# Jira task handling

Kari doesn't store or fetch Jira content — `jira_task_key` on a draft is **link metadata only**. When the
spec lives on Jira, fetch it via **Atlassian MCP**, then pass the key to `inspector gen --jira <KEY>` so the
link shows on the draft.

Apply at the **start of Step 1** — resolving the spec source early prevents wasted clarification rounds.

## 1. Detect a task key

Scan the user message, pasted text, or any URL for `[A-Z]{2,}-\d+` — standalone (`SPOQR-144`), in a URL
(`…/browse/SPOQR-144`), or anywhere prominent in a paste. Found → treat it as implicitly provided; confirm
rather than re-ask.

| Situation | What to do |
|-----------|-----------|
| Key detected | `AskUserQuestion`: "Found Jira task `<KEY>` — fetch its content as the spec?" → "Yes, fetch" \| "No, ignore" \| "Use a different key" |
| User mentioned a Jira task, no key | Ask for the key |
| No mention of Jira | `AskUserQuestion`: "Is there a related Jira task?" → "Yes — I'll provide the key" \| "No — continue without" |
| User declines | Continue without `jira_task_key`; don't block. Fall back to paste / docs / defaults |

## 2. Fetch it

```
jira_get_issue(issue_key="SPOQR-144",
               fields="summary,description,status,issuetype,priority,labels",
               expand="renderedFields")
```

`renderedFields` helps when the description uses Jira wiki markup.

- **Found** → `summary` + `description` are the primary spec. Mention `<KEY>: <summary>` in the Step 1
  confirmation so the user can verify you fetched the right task.
- **404 / other error** → `AskUserQuestion`: "Try a different key" \| "Paste description manually" \| "Skip
  Jira and continue".
- **Atlassian MCP unavailable** → say so once, then continue with the normal clarification loop. Don't
  retry or bring it up again.

## 3. Passing the key on

Only when the user confirmed a real, fetched key: `inspector gen … --jira SPOQR-144`. Draft title pattern
`"[<JIRA-KEY>] <Feature> — <short purpose>"`, otherwise `"<Feature> — <short purpose>"`.

**Never fabricate a key.** A wrong key creates a broken traceability link that's hard to detect later —
worse than no key.
