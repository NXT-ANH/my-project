#!/usr/bin/env python3
"""PII scan — quét email / SĐT / CMND / CCCD / thẻ ngân hàng trong file staged.

Chạy bởi pre-commit, nhận danh sách file staged qua argv.
Exit 1 nếu phát hiện PII -> chặn commit.

Bỏ qua 1 dòng:   thêm comment  # pii-allow   (hoặc // pii-allow)
Bỏ qua 1 file:   thêm vào PII_IGNORE bên dưới hoặc exclude trong .pre-commit-config.yaml
"""
import re
import sys

# --- các mẫu PII -----------------------------------------------------------
PATTERNS = [
    ("EMAIL", re.compile(
        r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")),
    ("SĐT-VN", re.compile(
        r"(?<![\w.])(?:\+84|0084|0)(?:3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-46-9])\d{7}(?![\w.])")),
    ("CMND/CCCD", re.compile(r"(?<![\w.])\d{12}(?![\w.])|(?<![\w.])\d{9}(?![\w.])")),
    ("THẺ-NH", re.compile(r"(?<![\w.])(?:\d[ -]?){13,19}(?![\w.])")),
]

# Giá trị rõ ràng là ví dụ/placeholder -> không coi là PII
ALLOW_VALUE = re.compile(
    r"example\.(com|org|net)|@(example|test|localhost|domain)\b"
    r"|noreply@|no-reply@|your[._-]?email|<[^>]*>|xxx+|0{6,}|1234567890",
    re.I,
)

# File không cần quét
PII_IGNORE = re.compile(
    r"(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|go\.sum)$"
    r"|(^|/)\.git/|(^|/)scripts/pii_scan\.py$"
)

ALLOW_LINE = re.compile(r"(#|//|/\*|<!--)\s*pii-allow")

# Phần mở rộng nhị phân -> bỏ qua
BINARY_EXT = re.compile(
    r"\.(png|jpe?g|gif|webp|ico|svg|pdf|zip|gz|tar|woff2?|ttf|eot|mp4|mp3|so|dylib|class|jar)$",
    re.I,
)


def luhn_ok(digits: str) -> bool:
    """Kiểm tra checksum Luhn — giảm false positive cho số thẻ."""
    d = [int(c) for c in digits]
    checksum = 0
    for i, n in enumerate(reversed(d)):
        if i % 2 == 1:
            n *= 2
            if n > 9:
                n -= 9
        checksum += n
    return checksum % 10 == 0


def scan(path: str):
    findings = []
    try:
        with open(path, "r", encoding="utf-8", errors="strict") as f:
            lines = f.readlines()
    except (UnicodeDecodeError, OSError):
        return findings  # nhị phân hoặc không đọc được -> bỏ qua

    for lineno, line in enumerate(lines, 1):
        if ALLOW_LINE.search(line):
            continue
        for label, pat in PATTERNS:
            for m in pat.finditer(line):
                val = m.group(0)
                if ALLOW_VALUE.search(val) or ALLOW_VALUE.search(line):
                    continue
                if label == "THẺ-NH":
                    digits = re.sub(r"\D", "", val)
                    if not (13 <= len(digits) <= 19) or not luhn_ok(digits):
                        continue
                findings.append((lineno, label, val, line.strip()))
    return findings


def mask(value: str) -> str:
    if len(value) <= 4:
        return "*" * len(value)
    return value[:2] + "*" * (len(value) - 4) + value[-2:]


def main(argv):
    files = [f for f in argv if not PII_IGNORE.search(f) and not BINARY_EXT.search(f)]
    total = 0
    for path in files:
        for lineno, label, val, ctx in scan(path):
            total += 1
            print(f"  {path}:{lineno}  [{label}]  {mask(val)}")
            print(f"      {ctx[:120]}")

    if total:
        print()
        print(f"PII scan: phát hiện {total} giá trị nghi là dữ liệu cá nhân.")
        print("Xử lý: xoá/thay bằng placeholder, hoặc thêm '# pii-allow' nếu là dữ liệu giả.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
