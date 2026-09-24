# Testcase Files — layout, naming, IDs

JSON is the authoring source of truth; the HTML/Markdown review page is **rendered by `inspector convert`**
— never hand-written. This file covers where the JSON lives and how files/IDs are named.

## Split by test level first, then by state

Everything lives under `<work_dir>/<level>/…`, where `<level>` is `integration_test` or `system_test` —
**IT and ST are separate trees from the top**, since they're different bodies of work (different scope,
authors, review cycles) and a testcase never moves between them. Under each level, state splits the same
way as before: `drafts/` (authoring + the pushed draft), `testcases/` (active mirror), `reviews/` (pulled
copies for reviewing).

## While authoring — draft folder (`<work_dir>/<level>/drafts/<slug>/`)

A **draft = one writing session = one folder**: a `draft.json` (title + server `draft_id` + `test_level`)
plus one `<feature>.testcases.json` per **leaf feature** the draft covers.

```
test/integration_test/drafts/
└── login/                          # draft slug (one writing session)
    ├── draft.json                  # { title, draft_id, project_key, app, test_level }
    ├── login-sso.testcases.json    # leaf feature "Login SSO"   (meta.feature_id = SSO)
    ├── login-local.testcases.json  # leaf feature "Login Local" (meta.feature_id = Local)
    └── login.html                  # rendered by convert (or login.md with --md)
```

- A draft may span **multiple leaf features**, but only ever **one test level** — mixing is a hard error
  (`gen`/`validate`/`push` all check). Needs both IT and ST → two separate draft folders/slugs.
- A bare slug (e.g. `inspector push login`) is looked up under both levels; if it exists under both, pass
  `--test-level <integration_test|system_test>` or the full path to disambiguate.
- `convert` renders **one self-contained HTML page** by default (screen-grouped, search/filter,
  tree/table toggle); `--md` writes **one `<screen>.md` per level-2 screen**, combining child features and
  labeling each testcase with the feature it belongs to.
- `push` sends the whole folder as one draft; `sync` moves active testcases into the mirror below.

## Active mirror (`<work_dir>/<level>/testcases/<app>/<module>/<feature>.testcases.json`)

One file per **leaf** feature, `<module>` being its root (level-1) ancestor. Written by `sync` (as
testcases go active) and by `inspector pull --app <app_id>` (refresh the whole app at once):

```
test/integration_test/testcases/web-app/auth/login-sso.testcases.json
test/integration_test/testcases/web-app/auth/login-local.testcases.json
test/system_test/testcases/web-app/checkout/full-purchase-flow.testcases.json
```

**Read-only in practice.** It mirrors what the server owns, and `push` refuses to send from it. To change
an active testcase, copy it into a draft folder (keeping its `sync` block) and set `"change": "update"` or
`"delete"` — see `inspector-gen-test` Step 4.

> Recommended structure — if the project already uses a different layout, respect that instead.

## Naming rules

- Directories and files: **kebab-case**, ASCII only, no accented characters.
- Feature file name = the leaf feature name in the system (abbreviate if long).
- Draft slug = the screen/session name (e.g. `login`); the rendered file takes the screen slug.

## Testcase ID format

`<PROJECT_KEY>_NNN` — the Kari project key, an underscore, then a 3-digit zero-padded sequence per file
(starts at `001`). Examples: `MOS_001`, `SPR_007`, `KARI_142`.

`PROJECT_KEY` is exactly the `project_key` from `inspector projects`. `convert --write-ids` / `validate`
assign IDs when omitted. Do **not** use a generic `TC-001` prefix — the project prefix tells reviewers at a
glance which project a testcase belongs to and matches how Kari displays IDs.

## Testcase order

The integer `order` field fixes display position within the feature — the single source of truth shared by
the rendered page, `push` (server `order_index`) and `pull`. Normally leave it out: `convert` auto-numbers
`0,1,2…` in array order. Set it explicitly only to **insert a case under a specific one** — give the new
case that case's `order` (duplicates fine) and place it right after it in the array. The CLI never shifts
other cases' order.
