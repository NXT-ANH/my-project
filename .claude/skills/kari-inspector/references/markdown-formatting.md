# Inline Markdown in testcase fields

Kari renders a **small, inline-only** subset of Markdown in testcase content fields. Optional polish — the
testcase must read correctly as plain text too.

> **TESTCASE FIELDS ONLY.** Test plan sections and test viewpoint cover/scope are rendered with
> `white-space: pre-wrap` and exported to Excel verbatim — nothing on those paths parses Markdown, so
> every token below would show up as literal punctuation. Write those in plain text; `plan validate` /
> `viewpoint validate` warn when they don't.

## Supported tokens (exactly these)

| Write | Renders as | Use for |
|---|---|---|
| `**text**` | **bold** | field names, buttons, the key assertion |
| `*text*` | *italic* | light emphasis, a state/condition |
| `` `text` `` | `monospace` | exact values, keys, codes, endpoints, labels typed verbatim |
| `~~text~~` | ~~strikethrough~~ | "not X" / removed (rare) |
| newline (`\n`) | line break | two short lines in one field |

Nothing else is interpreted. Headings, lists, links, tables, blockquotes, images, and fenced code blocks
show up as literal characters.

**Applies to:** `preconditions`, `steps[].action`, `steps[].test_data`, `steps[].expected`,
`expected_result`. **Not `title`** — it's rendered as plain text; keep the `[L1]` prefix as-is.

```json
{
  "preconditions": "Local login is enabled. Account `qa.nguyen` exists with a known password.",
  "steps": [
    { "action": "Enter an incorrect password in the **Password** field", "test_data": "password=wrongpass123" },
    { "action": "Click the **Gửi** button" }
  ],
  "expected_result": "An error toast **Invalid credentials** is shown; user stays on the login page, *not* authenticated."
}
```

## Gotchas

- Raw `*`, `` ` ``, `~~` **inside a value** get swallowed as formatting: `password=a*b*c` italicises `b`.
  Wrap the whole value in a code span (`` `a*b*c` ``) or describe it instead.
- Markers must open and close **on the same line** and can't nest — `**a*b**` renders as italic `*a*`, not
  bold.
- Safe (never treated as formatting): underscores (`user_name`), angle brackets (`<script>`), a lone `*`.
- In doubt for an exact literal (endpoints, payloads, codes) → use a `` `code span` ``.

**Excel export writes the text raw** — markers appear literally (`**Password**`). Never rely on them to
carry meaning: the sentence must be correct and unambiguous with the markers stripped.
