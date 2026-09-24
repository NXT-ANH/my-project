---
name: inspector-e2e
description: >
  Write, run, debug, and verify Playwright E2E specs for Kari Inspector testcases. ALWAYS use this when the
  user asks to "chạy test e2e", "viết test e2e", "sửa/fix test e2e", "run playwright test", "debug e2e",
  "test e2e đang fail", or to create/make-pass automation for a feature's active testcases. It does NOT
  author *testcases* — that's `inspector-gen-test` / `inspector-review`; this skill turns already-active
  testcases into runnable specs and keeps them green.
---

# Inspector — E2E automation (Playwright)

Part of the Kari Inspector kit. Writes and maintains Playwright specs in the E2E dir (default `e2e/`,
usually a submodule) from a feature's active testcases. Companions: `inspector-gen-test`, `inspector-review`.

> `work_dir` (default `test`) and `e2e_dir` (default `e2e`) come from `.inspector/config.json` — never
> hardcode. Missing → run `../kari-inspector/references/project-setup.md` first.

## Prerequisites

- **inspector CLI** — `@kaopiz/inspector-cli` (inside the repo: `npm link` from `src/inspector-cli/`);
  `inspector init` for auth.
- **E2E dir checked out** — `git submodule update --init <e2e_dir>` if it's a submodule.
- **Playwright agent-cli** (https://playwright.dev/agent-cli) — used for exploring the app and authoring
  specs, not just debugging:
  ```
  npm install -g @playwright/cli@latest      # provides `playwright-cli` (Node ≥ 20)
  playwright-cli install --skills            # installs the `playwright-cli` skill into .claude/skills
  ```

## Hard rules

- **Stop when specs pass locally.** No PR, push to the app's E2E branch, or triggering auto test — those
  are the user's manual steps.
- **The testcase is the source of truth; the spec is derived from it.** If `steps[]` / `expected_result` is
  wrong or incomplete, don't work around it in the spec — fix the testcase via `inspector-gen-test` /
  `inspector-review` first (Step 3), then write the spec to match. Never invent scenarios or assertions the
  testcase doesn't cover.
- **Test title must start with `sync.testcase_uid`** (Step 3) — the server maps results back to Kari by
  parsing the leading token before the first `:`/dash/space in the report title. Get this wrong and the run
  result shows "no matching testcase" instead of pass/fail.
- **Delegate all browser exploration and spec authoring to the `playwright-cli` skill** (`references/`:
  `test-generation.md` for plan/generate/heal, `playwright-tests.md` for the runner, `session-management.md`,
  `tracing.md`). One persistent session per app: `playwright-cli -s=<app>-e2e <command>`.

## Tracking the run (`TaskCreate`)

Create after Step 2, once you know how many features/testcases are in play. One task per step, plus one per
feature needing a spec written or fixed:

```
Sync active testcases (1) · Ground in FE source (2) · Write/update <feat>.spec.ts (3 — one per feature)
Run the specs (4) · Debug failures (5 — one per failing spec) · Report results (6)
```

A Step 3/5 task completes only when the spec exists, is named to map back to Kari, and **passes** — or the
failure is classified and routed (app bug reported, testcase handed back upstream). Skip the list for a
single-spec run the user just asked you to execute.

## Workflow

### 1 — Sync active testcases

Refresh from the server first — a stale local mirror produces specs that don't match reality. Sync the
whole app's active mirror (same command `inspector-gen-test` Step 4 uses):

```
inspector pull --app <app_id> --project <KEY>     # → <work_dir>/<level>/testcases/<app>/<mod>/<feat>.json
```

Defaults to `--status active`, walks the whole feature tree, merges into
`<work_dir>/<level>/testcases/<app>/<mod>/<feat>.testcases.json` (local-only entries survive re-sync). Scope
to one feature with `--feature-id <uuid> --project <KEY> --app <app> --module <mod> --feature <feat>`, but
still pass `--status active` — a bare `pull` fetches every status, and a draft/archived testcase has no
`sync.testcase_uid` to build a spec from.

Only testcases with `sync.testcase_uid` are active — that UID, `steps[]`, and `expected_result` become the
spec test. Read `test_case_type` and `severity` too: a CRITICAL happy path deserves tighter assertions than
a LOW edge case.

### 2 — Ground in the real app (mandatory before writing)

A spec built purely from `steps[]` text guesses at selectors and drifts on the first UI change:

1. **Frontend source, if in this workspace** — find the page/component (fields, `data-testid`/ARIA roles,
   exact strings incl. i18n, validation, routes). Search rather than assume; spawn `Explore` for a broad
   sweep. Reuse findings from a preceding `gen-test` session if this run follows one directly.
2. **The live app** — via `playwright-cli` (`-s=<app>-e2e open <base-url>`, `snapshot`, `find`) to confirm
   real locators and current behavior, even when FE source is available (source shows intent, DOM shows
   what's rendered).
3. **Existing specs/pages/fixtures in `<e2e_dir>`** — `pages/{Name}Page.ts` (POM), `fixtures/`,
   `data/{feature}/*.json`. Check `## Generated Assets` at the bottom of `<e2e_dir>/CLAUDE.md` before
   creating any file — if listed, import it, don't recreate it.

If FE source isn't in this workspace, rely on (2) and (3) alone and say so — don't block on it.

### 3 — Write or update the spec

Follow `<e2e_dir>/CLAUDE.md` conventions (POM, fixtures, `data/{feature}/*.json`, TypeScript strict). Use
`playwright-cli`'s `references/test-generation.md` plan → generate → heal flow: drive the app live, capture
the generated code, assemble it into `<e2e_dir>/tests/<app>/<mod>/<feat>.spec.ts`, add explicit assertions
per testcase's `expected_result`.

One `test(...)` per testcase, one spec file per feature (mirrors
`<work_dir>/<level>/testcases/<app>/<mod>/<feat>.testcases.json`). Title = `sync.testcase_uid` copied
exactly, then a separator (`:`, `-`, `–`, `—`, whitespace), then a short description:

```typescript
test('KPP-001_001: shows error on invalid credentials', async ({ page }) => {
  // steps[] → actions, expected_result → assertions
});
```

A testcase with no `sync.testcase_uid` (draft/pending) has nothing to automate yet — skip it and say so.

**If a testcase itself is wrong** (wrong field name, stale flow, missing case found while grounding or
writing): don't silently write a spec that matches the app while ignoring the testcase. Flag it, hand back
to `inspector-review` / `inspector-gen-test` to correct it through a draft (it's active), then update the
spec once fixed. Only write straight to spec when the testcase is already correct.

### 4 — Run

```
cd <e2e_dir> && npx playwright test tests/<app>/<mod>/<feat>.spec.ts
```

(via `playwright-cli`'s Playwright-tests flow — that flow *is* `@playwright/test`, the runner in the E2E dir)

### 5 — Debug & classify failures (loop)

Read the error + trace (`playwright-cli` `references/tracing.md`), reproduce the failing step live
(`playwright-cli -s=<app>-e2e open <base-url>` → `snapshot` / `find`; base URL from `inspector projects` or
`.inspector/config.json`). Classify:

- **Spec bug** (wrong locator, timing, assertion) → fix the spec directly; re-run.
- **App bug** (behavior ≠ `expected_result`) → report it; the spec is correct as written.
- **Testcase problem** (step/expected wrong) → hand back per Step 3's note, update the spec once corrected.

### 6 — Report

Per `testcase_uid`: which specs pass, which fail and why (spec bug / app bug / testcase problem — all fixed
or routed, not left red), and any active testcases still with no spec (not yet reached, or blocked on a
testcase fix). Note the `testcase_uid → spec test` mapping so results trace back to Kari.
