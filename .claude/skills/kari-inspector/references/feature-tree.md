# Feature tree — derive from SRS, confirm, create

The catalog **feature tree** is the shared prerequisite for authoring testcases, a **test plan**, and a
**test viewpoint**. All three are bounded by it: a testcase targets a leaf `feature_id`, a plan's `scope`
references a `feature_id` per function, and a viewpoint's matrix **columns are the tree itself** (level-1
roots + their direct children). So before you author any of them, make the tree exist — grounded in the
project's SRS, never fabricated.

Use this procedure wherever a skill says "build the feature tree from SRS". The **depth** you build to
depends on the artifact (see the table); the read → propose → confirm → create loop is the same.

## Procedure

1. **Read the SRS.** Resolve `docs_dir` (config `docs_dir` → default `docs`; if unset, survey the repo per
   `project-setup.md` and persist it into `.inspector/config.json`). Scan that folder — the usual layout is
   `data-source/`, `srs/`, `basic-design/`, `detail-design/` subfolders — and read the SRS (plus basic
   design when present) to understand the functional scope. Spawn the **`Explore`** agent
   (`subagent_type: "Explore"`) to keep the reading off this session's context. No SRS found → tell the
   user and fall back to the scope they describe; don't invent modules.
2. **Fetch the current tree** — `inspector tree --app <app_id> --project <KEY>` →
   `.inspector/features/<app_id>.json`. This is the source of truth for what already exists. The tree nests
   by `parent_feature_id` (**Module → Screen → Function → Item**).
3. **Propose** a tree that covers the SRS, mapped against what already exists: mark each node **exists**
   (with its `feature_id`) or **new**. Build only to the depth the artifact needs (table below). Present it
   and gate on **`AskUserQuestion`** ("Tạo các feature còn thiếu này lên hệ thống?" — proposed structure /
   "Enter manually") so the user can add / remove / rename first. **Never create without this confirmation.**
4. **Create only the approved missing nodes, top-down so parents exist first:**
   ```
   inspector feature create --app <app_id> --name "<Module>"
   inspector feature create --app <app_id> --name "<Screen>"   --parent <module_id>
   inspector feature create --app <app_id> --name "<Function>" --parent <screen_id>   # → leaf feature_id
   ```
   Pass `--description` from the SRS where useful. Never re-create a node that already `exists`, and
   **never fabricate a `feature_id`**.
5. **Re-fetch** — `inspector tree --app <app_id> --project <KEY>` again so every new `feature_id` lands in
   `.inspector/features/<app_id>.json` for whatever you author next.

## Depth by artifact

| Authoring | Build to | Notes |
|---|---|---|
| **Testcases** (`inspector-gen-test`) | **Leaf** (Module → Screen → Function → Item) | Each testcase targets a leaf; aim **< ~10 testcases per leaf** (generation-rules §1.1). Split Item only for a distinct field-group/section. |
| **Test plan** (`inspector-gen-testplan`) | **Module → Function** | `scope` is modules → functions; each function needs a real `feature_id`. |
| **Test viewpoint** (`inspector-gen-viewpoint`) | **Module + direct children** (2 levels) | `viewpoint gen` builds columns from **level-1 roots + their direct children** per app. Deeper nodes don't become columns — build at least these two levels so no function is missing from the matrix. |

## Rules

- **`feature_id` is sacred** — only real catalog UUIDs from `inspector tree`. A wrong/invented id fails
  validation downstream.
- **Create top-down** — a child needs its parent's id for `--parent`, so create the Module before its
  Screens, the Screen before its Functions.
- **Confirm before creating** — always `AskUserQuestion` on the proposed structure; don't silently create
  features the user hasn't seen.
- **Idempotent** — re-running should create only what's still missing; re-fetch the tree first so you see
  what already exists.
