# Project setup — `.inspector/config.json` + `.inspector/rules.md`

Run **once at the start of a session**, before the first `inspector` command that needs project/paths.

## The config file

`.inspector/config.json` at the repo root — **committed** (the token is never here; it lives in
`~/.config/kari-inspector/credentials.json`).

| Field | Meaning | Default | Env override |
|-------|---------|---------|--------------|
| `base_url` | Kari server | `https://inspector-kari.kaopiz.com` | `KARI_API_URL` |
| `project_key` | default project code (e.g. `KPP`) | — | — |
| `work_dir` | folder holding `drafts/`, `testcases/`, `reviews/` | `test` | `KARI_WORK_DIR` |
| `e2e_dir` | folder holding the Playwright E2E specs (`inspector-e2e` writes here) | `e2e` | `KARI_E2E_DIR` |
| `docs_dir` | folder holding project reference docs (data source, SRS, basic/detail design) — `inspector-gen-testplan` reads SRS from here | `docs` | `KARI_DOCS_DIR` |

Precedence per field: **env var → config → default**. `base_url` + token come from `inspector init`; the
other four come from this flow (don't run `init` for them).

**Trigger:** Steps 1–3 when **any** of `project_key` / `work_dir` / `e2e_dir` / `docs_dir` is missing. Step 4 has its own
trigger: `.inspector/rules.md` missing or still the bare template.

## Step 1 — Survey the repo (so questions come pre-filled)

- **`project_key`** — `inspector projects`. One result → propose it; several → list them. A `project_key` in
  a nearby config or a Jira key in the branch name is a hint.
- **`work_dir`** — glob `*/testcases/**/*.testcases.json` and `*/drafts/*/draft.json` (common names:
  `test/`, `tests/`, `testcases/`). Found → propose that top-level dir; else `test`.
- **`e2e_dir`** — look for `playwright.config.*` and/or a `tests/` tree of `*.spec.ts` (`e2e/`,
  `playwright/`); check `.gitmodules` for an E2E submodule. Found → propose it; else `e2e`.
- **`docs_dir`** — look for a top-level docs folder (common layout: `data-source/`, `srs/`,
  `basic-design/`, `detail-design/` underneath; check `.gitmodules` for a docs submodule). Found →
  propose that top-level dir; else `docs`.

Keep it light — a couple of `Glob`/`ls` calls. The point is a sensible pre-filled answer, not an audit.

## Step 2 — Confirm (`AskUserQuestion`)

**One** call, batching only the missing fields, each with the surveyed guess pre-selected plus "Enter
manually". Never silently write a value the user hasn't seen.

## Step 3 — Write `.inspector/config.json`

**Merge, don't overwrite** — preserve existing keys. Pretty JSON (2-space indent, trailing newline), no
trailing slash on dir values:

```json
{
  "base_url": "https://inspector-kari.kaopiz.com",
  "project_key": "KPP",
  "work_dir": "test",
  "e2e_dir": "e2e",
  "docs_dir": "docs"
}
```

Tell the user it's saved and worth committing. From here, every path comes from `work_dir` / `e2e_dir` /
`docs_dir`.

## Step 4 — Explore, then *suggest* rules for `.inspector/rules.md`

`.inspector/rules.md` is this team's **append-only** layer on the kit rules (`project-rules.md`).
`install --skills` scaffolds it as an empty template, and a template nobody fills in is a wasted mechanism.

**You suggest; the user writes.** Do **not** create or edit the file here — only if the user explicitly asks
("ghi vào rules.md"). No `AskUserQuestion` either: this is one short observation block at the end of setup,
not a gate. Once per project setup, not per session. Skip silently if the file is already filled in.

**Explore first** — spawn the **`Explore`** agent (`subagent_type: "Explore"`) to keep the reading off this
session's context; fall back to `Glob`/`Grep`/`Read`:

| Where | What you're looking for |
|---|---|
| Spec / design docs | How the team writes ACs; recurring non-functional requirements (audit trail, permissions, i18n); consistent domain terms |
| Existing testcases (`<work_dir>/testcases/**`) | The team's **language**; `test_data` format; how `preconditions` name roles; recurring case types |
| Existing tests in code | Naming patterns, fixtures, what's already covered → candidates for **out of scope** |
| Code — role/status/permission enums, i18n catalogs, validation schemas | **Domain vocabulary**: exact ids testcases should use verbatim |
| QA / contributing docs, README testing sections | Rules the team wrote in prose but never fed to the kit |

**Then report 2–5 observations max**, one line each, each naming its evidence, grouped by the template
section it belongs to, then one sentence pointing at the file:

> Từ cấu trúc dự án, vài điểm có thể đáng đưa vào `.inspector/rules.md`:
> - **Domain vocabulary** — `app/constants/roles.py` định nghĩa `admin` / `store_owner` / `staff`; testcase nên dùng đúng id này.
> - **Mandatory coverage** — `docs/specs/*.md` màn hình nào ghi dữ liệu cũng có mục "Ghi audit log", nhưng chưa testcase nào kiểm tra.
> - **Out of scope** — hiệu năng đã có bộ k6 riêng ở `perf/`.

Then move on to what the user actually asked for; don't wait for an answer. A rule you can't trace to
something you saw is a guess — drop it, and never pad the list to reach a count. Nothing specific found →
one line: "`.inspector/rules.md` đang trống; thêm vào đó nếu team có quy ước riêng."

**Append-only still applies.** Never suggest a rule that contradicts `testcase-generation-rules.md`. If the
repo's existing testcases violate a kit rule, raise that as a *finding*, not as a rule to adopt.
