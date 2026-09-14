#!/usr/bin/env python3
"""Bắt buộc commit message chứa mã spec dạng [SPEC-XXX].

Dùng cho hook commit-msg (pre-commit truyền đường dẫn file message qua argv).
Cùng regex này được dùng lại cho PR title trong CI (xem .github/workflows/pr-title.yml).
"""
import re
import sys

SPEC_RE = re.compile(r"\[SPEC-[A-Z0-9]+(?:-[A-Z0-9]+)*\]")

# Commit do git tự sinh -> không bắt buộc
EXEMPT_RE = re.compile(
    r"^(Merge\s|Revert\s|fixup!\s|squash!\s|Applied\sautofix)", re.I
)


def main(argv):
    if not argv:
        print("check_spec_id: thiếu đường dẫn commit message.")
        return 1

    with open(argv[0], "r", encoding="utf-8", errors="replace") as f:
        raw = f.read()

    # Bỏ comment của git và dòng trống ở đầu
    lines = [l for l in raw.splitlines() if not l.startswith("#")]
    msg = "\n".join(lines).strip()
    subject = lines[0].strip() if lines else ""

    if not msg:
        print("Commit message rỗng.")
        return 1

    if EXEMPT_RE.match(subject):
        return 0

    if SPEC_RE.search(subject):
        return 0

    print("Commit message thiếu mã spec.")
    print()
    print(f"  Hiện tại : {subject}")
    print("  Yêu cầu  : subject phải chứa [SPEC-XXX]")
    print()
    print("  Ví dụ hợp lệ:")
    print("    [SPEC-123] feat(backend): thêm endpoint tạo đơn hàng")
    print("    fix(frontend): sửa lỗi validate form [SPEC-ABC-42]")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
