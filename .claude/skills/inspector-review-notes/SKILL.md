---
name: inspector-review-notes
description: >
  Process LOCAL self-review notes on a Kari draft (from `inspector review`): read <draft>/comments.json,
  edit the testcase JSON per each open note, mark it resolved, and re-render. ALWAYS use this when the user
  says "xử lý review notes cho draft X", "sửa testcase theo note đã comment", "apply my review notes", or
  refers to comments they left in the `inspector review` browser page. These are pre-push, local-only notes
  — for reviewers' comments on an already-pushed draft, use inspector-address-review instead.
---

# Process local review notes → fix testcases → re-render

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside.

> `<work_dir>` comes from `.inspector/config.json` (default `test`) — don't hardcode `test/`. Missing
> config → run `../kari-inspector/references/project-setup.md` first.

## Scope

These notes live only in `<work_dir>/drafts/<slug>/comments.json` — a local self-review aid before
`inspector push`. Never push or sync them.

> **Same folder, different file:** `review-comments.json` next to it holds the reviewers' *server*
> comments, handled by `inspector-address-review`. Don't read or write it here; resolving a note in
> `comments.json` says nothing about a server comment.

## Steps

1. Read `<work_dir>/drafts/<slug>/comments.json`. Work only on notes with `status: "open"`.
2. For each open note:
   - Open the feature file whose testcase `id` matches `note.testcase_id`.
   - Navigate to `note.field`: `title` / `preconditions` / `expected_result` → the scalar field;
     `steps[i].action` / `steps[i].test_data` / `steps[i].expected` → the i-th (0-based) step.
   - Apply what `note.body` describes, keeping the testcase's own language.
   - Unsure what the note wants → leave it `open` with a short clarifying line; don't invent a fix.
3. For each note you actually addressed, set `status: "resolved"` + `resolved_at` (ISO timestamp), save.
4. Re-render: `inspector convert <work_dir>/drafts/<slug>`.
5. Tell the user to reopen `inspector review <work_dir>/drafts/<slug>` for the next pass. Notes whose
   anchored text you changed now show as **stale** — expected; it flags what you touched.

## Do not

- Delete notes (the author owns deletion in the UI).
- Resolve a note you didn't address.
- Push, sync, or otherwise send these notes to the server.
