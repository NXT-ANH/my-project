#!/usr/bin/env bash
#
# update-submodules.sh — đồng bộ tất cả submodule về branch develop mới nhất
# và cập nhật con trỏ submodule trong repo master.
#
#   ./update-submodules.sh              # dùng branch mặc định (develop)
#   ./update-submodules.sh release/1.2  # dùng branch khác
#   BRANCH=main ./update-submodules.sh  # hoặc qua biến môi trường
#
# Nếu submodule url là đường dẫn local (file://, /path/to/repo.git), git chặn
# theo mặc định (CVE-2022-39253). Bật bằng:
#   ALLOW_FILE_PROTOCOL=1 ./update-submodules.sh
#
set -uo pipefail

BRANCH="${1:-${BRANCH:-develop}}"

# Cho phép submodule qua đường dẫn local (tắt mặc định vì lý do bảo mật)
if [ "${ALLOW_FILE_PROTOCOL:-0}" = "1" ]; then
  export GIT_ALLOW_PROTOCOL="file:https:ssh:git"
fi

cd "$(dirname "$0")" || exit 1
ROOT="$(git rev-parse --show-toplevel)" || { echo "Không ở trong git repo."; exit 1; }
cd "$ROOT" || exit 1

if [ ! -f .gitmodules ]; then
  echo "Không tìm thấy .gitmodules trong $ROOT"
  exit 1
fi

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
fail()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }

FAILED=()
SKIPPED=()
UPDATED=()

# ---------------------------------------------------------------- 1. init & update
bold "[1/4] Init & update submodule"
git submodule sync --recursive >/dev/null
if git submodule update --init --recursive; then
  ok "Tất cả submodule đã được init & update"
else
  fail "git submodule update thất bại"
  exit 1
fi
echo

# ---------------------------------------------------------------- 2. checkout + pull
bold "[2/4] Checkout '$BRANCH' và pull code mới nhất"
PATHS=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

for sm in $PATHS; do
  printf '\n  → %s\n' "$sm"

  if [ ! -d "$sm/.git" ] && [ ! -f "$sm/.git" ]; then
    fail "$sm: chưa được init, bỏ qua"
    FAILED+=("$sm")
    continue
  fi

  (
    cd "$sm" || exit 1

    if ! git fetch --prune origin; then
      exit 1
    fi

    # Branch có tồn tại trên remote không?
    if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
      exit 2
    fi

    # Có thay đổi chưa commit thì không đụng vào, tránh mất code
    if ! git diff --quiet || ! git diff --cached --quiet; then
      exit 3
    fi

    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" --track "origin/$BRANCH" || exit 1
    git pull --ff-only origin "$BRANCH" || exit 1
  )
  rc=$?

  case $rc in
    0) ok "$sm: đã ở $BRANCH mới nhất ($(git -C "$sm" rev-parse --short HEAD))"
       UPDATED+=("$sm") ;;
    2) warn "$sm: không có branch 'origin/$BRANCH' — giữ nguyên $(git -C "$sm" rev-parse --abbrev-ref HEAD)"
       SKIPPED+=("$sm") ;;
    3) warn "$sm: có thay đổi chưa commit — bỏ qua để không mất code"
       SKIPPED+=("$sm") ;;
    *) fail "$sm: fetch/checkout/pull thất bại"
       FAILED+=("$sm") ;;
  esac
done
echo

# ---------------------------------------------------------------- 3. cập nhật master
bold "[3/4] Cập nhật con trỏ submodule trong repo master"
CHANGED=$(git diff --ignore-submodules=dirty --name-only -- $PATHS)

if [ -z "$CHANGED" ]; then
  ok "Không có submodule nào đổi commit — master đã up-to-date"
else
  echo "  Submodule đổi commit:"
  for c in $CHANGED; do echo "    - $c"; done
  git add -- $CHANGED
  if git commit -m "chore: update submodules to latest $BRANCH

$(for c in $CHANGED; do echo "- $c -> $(git -C "$c" rev-parse --short HEAD)"; done)"; then
    ok "Đã commit: $(git rev-parse --short HEAD)"
    warn "Chưa push. Chạy 'git push' khi bạn đã kiểm tra xong."
  else
    fail "Commit thất bại"
  fi
fi
echo

# ---------------------------------------------------------------- 4. in trạng thái
bold "[4/4] Trạng thái từng submodule"
printf '  %-12s %-18s %-10s %-8s %s\n' "SUBMODULE" "BRANCH" "COMMIT" "DIRTY" "SUBJECT"
printf '  %-12s %-18s %-10s %-8s %s\n' "---------" "------" "------" "-----" "-------"

for sm in $PATHS; do
  if [ ! -d "$sm/.git" ] && [ ! -f "$sm/.git" ]; then
    printf '  %-12s %-18s %-10s %-8s %s\n' "$sm" "-" "-" "-" "chưa init"
    continue
  fi
  br=$(git -C "$sm" rev-parse --abbrev-ref HEAD 2>/dev/null)
  sha=$(git -C "$sm" rev-parse --short HEAD 2>/dev/null)
  sub=$(git -C "$sm" log -1 --pretty=%s 2>/dev/null)
  if git -C "$sm" diff --quiet && git -C "$sm" diff --cached --quiet; then dirty="no"; else dirty="YES"; fi
  printf '  %-12s %-18s %-10s %-8s %s\n' "$sm" "$br" "$sha" "$dirty" "$sub"
done

echo
bold "Tổng kết (branch: $BRANCH)"
echo "  Cập nhật OK : ${#UPDATED[@]} ${UPDATED[*]:-}"
echo "  Bỏ qua      : ${#SKIPPED[@]} ${SKIPPED[*]:-}"
echo "  Thất bại    : ${#FAILED[@]} ${FAILED[*]:-}"

[ ${#FAILED[@]} -eq 0 ] || exit 1
