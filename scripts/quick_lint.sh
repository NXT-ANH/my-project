#!/usr/bin/env bash
#
# quick_lint.sh — lint CHỈ các file staged, tự nhận diện stack.
#
# Nhận danh sách file staged qua argv (pre-commit truyền vào).
# Nhóm file theo ngôn ngữ rồi chỉ chạy linter nào thực sự có trong dự án.
# Không có linter -> báo skip, không fail (tránh chặn commit vì môi trường thiếu tool).
#
set -uo pipefail

[ $# -eq 0 ] && exit 0

js=(); py=(); go=(); sh=(); json=(); yaml=()
for f in "$@"; do
  [ -f "$f" ] || continue
  case "$f" in
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs) js+=("$f") ;;
    *.py)                              py+=("$f") ;;
    *.go)                              go+=("$f") ;;
    *.sh|*.bash)                       sh+=("$f") ;;
    *.json)                            json+=("$f") ;;
    *.yml|*.yaml)                      yaml+=("$f") ;;
  esac
done

rc=0
ran=0
skipped=()

run() {  # run <tên> <cmd...>
  local name="$1"; shift
  ran=1
  echo "  → $name"
  if ! "$@"; then rc=1; fi
}

# --- JS / TS ---------------------------------------------------------------
if [ ${#js[@]} -gt 0 ]; then
  if [ -f package.json ] && npx --no-install eslint --version >/dev/null 2>&1; then
    run "eslint (${#js[@]} file)" npx --no-install eslint --max-warnings=0 "${js[@]}"
  elif command -v eslint >/dev/null 2>&1; then
    run "eslint (${#js[@]} file)" eslint --max-warnings=0 "${js[@]}"
  else
    skipped+=("JS/TS: chưa cài eslint")
  fi
fi

# --- Python ----------------------------------------------------------------
if [ ${#py[@]} -gt 0 ]; then
  if command -v ruff >/dev/null 2>&1; then
    run "ruff (${#py[@]} file)" ruff check "${py[@]}"
  elif command -v flake8 >/dev/null 2>&1; then
    run "flake8 (${#py[@]} file)" flake8 "${py[@]}"
  else
    # Tối thiểu: kiểm tra cú pháp, luôn có sẵn vì python3 là dependency của pre-commit
    run "python syntax (${#py[@]} file)" python3 -m py_compile "${py[@]}"
  fi
fi

# --- Go --------------------------------------------------------------------
if [ ${#go[@]} -gt 0 ]; then
  if command -v golangci-lint >/dev/null 2>&1; then
    run "golangci-lint" golangci-lint run
  elif command -v gofmt >/dev/null 2>&1; then
    out=$(gofmt -l "${go[@]}")
    ran=1
    echo "  → gofmt (${#go[@]} file)"
    if [ -n "$out" ]; then echo "$out cần gofmt"; rc=1; fi
  else
    skipped+=("Go: chưa cài golangci-lint/gofmt")
  fi
fi

# --- Shell -----------------------------------------------------------------
if [ ${#sh[@]} -gt 0 ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    run "shellcheck (${#sh[@]} file)" shellcheck "${sh[@]}"
  else
    run "bash -n (${#sh[@]} file)" bash -n "${sh[@]}"
  fi
fi

# --- JSON ------------------------------------------------------------------
if [ ${#json[@]} -gt 0 ]; then
  ran=1
  echo "  → json syntax (${#json[@]} file)"
  for f in "${json[@]}"; do
    python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" \
      || { echo "    JSON không hợp lệ: $f"; rc=1; }
  done
fi

# --- YAML ------------------------------------------------------------------
if [ ${#yaml[@]} -gt 0 ]; then
  if python3 -c "import yaml" 2>/dev/null; then
    ran=1
    echo "  → yaml syntax (${#yaml[@]} file)"
    for f in "${yaml[@]}"; do
      python3 -c "import yaml,sys; list(yaml.safe_load_all(open(sys.argv[1])))" "$f" \
        || { echo "    YAML không hợp lệ: $f"; rc=1; }
    done
  else
    skipped+=("YAML: chưa có PyYAML")
  fi
fi

for s in "${skipped[@]:-}"; do [ -n "$s" ] && echo "  · bỏ qua — $s"; done
[ $ran -eq 0 ] && [ ${#skipped[@]} -eq 0 ] && echo "  · không có file cần lint"

exit $rc
