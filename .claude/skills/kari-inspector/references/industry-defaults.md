# Industry-Standard Default Values

Use this table when the spec is silent on a common configuration. Present the listed value as the **first / recommended option** in `AskUserQuestion`, plus 1-2 common alternatives, plus "Enter manually". This stops the model from inventing arbitrary numbers and gives the user a sensible default they can accept with one click.

These defaults are drawn from RFC / NIST / common UX practice — not from any specific product. If the spec contradicts a value here, the spec wins.

---

## Validation & input limits

| Field / Rule | Recommended default | Source |
|---|---|---|
| Email max length | 255 characters | RFC 5321 |
| Password min length | 8 characters | NIST SP 800-63B |
| Password max length | 128 characters | NIST SP 800-63B |
| Text / name max length | 255 characters | Common DB varchar default |
| Textarea max length | 1000 characters | Common UX practice |
| File upload max size | 5 MB | Common UX practice |
| File upload formats | jpg, png, pdf | Common UX practice |
| Negative numbers | Not allowed (default) | — |

## Behavior & UX

| Field / Rule | Recommended default |
|---|---|
| Validation timing | On submit |
| Error message location | Inline below the field |
| Session timeout | 30 minutes of inactivity |
| Login lockout | After 5 consecutive failed attempts |
| Redirect after login | Dashboard / home page |
| Redirect after logout | Login page |
| Pagination page size | 10 items per page |
| Date format | DD/MM/YYYY |

---

## How to use this in clarification

When you find a gap in the spec, ask via `AskUserQuestion` with the recommended value as the first option:

> "What's the maximum length for the email field?" → "255 characters (RFC 5321 — recommended)" | "100 characters" | "Other (enter manually)"

This pattern:
- Lets the user accept the default with one click (most common case).
- Surfaces the *why* (RFC 5321) so the user can override with confidence if their product has a different rule.
- Avoids both extremes: silently guessing, or paralyzing the user with too many decisions.
