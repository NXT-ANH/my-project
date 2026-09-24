---
name: inspector-review
description: >
  Review Kari Inspector testcases — a pending draft, someone else's feature testcases, or testcases just
  generated locally. ALWAYS use this when the user says "review testcase", "review draft", "review test
  của X", "đánh giá bộ testcase", "check coverage", or asks whether a set of testcases is good/complete.
  This skill JUDGES and produces findings — it does not apply fixes. To act on existing comments, route to
  inspector-address-review (reviewers' server comments) or inspector-review-notes (own local notes).
---

# Inspector — Review testcases

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside (shared rules load from
`../kari-inspector/references/`). Companions: `inspector-gen-test`, `inspector-e2e`.

**CLI:** `inspector` from `@kaopiz/inspector-cli` (inside the repo: `npm link` from `src/inspector-cli/`).
`inspector init` for auth. If `.inspector/config.json` lacks `project_key` / `work_dir` / `e2e_dir`, run
`../kari-inspector/references/project-setup.md` first. Examples use the default `work_dir` (`test/`).

Reviews are read-heavy: pull once to local JSON (off-context), then analyze the file. A review is only
credible when **grounded in evidence** — the spec and the actual code — not just checked against generic
rules.

```
1. PULL     → local JSON, off-context
2. RESEARCH spec + code/tests for the feature   → what SHOULD be covered
3. ANALYZE  each testcase against evidence + rules
4. REPORT   actionable comment list, then offer to post
```

## Step 1 — Pull the target

Decide the target with `AskUserQuestion` (pending draft / feature's active testcases / local file).

**A pending draft (common case)** — one review file per leaf feature under
`<work_dir>/reviews/<draft-slug>/`, each testcase tagged with `sync.change_type` (CREATE/UPDATE) and
`sync.version_id` (needed to post comments):

```
inspector pull --draft <draft_id>
```

Draft id: from the Kari URL (`…/drafts/<id>`), from local `<work_dir>/drafts/<slug>/draft.json`, or via
MCP `kari_list_drafts` (the CLI has no drafts-list command).

**A feature's active testcases:**

```
inspector pull --feature-id <uuid> --project <KEY> --app <app> --module <mod> --feature <feat>
```

**A local draft folder** (just generated this session): read the JSON directly. To let a **human** review
and leave inline notes, serve it — `inspector review test/<level>/drafts/<slug> --open` (background; blocks
until Ctrl-C). Opening the `.html` as `file://` gives a read-only page with no comment UI.

To read any pulled file in the terminal: `inspector convert <file-or-dir> --md --stdout`.

## Step 2 — Research: ground the review in spec + code

**This is what makes the review real.** "Missing the locked-account case" is only credible if you can point
at where that behavior is defined.

1. **Spec** — the repo spec file (use-case / SRS / design doc / screen or API description) or the Jira task
   (`jira_get_issue` — `../kari-inspector/references/jira-handling.md`): acceptance criteria, validation
   rules, error messages, roles, business rules.
2. **Implementation** — backend handler/endpoint + request schema, core logic, or the frontend
   page/component. Read it for **actual** field names, validation limits, exact error strings, branches and
   roles — this is what catches testcases asserting wrong data or missing a real branch.
3. **Existing tests** — unit / component / E2E already covering this, so suggestions don't duplicate.

Search rather than assume paths. Use `Grep`/`Glob`/`Read`, or the `Explore` agent for a broad sweep. Keep a
short evidence list — each Step 4 finding should cite a `file:line` or an AC where it can.

> No repo spec and no Jira task → say so, review against the generation rules only, and flag that coverage
> completeness couldn't be verified against a source of truth.

## Step 3 — Analyze against evidence + rules

Rules: `../kari-inspector/references/testcase-generation-rules.md`. **Read `.inspector/rules.md` first** if
present and filled in — the project's **append-only** layer (mandatory coverage, field conventions, domain
vocabulary, out of scope); a violation is a finding like any other. Where it contradicts the kit rules,
judge by the **kit** rule and report the contradiction as a finding against the rules file, not against the
testcases (`../kari-inspector/references/project-rules.md`).

Per testcase:

- **Title** — specific, names the scenario (not "Test login"); carries the `[L1]` tag.
- **Preconditions** — login state, screen, prerequisite data all listed.
- **Steps** — atomic (one action each); no "do A then B"; no internal/code-level steps (network tab,
  DevTools, DB queries).
- **Expected results** — present and verifiable for every user-visible outcome, and **matching the
  code/spec** (right error string, redirect, validation limit).
- **Coverage** — happy / negative / boundary(BVA) / edge / security / non-functional per the field and
  function checklists (generation-rules §3–§7), **measured against the spec's AC and the code's real
  branches**. Name the technique for each gap (EP, BVA, decision table, state transition).
- **Correctness** — real `test_data`, no placeholders; sensible `severity` + `test_case_type`.
- **Duplication / scope** — duplicate scenarios, fields/screens not in the spec, coverage already provided
  by existing tests, or anything `.inspector/rules.md` marks out of scope.
- **E2E perspective** — user-facing UI actions only; flag unit/API/DOM-level testcases.
- **Test level fit** — read `meta.test_level` and judge scope per generation-rules §0.2: IT goes deep on
  one feature, ST follows a cross-module process without re-testing single-field validation. Flag cases
  belonging in the other level, and any mismatch between `draft.json` and a feature file.

**ST / FB No.114 checklist** (when `test_level` is `system_test`, or the ticket asked for journey / luồng /
E2E process) — also apply generation-rules **§0.2.1**:

- **Function-centric ST** — cases organized only as isolated IT functions while the requirement describes a
  business journey → Needs revision (re-order / re-scope along the module chain).
- **Overlong** — any case with **>15** steps without a split into chained shorter cases → Needs revision.
- **Checkpoint expects** — create/save/approve/state-change steps with empty `steps[].expected` while all
  asserts sit only in `expected_result` → Needs revision / warn.
- **Contamination** — module names or chains that look copied from another product (not in this project's
  `.inspector/domain-map.md` / SRS) → Needs revision.

For a **draft**, weight by `change_type`: scrutinize CREATE for coverage, UPDATE for whether the change is
correct and doesn't drop previously-covered cases.

## Step 4 — Report an actionable comment list

One entry per issue, mapped to a specific testcase, backed by evidence where possible. Prefer a short table
over prose:

- **Approved** — testcase `id`/title that pass.
- **Needs revision** — `id`/title + the specific issue + the fix, citing `file:line` or an AC.
- **Suggested additions** — concrete ADD testcases (title + type + one-line rationale + the spec/code
  branch they cover).

Comments must be **actionable** — point at the exact step/field and give the fix:

> Bad: "Steps are unclear."
> Good: "Step 3 'verify result' → 'Observe the success toast; expect \"Đơn hàng đã được tạo\".' (matches
> `LoginForm.tsx:88`)."

Each comment carries the `sync.version_id` from the pulled file, so it can target the exact version.

## Step 5 — Offer next actions (`AskUserQuestion`)

- **Post findings as Kari comments** — one per finding:

  ```
  inspector comments post <version_id> "<finding>" [--quote "<exact text>"] [--field title|preconditions|expected_result|steps[0].action]
  ```

  `--quote` + `--field` anchor it so the author sees it inline. (Fallback: MCP `kari_add_comment`, or
  `POST /api/review_comments`.)
- **I'll apply the fixes in the JSON** — hand back to `inspector-gen-test` (edit → validate → convert →
  push; same `version_id`).
- **Just the report** — leave the findings as text.

Don't post findings *and* apply them yourself — pick one, or the fix and the comment drift apart. After
posting, the author's side of the loop is **`inspector-address-review`**.

**Closing comments is the reviewer's job.** Once the author has fixed, pushed, and replied, re-pull with
`inspector comments <draft_id>`, read the replies, and close what you verified:
`inspector comments resolve <id>`. Never hand `resolve` to the author — the server allows it, but then a
comment closes with nobody re-checking the fix.

## Interaction rule

`AskUserQuestion` for scope/decision gates (which draft/feature, whether to post). Keep the findings report
as readable text/tables.
