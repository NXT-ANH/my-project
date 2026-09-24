---
name: inspector-gen-test
description: >
  Generate Kari Inspector testcases for a feature — clarify the requirement, write standard JSON,
  self-review it, serve it for the user to comment on in the browser (`inspector review`), then push a
  draft. ALWAYS use this when the user asks to create / write / add testcases, "gen testcase for X",
  "viết testcase", "tạo test case", or to draft testcases for a feature/Jira task.
---

# Inspector — Generate testcases (JSON-first)

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside (shared rules load from
`../kari-inspector/references/`). Companions: `inspector-review`, `inspector-e2e`.

**CLI:** `inspector`, from `@kaopiz/inspector-cli` (`npm i -g`, or `npx`). Inside the inspector-cli repo
itself: `npm link` from `src/inspector-cli/`. `inspector init` for auth; a `401/403` re-prompts
automatically.

**Config first.** If `.inspector/config.json` is missing `project_key` / `work_dir` / `e2e_dir`, run
`../kari-inspector/references/project-setup.md`. Examples below use the default `work_dir` (`test/`) —
substitute the configured value.

## Core principles

1. **Clarify first** — loop with `AskUserQuestion` to ≥90% confidence before writing anything.
2. **Ground in spec + code** (Step 2) — testcases must match the real field names, limits, and error
   strings. When spec and code disagree, surface it and let the user pick.
3. **JSON is the source of truth.** Never hand-write the review page — write JSON, let `convert` render.
4. **Propose → AI self-review (Step 6) → user review (Step 7) → push.** Never push straight from `convert`.
5. **Never invent a `feature_id` or Jira key** — resolve via CLI / Jira MCP.
6. **Apply `.inspector/rules.md`** if present (append-only; kit rules win on conflict —
   `../kari-inspector/references/project-rules.md`).
7. **Write in the user's language** (Vietnamese when the user chats Vietnamese or existing testcases are).
   `[L1]` tags, field/button/API names and enum values stay literal — generation-rules §0.

## Tracking the run (`TaskCreate`)

Create the list **right after Step 1 confirms scope** (before that you don't know how many features are
involved). One task per remaining step; drop ones that don't apply:

```
Ground in spec + code (2) · Resolve feature tree (3) · Gap-analyze existing (4)
Write + validate + render (5) · AI self-review (6) · User review in browser (7)
Push the draft (8) · Sync testcase codes (9)
```

- **Step 7 completes only when the review server is stopped**; keep it `in_progress` across note loops.
- **Step 9 usually stays `pending`** past the session — it needs the draft applied in Kari first. Say so.

Skip the list only if the user asks, or the run is genuinely one step (e.g. re-pushing one edited testcase).

## Workflow

### Step 1 — Clarify the requirement (`AskUserQuestion`)

Spec source: a Jira task (fetch via `jira_get_issue` — `../kari-inspector/references/jira-handling.md`),
pasted text, or a spec file in the repo.

Assess confidence against: input fields + validation, success flow, error cases + messages,
roles/permissions, conditional business rules. Ask each gap via `AskUserQuestion` (max 3–4 per call), the
industry-standard option pre-selected plus "Enter manually" —
`../kari-inspector/references/industry-defaults.md`. Loop to ≥90%, then summarize (2–5 bullets) and
confirm: "Correct, proceed" / "Needs adjustment".

**Decide the test level in the same pass** — it changes *what you write*, so deciding it later means
rewriting. Rules + comparison table: generation-rules §0.2.

- **Default IT** (`integration_test`) — one screen / feature / function. Don't ask when the spec clearly
  covers a single screen.
- **ST** (`system_test`) — a business process spanning modules, or the user says "luồng" / "end-to-end".
- **Ambiguous** → fold into the Step 1 question batch, not a separate round-trip.

Include the level in the Step 1 summary and carry it into `gen --test-level` (Step 5). **One draft = one
level** — the CLI rejects mixing; if the requirement needs both, plan two drafts and say so.

#### Step 1b — ST business chain (mandatory when level = ST)

When Step 1 chose **ST** (or the user asked for luồng / system / E2E journey coverage), **do not write ST
JSON yet**. Follow generation-rules **§0.2.1**:

1. Extract a proposed **ordered module/screen chain** from SRS/Jira/AC (bullet list).
2. Read `.inspector/domain-map.md` if it exists (and `.inspector/rules.md` if filled). Kit template:
   `../kari-inspector/references/domain-map.example.md` — projects copy it to `.inspector/domain-map.md`.
3. If the chain is ambiguous or not confirmed in the domain map → `AskUserQuestion` **once**. If a confirmed
   chain matches → reuse it and state the assumption in one line.
4. Plan **chained short ST cases** along that flow (hard split when a case would exceed 15 steps; fill
   checkpoint `steps[].expected` per §0.2.1). Keep the IT feature tree; span multiple leaf features in one
   draft when needed — no "Flow" feature type.
5. Only then continue Steps 2–5 for ST authoring.

Never paste another product's module names from memory or from a foreign domain map.

### Step 2 — Ground in spec docs + current code (mandatory)

Collect, for the feature under test:

1. **Spec** — the Jira task or repo spec file: acceptance criteria, validation rules, exact error
   messages, roles, business rules.
2. **Implementation** — the source of truth for *behavior*: backend handler/endpoint + request schema,
   core logic, frontend page/component (fields, validation, exact user-visible strings incl. i18n files).
3. **Existing tests** — unit / component / E2E already covering this, so you don't duplicate coverage.

Paths vary per project — search rather than assume. **Recommended:** spawn the **`Explore`** agent
(`subagent_type: "Explore"`) to sweep for spec + code in one pass and return a short evidence list (ACs +
`file:line` for field names, limits, error strings, branches), keeping read-heavy research off this
session's context. Fall back to `Grep`/`Glob`/`Read`.

Keep the evidence list for Step 6. **If spec contradicts code**, don't silently pick — `AskUserQuestion`
for the source of truth before writing. If neither spec nor Jira task exists, say so and author against
the generation rules + code, flagging that coverage wasn't checked against a written spec.

### Step 3 — Resolve the feature tree (get `feature_id`)

Tree shape + title-prefix rules: generation-rules §1.1. Shared read → propose → confirm → create loop
(and reading the SRS from `docs_dir`): `../kari-inspector/references/feature-tree.md`. **Depth for
testcases: Leaf** — the Item-level guidance below is what makes this skill's targets finer than a plan's
or a viewpoint's.

```
inspector projects                 # → project_key
inspector apps --project <KEY>     # → app_id
inspector features --app <app_id>  # → nested tree; the matching feature's UUID = feature_id
inspector tree --app <app_id>      # optional: cache → .inspector/features/<app_id>.json
```

The tree nests by `parent_feature_id` (**Module → Screen → Function → Item**). Each testcase file targets
a **leaf** feature, not the Module.

If no matching feature exists, propose one on the spot (don't defer):

1. **Module** — an existing one, or a new top-level grouping matching the spec's domain.
2. **Screen** — one screen.
3. **Function** — split only if the screen offers more than one distinct, independently-usable function
   (Login SSO / Login Local / Register). Skip this level for a single-function screen.
4. **Item** — split whenever the screen/function holds more than one distinct field-group or section
   (General Info / Pricing / Media), targeting **under ~10 testcases per leaf** (generation-rules §1.1).
   Stop at Function/Screen only for a genuinely single, undivided field-group. Don't pad thin Items.
5. Confirm the proposed names with `AskUserQuestion` (proposed structure / "Enter manually").
6. Create top-down so parents exist first:

```
inspector feature create --app <app_id> --name "<Module>"
inspector feature create --app <app_id> --name "<Screen>"   --parent <module_id>
inspector feature create --app <app_id> --name "<Function>" --parent <screen_id>   # → leaf feature_id
```

`inspector feature update <id> --parent <new>` re-parents; `inspector feature delete <id>` removes a
mistake (refused if it still has children or active testcases). MCP `kari_create_feature` is the fallback.

### Step 4 — Gap analysis against existing testcases

Refresh the **active mirror** first, so you reason about what is actually live:

```
inspector pull --app <app_id> --project <KEY>     # whole app → test/<level>/testcases/<app>/<mod>/<feat>.json
inspector pull --feature-id <uuid> --project <KEY> --app <app> --module <mod> --feature <feat>  # one feature
```

`pull --app` walks the tree and refreshes every **leaf** feature (merging, so local-only testcases
survive). Read the files for the feature under test, then produce a short gap analysis —
**ADD / UPDATE / DELETE** per existing testcase — and confirm it with `AskUserQuestion` before writing.
An existing testcase also tells you the team's **language** — match it.

> **Draft-folder model:** a draft = one writing session = one folder `test/<level>/drafts/<slug>/`, holding
> `draft.json` (title + server `draft_id` + `test_level`) plus **one `<feature>.testcases.json` per leaf
> feature** — so a draft can span several features, but only ever one test level (IT and ST are separate
> trees from the top; a draft never mixes them). `test/<level>/testcases/…` is the per-feature active
> mirror that `sync` (Step 9) populates. One draft per writing session.

#### Changing an ACTIVE testcase (UPDATE / DELETE)

Active testcases are server-owned; they only change **through a draft**, and only once that draft is
**applied** in Kari. Never edit `test/<level>/testcases/**` and push it — `push` refuses (that tree is the
mirror).

1. Copy the testcase **from the mirror into the draft folder's feature file** — keep its `sync` block
   intact (`sync.testcase_id` is what identifies the active row; hand-writing it doesn't work).
2. Add `"change": "update"` (then edit the content) or `"change": "delete"` (leave the content as-is —
   it's the server's current version, shown for reference).
3. `validate` → `convert` → push as usual. The review page badges each one **UPDATE** / **DELETE**.

```jsonc
{
  "title": "[Main] Đăng nhập nội bộ thành công",   // edited content for an update
  "change": "update",
  "sync": { "testcase_id": "…", "version_id": "…", "testcase_uid": "KPP-001_005" }
}
```

`validate` blocks the two mistakes that corrupt data: a `change` without `sync.testcase_id`, and an
active testcase pasted in **without** `change` (which would push as a duplicate of a live testcase).
ADD stays the default — a brand-new testcase has no `sync` block and no `change`.

### Step 5 — Write JSON → validate → render

**Reusing a draft folder? Check its server status first.** `gen` silently reuses
`test/<level>/drafts/<slug>/draft.json` when the slug exists on disk, but that file only stores `draft_id`
— never `status` — so it goes stale after a push. If that draft was applied in Kari since, appending new
testcases lands them as orphaned `draft`-status rows that never go active (`append-testcases` isn't blocked
on an applied draft server-side). Check before writing:

```
kari_get_draft <draft_id>     # MCP — read-only; `.draft.status` is the live value
```

No bare CLI check exists (`inspector pull --draft <id>` also fetches it but writes review files as a side
effect — avoid). **`status` ≠ `APPLIED`** → safe to keep appending. **`status` = `APPLIED`** → finalized,
don't reuse; pick a fresh `--draft <slug>` (e.g. `<slug>-2`) instead.

Pick a `--draft <slug>` (usually the screen name); run `gen` once per leaf feature into the same slug:

```
inspector gen --project <KEY> --app <app> --module <mod> --feature <feat-1> --feature-id <uuid-1> \
  --draft <slug> --title "<Draft title>" --test-level <integration_test|system_test> [--jira <KEY>]
inspector gen ... --feature <feat-2> --feature-id <uuid-2> --draft <slug>   # inherits the draft's level
```

`--test-level` goes on the **first** `gen` of a draft (default `integration_test`); later features inherit
it — a different value is a hard error, and `validate`/`push` re-check it against `draft.json`.

Fill `testcases[]` per `inspector-cli/schema/testcases.schema.json`; each file's `meta.feature_id` is its
**leaf** feature. Field + order rules: generation-rules §2. Inline Markdown:
`../kari-inspector/references/markdown-formatting.md`. **Read `.inspector/rules.md` now** if present and
filled in.

**Order:** the per-testcase `order` drives display order; `convert` fills `0,1,2…`, so normally just author
top-to-bottom. To insert a case **under** case X, place it right after X and give it X's `order`.

```
inspector validate test/<level>/drafts/<slug>
inspector convert  test/<level>/drafts/<slug> --write-ids          # → self-contained HTML review page
inspector convert  test/<level>/drafts/<slug> --write-ids --md     # or one Markdown per level-2 screen
```

`convert` groups by screen and labels each testcase with its feature (run `inspector tree --app <app_id>`
once so grouping works). Show the output path + a 1-line summary, then go straight to Step 6 — **don't** ask
for push approval yet, and **don't** hand the user the `.html` path (see Step 7).

### Step 6 — Mandatory automated self-review (subagent)

Always run this; it's not gated behind a question. Use the `Agent` tool
(`subagent_type: "general-purpose"`):

```
Skill: inspector-review — review the LOCAL draft folder test/<level>/drafts/<slug>/ (already generated this
session; do NOT pull a server draft — it isn't pushed yet). Ground the review in the feature's spec and
its real implementation per that skill's Step 2. For system_test drafts, also apply the ST checklist
(generation-rules §0.2.1 / FB No.114: business-flow vs function-centric, step count >15, checkpoint
expects, domain contamination). Return ONLY the actionable comment list (Approved /
Needs revision / Suggested additions), each finding citing a testcase id + file:line or AC. Do not post
anything to Kari and do not edit any file.
```

One automatic round. Summarize the findings (2–6 bullets: counts + highest-severity items); if
`.inspector/rules.md` was in play, add one line naming the project rules applied and any conflict flagged.
Then gate with `AskUserQuestion`:

- **Apply review fixes** → edit JSON, re-run `validate` + `convert`, show the diff summary → Step 7.
- **Skip the fixes** → Step 7 (the user consciously accepted the findings).
- **I'll edit the file first** → wait, then re-run validate/convert/this step.
- **Cancel** → stop.

> `Agent` tool unavailable → invoke `inspector-review` inline on the same folder, then the same gate.
> Never skip the review silently.

### Step 7 — User review in the browser (`inspector review`, mandatory)

The AI review doesn't replace the author's own eyes. **Don't hand over the static `.html` path** — opened
as `file://` the comment UI is gated off (`window.__REVIEW_SERVER__`) and notes can't be saved.

```
inspector review test/<level>/drafts/<slug> --open     # Bash run_in_background: true — it blocks until Ctrl-C
```

Read the background output for the **actual** port (`review` falls back to a random free port when 7333 is
taken). `--open` launches the browser; still print the URL since the opener can fail silently.

Tell the user in one short message: the URL, that they highlight text inside a testcase to attach a note,
and that you'll wait. Then `AskUserQuestion`:

- **Process my notes** → handle every `status: "open"` note in `test/<level>/drafts/<slug>/comments.json` per the
  **`inspector-review-notes`** skill, tell the user a reload shows the refresh, then ask "More notes, or
  push?" → loop / push. No file or no open notes → say so and go to push.
- **No notes — push as-is** → Step 8.
- **Cancel** → stop.

**Stop the server** (`TaskStop`) once the user moves on. These notes are local and pre-push — never
pushed or synced.

### Step 8 — Push the draft

```
inspector push test/<level>/drafts/<slug>
```

Creates the draft **once** (from `draft.json`) and appends all feature files to it — one server draft
spanning every feature in the folder. Writes `draft_id` into `draft.json` and `version_id` + `status` +
`content_hash` into each feature file, and prints the Kari URL (`<base_url>/drafts/<id>`) — **give the
user that link**.

**Editing after a push:** edit the JSON and run `push` again. It compares each testcase against the stored
`content_hash`: new ones appended (`+`), edited ones updated in place keeping the same `version_id` (`~`),
unchanged skipped. `--all` forces everything through the update path. Submitting for review / approving
stays in the Kari UI (or `kari_update_draft` MCP).

**Testcases carrying `change`** (Step 4) go to the active-change endpoint instead — printed as
`~ UPDATE` / `- DELETE`. They do **not** touch the live testcase yet: it stays active, with its `uid`
intact, until the draft is applied. Tell the user that explicitly, so nobody expects the change to show
up in Kari's testcase list right away.

**Push failed partway** → just run it again. `draft_id` and per-file `version_id`s are recorded as they
land, so a retry reuses the same draft and sends only what's missing. Only if `draft.json` has no
`draft_id` did the draft never get created.

### Step 9 — After apply, sync the codes

```
inspector sync test/<level>/drafts/<slug>
```

Mints `sync.testcase_uid` (e.g. `KPP-001_003`) + status onto matched testcases, then **moves** the active
ones into `test/<level>/testcases/<app>/<mod>/<feature>.testcases.json`. Still-draft testcases stay; once every
feature file is fully active the draft folder is removed.

> Remove an orphaned/duplicate server draft: `inspector draft delete <draft_id>`.

## Interaction rule

Use `AskUserQuestion` for every decision/gate; plain text only for summaries. The Step 6 self-review and
the Step 7 review server always run — only the decisions that follow them are gates.
