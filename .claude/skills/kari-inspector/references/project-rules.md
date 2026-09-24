# Project rules — `.inspector/rules.md` (append-only layer)

A project may add its own testcase rules in **`.inspector/rules.md`** at the repo root. Created as a
commented template by `inspector install --skills`, **never overwritten** (not even with `--force`),
committed to git.

Read it **once per session**, before authoring (`inspector-gen-test` Step 5) or reviewing
(`inspector-review` Step 3) — alongside `testcase-generation-rules.md`, not instead of it.

## Precedence — the kit rules win

The file is **append-only**: it may only **add** constraints, never weaken, replace, or reinterpret a kit
rule.

1. **`testcase-generation-rules.md`** — canonical, immutable.
2. **`.inspector/rules.md`** — additional constraints only.

**On conflict:** apply the **kit** rule, then tell the user the project file contradicts it (quote both, one
line each) and suggest they drop that line or change the kit. Never silently apply the project rule over a
kit rule, and never treat this file as permission to skip a kit requirement.

| Project rule | Verdict |
|---|---|
| "Every feature needs an audit-log case" | ✅ apply — adds coverage |
| "`test_data` uses `key=value`, separated by `; `" | ✅ apply — narrows an unconstrained field |
| "Use `Cửa hàng`, never `Store`" | ✅ apply — adds vocabulary |
| "Skip the `[L1]` prefix in titles" | ❌ conflicts with §1.1 — apply the kit rule, flag it |
| "Login cases don't need negative cases" | ❌ conflicts with §3–§7 — apply the kit rule, flag it |
| "Write everything in English" | ⚠️ conflicts with §0 if the team chats Vietnamese — flag and ask |

Anything that isn't a conflict is a rule you must follow exactly as if it were in the kit rules.

## Handling the file

- **Missing** — normal. Kit defaults only; don't create it mid-task or nag about it.
- **Template only** (headings with nothing but a `<!-- e.g. … -->` placeholder) — treat as empty. Those
  examples are illustrations, **not** rules.
- **Filled in** — follow every rule, subject to the precedence above.
- **Long** (over ~200 lines) — read it fully anyway; cheap compared to a wrong testcase set.

No need to narrate each rule as you apply it, but mention them in the self-review / review summary, e.g.
"Applied 3 project rules from `.inspector/rules.md` (audit-log coverage, `test_data` format, role
vocabulary)."

## Who writes it

**The user does.** Never create or edit it on your own initiative. What you *do* is help them find what's
worth writing — `project-setup.md` Step 4 explores the project and reports 2–5 concrete observations with a
pointer to the file.

**Template sections** (all optional): Mandatory coverage · Field conventions · Domain vocabulary ·
Environment & test accounts (no secrets — it's committed) · Out of scope.

**Related (optional, not `rules.md`):** business module chains for System Test live in
**`.inspector/domain-map.md`** (copy from kit `domain-map.example.md`). That file does not override kit
rules; gen/review load it for ST flow confirmation (generation-rules §0.2.1).
