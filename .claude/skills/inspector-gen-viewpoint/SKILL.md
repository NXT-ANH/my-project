---
name: inspector-gen-viewpoint
description: >
  Author a Kari **test viewpoint** locally as one viewpoint.json (matrix of viewpoint rows × functions,
  cover/scope, confirm content), review it offline, then push it to Kari. ALWAYS use this when the user
  asks to create / write / gen a test viewpoint, "tạo test viewpoint", "làm ma trận viewpoint",
  "gen viewpoint cho <project>". NOT for test plans (`inspector-gen-testplan`) or testcases
  (`inspector-gen-test`).
---

# Inspector — Author a test viewpoint (JSON-first)

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside (shared rules load from
`../kari-inspector/references/`). This skill authors the **Test Viewpoint sheet** — which viewpoint
rows apply to which function — not a test plan and not testcases.

**CLI:** `inspector` / `kari`. Lifecycle: `viewpoint gen → validate → convert/review → push → pull/sync`.

## Why author it locally

The server generator spends **one LLM call per function** deciding that function's marks, then reads
the rows and the confirm sheet straight out of the Excel template. Only the marks need thinking, and
you are the model — authoring them here means the push runs no AI at all.

## What a viewpoint holds

One file `test/viewpoints/<slug>/viewpoint.json`:

- **meta** — `project_key`, `platform` (web_wap|app|hybrid, derived server-side when null),
  `session_id`, `status`. Written back by `push`/`pull`.
- **cover** — free-form sheet header (`project_name`, `reviewer`, `phase`, `version`).
- **scope** — `description`, `feature_summary`.
- **rows** — the template's viewpoint rows, each with a 1-based `no` plus `level_0..level_3`.
  Positional: `no` is re-derived on every read, so never hand-number them.
- **functions** — the matrix columns: `module_name`, `name`, and **`marks`**.
- **confirm_items** — only present once someone has decided something; otherwise the server's
  ~500 template rows stay server-side (they would be 5× the rest of the file).

**`marks` is the whole point.** It is a range string of row numbers — `"1-7,10-21,25,64"` — meaning
this function is tested against those viewpoint rows. An array of numbers is also accepted on read;
writes always come back as ranges.

## Workflow

0. **Is there one already?** — `inspector viewpoint status --project <KEY> [--json]`. Read-only.
   `action: "new"` → nothing on the server yet. Otherwise a session exists and `push` will **replace**
   it; pull it first rather than authoring a second one blind.
1. **Read project rules** — `.inspector/rules.md`, plus the kit rules in `../kari-inspector/references/`.
1b. **Build the feature tree from SRS** — the matrix **columns ARE the feature tree** (level-1 roots +
   their direct children), so `viewpoint gen` can only produce columns for functions that already exist
   as features. Before scaffolding, make the tree exist per **`../kari-inspector/references/feature-tree.md`**:
   read the SRS from `docs_dir`, propose the tree against what exists, confirm with `AskUserQuestion`,
   `inspector feature create` the approved missing nodes, re-fetch. **Depth for a viewpoint: Module +
   direct children (2 levels)** — deeper nodes don't become columns. Skip only when the tree is already
   complete for the scope the user wants covered.
2. **Scaffold** — `inspector viewpoint gen --project <KEY> [--slug <s>]`. Pulls the template rows and
   turns the project's feature tree into columns (level-1 features and their direct children, per app —
   the same column set the server would build). `--no-functions` scaffolds columns-empty.
3. **Author the marks** — for each function, read the rows and set `marks` to the rows that genuinely
   apply. This is judgement, not a formula; see Rules below.
4. **Validate** — `inspector viewpoint validate test/viewpoints/<s>` (blocks on marks that point at
   no row, unreadable ranges, duplicate columns).
5. **Review offline** — `inspector viewpoint convert test/viewpoints/<s>` → open `<s>.html` for the
   grid with 〇 and a coverage-per-function table, or `--md --stdout` to read in the terminal. Show
   the user; iterate.
5b. **Let the user fix the matrix themselves** — `inspector viewpoint review test/viewpoints/<s>
   [--open]` serves a local page (127.0.0.1) where clicking a cell toggles 〇 and **Save writes
   viewpoint.json**. A matrix has no prose to comment on, so unlike `inspector review` there is no
   notes file — the review IS the edit. Offer this before pushing whenever the user wants to check
   the marks; re-read the file afterwards, since they may have changed it under you. Runs until
   Ctrl-C, so don't block on it: start it, hand over the URL, and continue when the user says so.
6. **Push** — `inspector viewpoint push test/viewpoints/<s>`. Imports the sheet and writes
   `session_id`/`platform`/`status` back into the file.
7. **Verify the push** — read the `functions:N rows:N marks:N confirm:N` line. `marks:0` on a doc that
   has marks means they did not land; say so instead of reporting success.
8. **Refresh** — `inspector viewpoint sync test/viewpoints/<s>` (or `viewpoint pull --project <KEY>`
   into a fresh folder). Everything round-trips, so sync **overwrites** the local file with the server
   version — anything authored since the last push is lost. Push before you sync.

## Rules

- **`marks` are positions in this file's `rows` array**, 1-based. Never renumber rows; if the rows
  change, the marks move with them.
- **Don't blanket-mark.** A column marked against all 112 rows says nothing. Mark the rows the
  function can actually fail on: input validation only where there are inputs, upload/export only
  where files move, pagination only where there is a list.
- **Non-functional rows (performance, security, compatibility, monkey) are not universal** — mark them
  where the function has a real risk, not by default. The server's own LLM-failure fallback marks
  every functional/UI row and skips exactly these; do better than the fallback.
- **`push` replaces the project's latest session in place** (functions, rows, marks). It does not
  stack sessions. Use `--new` only when the user wants a separate session kept alongside the old one.
- **Confirm items are all-or-nothing.** Push replaces the whole list, so the file either carries every
  item or none. `pull`/`sync` follow that: they bring the sheet down only once something is decided,
  or with `--with-confirm`.
- **Cover and scope are PLAIN TEXT — no Markdown.** They are `<input>`/`<textarea>` values on the web
  and raw cells in the Excel export; nothing parses Markdown on that path, so `**bold**`, `#` and pipe
  tables show up as literal characters. `viewpoint validate` warns when it finds any. Use plain lines
  (`- Account: Change Password, Personal Access Token`). Only TESTCASE fields render inline Markdown
  (`../kari-inspector/references/markdown-formatting.md`).
- Excel export stays on the web (Test Viewpoint → Export) — the CLI does not export .xlsx.
