---
name: inspector-gen-testplan
description: >
  Author a Kari **test plan** locally as one plan.json (scope + schedule tasks + sections + milestones),
  review it offline, then push it to Kari. ALWAYS use this when the user asks to create / write / gen a
  test plan, "tạo test plan", "viết kế hoạch test", "lập test plan cho <project>", or to draft a plan's
  scope/schedule for a project. NOT for testcases — that is `inspector-gen-test`.
---

# Inspector — Author a test plan (JSON-first)

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside (shared rules load from
`../kari-inspector/references/`). This skill authors a **test plan** (project-level: scope, schedule,
sections, milestones) — not testcases. For testcases use `inspector-gen-test`.

**CLI:** `inspector` / `kari`, from `@kaopiz/inspector-cli`. Lifecycle: `plan gen → validate → convert/review → push → pull/sync`.

## What a test plan holds (fidelity of local authoring)

A plan is authored as one file `test/plans/<slug>/plan.json`:

- **meta** — `project_key`, `title`, `start_date`, `due_date`, `period_label`.
- **scope** — modules → functions. Each function references a real catalog `feature_id` (from
  `inspector tree`) and carries `priority` (high|medium|low), `complexity` (**simple|medium|complex**),
  `estimate_mh`, `duration_days`.
- **schedule_tasks** — nested under each function: QA activities with `task_type`
  (analyze_qna|write_testcase|review_testcase|update_testcase|execute_test|retest_bugfix|regression|report|custom),
  `title`, `priority`, `resource` (sqa|dev|both), `duration_working_days`, `estimate_mh`, optional `jira_st`/`process`.
- **sections** — narrative by section_key. Kari knows exactly five: `introduction`, `environment`,
  `test_items`, `features_not_tested`, `estimate`. Any other key is stored by the import endpoint but
  **never rendered on any Kari screen** — validate blocks it.
- **milestones** — `title`, `deliverable`, optional `owner_user_id`, `due_date`, `note`.

> **Server-computed / out of local scope (v1):** bar dates are computed server-side from durations +
> the working-day calendar. Assignee, environment, PIC, explicit bar dates, and task dependencies are
> **not** authored locally — set them on the Kari web UI after push. Don't invent user/environment IDs.

## Workflow

0. **Edit or start fresh?** — `inspector plan status --project <KEY> [--json]`. Read-only; branch on
   `action`: `edit` → keep working in the existing plan dir and push to the same `plan_id`;
   `new` → `plan gen` with a **new slug**; `wait` → the plan is in review, stop and tell the user;
   `clone` → the plan was rejected into a locked state, clone it on the web first. Never push into a
   plan whose status is not editable — the server returns 409 `plan_read_only`.
1. **Read project rules** — `.inspector/rules.md` (mandatory coverage, vocabulary, conventions). Apply
   the kit rules from `../kari-inspector/references/` where they overlap; kit rules win on conflict.
2. **Build the feature tree from SRS** — the plan's `scope` is modules → functions and every function
   needs a real catalog `feature_id`, so make the tree exist before scaffolding. Follow
   **`../kari-inspector/references/feature-tree.md`**: read the SRS from `docs_dir`, propose the tree
   against what already exists, confirm with `AskUserQuestion`, `inspector feature create` the approved
   missing nodes, re-fetch. **Depth for a plan: Module → Function.** Never fabricate a `feature_id`.
3. **Scaffold** — `inspector plan gen --project <KEY> --start-date <YYYY-MM-DD> --slug <s> [--title …] [--due-date …]`.
4. **Author `plan.json`** — fill scope (modules/functions with priority/complexity/estimate/duration),
   the QA `schedule_tasks` per function, the narrative sections, and milestones. Write content in the
   **user's language** (Vietnamese by default).
5. **Validate** — `inspector plan validate test/plans/<s>` (blocks on enum/date/feature_id errors).
6. **Review** — `inspector plan review test/plans/<s> [--open]` renders the preview and serves it on
   127.0.0.1: the Kari layout (same two tabs, same five sections, milestones table) plus a **Gantt**
   built from the dates the server will compute on push. Hand the user the URL; every reload
   re-renders plan.json, so keep editing while the page stays open. Runs until Ctrl-C — start it in
   the background, don't block on it.
   `inspector plan convert test/plans/<s>` writes the same page as a standalone file (`--md --stdout`
   for the terminal). `plan review` fetches the holiday calendar and caches it under `.inspector/`;
   `convert` reuses that cache, and without it the timeline only skips weekends.
7. **Push** — `inspector plan push test/plans/<s>` (creates the plan if new, imports everything, writes
   `plan_id`/`version_no`/`status` back, prints the Kari URL). `--force` overwrites manual-override bars.
8. **Verify the push** — read the `functions:N sections:N schedule:N` line. `schedule:0` when the plan
   has schedule tasks means they did **not** land; say so instead of reporting success.
9. **Refresh** — `inspector plan pull --plan <id> --slug <s>` (by id), `inspector plan pull --project <KEY>`
   (the project's current/latest-version plan, no id needed — same one the web opens), or
   `inspector plan sync test/plans/<s>`. The server only round-trips meta + scope, so both **merge**
   onto the local file and keep sections/milestones/schedule_tasks. `--force` resets those to empty —
   only use it when the user asks to discard local authoring.

## Rules

- **feature_id is sacred** — only real catalog UUIDs from `inspector tree`. A wrong id fails validation.
- **complexity enum is `simple|medium|complex`** (not low/medium/high — that's `priority`).
- Keep every schedule task's `title` non-empty and its `task_type`/`resource` within the allowed sets.
- Don't author assignee/environment/dependency/explicit dates locally — that's a web-side edit.
- Prefer authoring sections concisely; `introduction` and `test_items` should not be empty.
- **Sections are PLAIN TEXT — no Markdown.** Kari renders them with `white-space: pre-wrap` and the
  Excel export copies the characters verbatim: `#`, `**bold**`, `` `code` ``, `> quote`, `[a](b)` and
  pipe tables all show up as literal punctuation on screen. `plan validate` warns when it finds any.
  Structure with plain prose instead: an ALL-CAPS line as a heading, `- ` for lists, `1. ` for steps,
  and one item per line instead of a table (`Change Password - ưu tiên High, 17 MH.`).
  This is the opposite of TESTCASE fields, where a small inline Markdown subset IS rendered — see
  `../kari-inspector/references/markdown-formatting.md`. Never carry that habit into a plan.
- **Bar dates are derived from `duration_days`**, and schedule tasks are laid back-to-back inside the
  bar and **clamped to its end**: if the tasks need more working days than the bar has, the extra ones
  are dropped on push. The preview counts them — fix by raising that function's `duration_days`.
- **`approved` is terminal.** There is no endpoint back out of it: not editable, and `clone` only
  accepts `rejected`. Warn the user before they approve a plan you are not confident in — the only
  way forward afterwards is a brand-new plan. A reviewer who wants changes should use
  **request-changes** (→ `changes_requested`, still editable), not approve.
- Milestone `order_index` is optional locally — the CLI sends the array position. Don't hand-number
  them unless the user wants a specific order; duplicates break a unique constraint server-side.
