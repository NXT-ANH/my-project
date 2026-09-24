---
name: inspector-address-review
description: >
  Address SERVER-side review comments on a pushed Kari draft: pull reviewers' comments with
  `inspector comments <draft_id>`, edit the affected testcases, then hand the author the exact
  `inspector push` + `inspector comments post --reply-to` commands (the REVIEWER resolves comments, never
  the author). ALWAYS use this when the user says "xử lý comment reviewer trên hệ thống cho draft X", "sửa
  testcase theo review của người khác", or "address the review comments on draft X". NOT the local pre-push
  self-review notes — those are inspector-review-notes.
---

# Address server review comments → fix testcases → hand back push/reply

Part of the Kari Inspector kit; requires the `kari-inspector` skill alongside.

> `<work_dir>` comes from `.inspector/config.json` (default `test`) — don't hardcode `test/`. Missing
> config → run `../kari-inspector/references/project-setup.md` first.

## Scope

These are **server-side** `review_comments`: they live in Kari, attach to a `testcase_version_id`, and
appear on the Draft Detail page after `push`. Distinct from the local pre-push `<draft>/comments.json`
notes (`inspector-review-notes`). It doesn't matter who authored the draft — anyone can pull it and fix it.

**Resolving is the REVIEWER's action, never the fixer's.** The reviewer raised the point, so the reviewer
decides it's settled. This side of the loop ends at *fix → push → reply*. The server doesn't enforce this,
so the discipline lives here.

**Do not auto-push.** Edit the JSON, then hand back the commands.

## Steps

1. **Pull comments:** `inspector comments <draft_id>`. They land as a flat list in
   `<work_dir>/drafts/<slug>/review-comments.json`, each entry carrying `file` + `testcase_title` naming
   the exact draft file and testcase — **you edit the draft files themselves**, there is no second copy.
   The summary line reports how many are unresolved.

   If the draft folder isn't on this machine, the command **pulls the draft down first** and says so — you
   get a real, pushable folder (`draft.json` linked to the `draft_id`, testcases keeping their
   `sync.version_id`).

   > **Only reviewing, not fixing?** `--reviewer` (or `--out <dir>`) rebuilds the draft under
   > `<work_dir>/reviews/<draft-slug>/` with a `review_comments: [...]` array per testcase instead. It
   > refuses to overwrite a review file you edited but haven't pushed (`--force` to take the server's
   > copy). You can't push from it.

2. **Work only unresolved, top-level comments** (`resolved: false`, no `parent_comment_id`):
   - Read `comment`; use `quoted_text` + `anchor_field` (`title`, `preconditions`, `expected_result`,
     `steps[0].action`…) to locate the exact spot.
   - Apply the change to the testcase's own fields, keeping its language (generation-rules §0).
   - Comment unclear → leave the testcase unchanged and note it for the author; don't invent a fix.

3. **Do NOT edit the comment records, push, or resolve.** `review-comments.json` is a pulled mirror of the
   server — editing it changes nothing upstream and loses your notes on the next pull.

4. **Validate:** `inspector validate <work_dir>/drafts/<slug>`.

5. **Hand back the commands.** List which comment ids you addressed (and which you skipped + why), then:

   ```
   inspector push <work_dir>/drafts/<slug>
   inspector comments post <version_id> --reply-to <comment_id> "Đã sửa: <what changed>"
   ```

   `push` re-saves the edited testcases in place, keeping each `sync.version_id`, so the reviewer sees the
   fix on the same version. One reply per comment addressed; skipped or unclear ones get a reply asking for
   clarification instead.

   **Never** print `inspector comments resolve` — if the author asks, say the reviewer closes the comment
   after checking the fix.
