---
name: kari-inspector
description: >
  Router + shared reference library for the Kari Inspector kit. Points to the focused skills
  (inspector-gen-test, inspector-gen-testplan, inspector-gen-viewpoint, inspector-review, inspector-review-notes, inspector-address-review, inspector-e2e)
  and holds the rules they share: testcase generation rules, severity + test_case_type, testcase template
  + ID format, industry defaults, Jira spec handling, MCP setup. Prefer the specific skill; use this to
  decide which one, or to look up a shared rule.
---

# Kari Inspector — kit router

| User intent | Skill |
|-------------|-------|
| Create / write / add testcases for a feature or Jira task | **`inspector-gen-test`** |
| Author a **test plan** (scope + schedule + sections + milestones) for a project | **`inspector-gen-testplan`** |
| Author a **test viewpoint** (matrix of viewpoint rows × functions) for a project | **`inspector-gen-viewpoint`** |
| Review testcases (own, someone else's, or a pending draft); check coverage | **`inspector-review`** |
| Apply LOCAL self-review notes from `inspector review` ("xử lý review notes cho draft X") | **`inspector-review-notes`** |
| Apply SERVER review comments on a pushed draft ("xử lý comment reviewer cho draft X") | **`inspector-address-review`** |
| Write / run / debug Playwright E2E specs for active testcases | **`inspector-e2e`** |

> **Two different comment flows.** `<draft>/comments.json` = local pre-push self-review notes
> (`inspector review` browser page) → `inspector-review-notes`. `<draft>/review-comments.json` = Kari
> server `review_comments` on a pushed draft, anchored to `testcase_version_id`, pulled via
> `inspector comments <draft_id>` → `inspector-address-review`. Same folder, different files; never map
> one to the other.

All skills drive the local **`inspector` CLI** (JSON on disk instead of per-request MCP calls). Setup:
`inspector init` (server URL + token), then `references/project-setup.md` if `.inspector/config.json` is
missing `project_key` / `work_dir` / `e2e_dir`.

> **Project rules:** if `.inspector/rules.md` exists and is filled in, it is this team's **append-only**
> layer on top of `references/testcase-generation-rules.md` (kit rules win on conflict). Read it before
> authoring or reviewing — see `references/project-rules.md`.

## Shared references

- `project-setup.md` — resolve/persist `.inspector/config.json` (project code, `work_dir`, `e2e_dir`, `docs_dir`)
- `feature-tree.md` — build the catalog feature tree from SRS (read `docs_dir` → propose → confirm →
  `feature create`); shared prerequisite for gen-test / gen-testplan / gen-viewpoint
- `testcase-generation-rules.md` — output format, coverage techniques, severity, test_case_type;
  **§0.2.1** for System Test business-flow authoring
- `domain-map.example.md` — template for project `.inspector/domain-map.md` (ST module chains)
- `project-rules.md` — how to apply `.inspector/rules.md`
- `testcase-template.md` — directory/file naming, testcase ID format, draft-folder layout
- `markdown-formatting.md` — inline Markdown the UI renders in testcase fields
- `industry-defaults.md` — default values to offer in `AskUserQuestion`
- `jira-handling.md` — fetching a spec from Jira via Atlassian MCP
- `mcp-setup.md` — connecting the Kari + Atlassian MCP servers (fallback path)

## MCP vs CLI

The CLI is the primary path and covers projects/apps/features, gen/validate/convert, push/pull/sync
(including **update/delete of active testcases** — see below), review comments (`inspector comments` —
pull / `post` / `resolve`), and `dashboard`. `mcp-atlassian` (`jira_*`) is how you read task/requirement
info from Jira. `kari-inspector` (`kari_*`) is a **fallback** for the few gaps:

| Operation | Tool |
|---|---|
| List drafts | `kari_list_drafts(project_key, status=…)` |
| Submit for review / approve / apply a draft | Kari UI, or `kari_update_draft(draft_id, status=…)` |
| Remove one change from a draft | `kari_remove_draft_testcase(...)` |

> **Active testcases only change through a draft**, and only once that draft is **applied**. The CLI path:
> `inspector pull --app <app_id>` (refresh the mirror) → copy the testcase into a draft folder keeping its
> `sync` block → set `"change": "update" | "delete"` → `push`. Never edit `<work_dir>/testcases/**` and push
> it; that tree is the server-owned mirror and `push` refuses it. Details: `inspector-gen-test` Step 4.

Kari MCP unavailable → `references/mcp-setup.md`. Atlassian MCP unavailable → ask the user to paste the spec.
