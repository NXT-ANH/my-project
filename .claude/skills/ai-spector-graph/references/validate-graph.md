# Task: validate-graph

Gate before generation. **User runs this command;** agent runs the CLI.

## Usage

- `/validate-graph`

## Required Behavior

**MCP (preferred when ai-spector server is configured):**

```
graph_validate({})
```

**CLI fallback:**

```bash
npx ai-spector graph validate
```

Validation issues come in two kinds, and the command exits accordingly:

- **Fatal** (`SCHEMA`, `GRAPH-LOAD`, `NO-CYCLE`) — the graph is unusable. Non-zero exit.
- **Conformance / advisory** (`SECTION-TREE`, `DOC-SECTION-COVERAGE`, `DOMAIN-ANCHORED`, custom rules) — the graph loads and is traversable but some part doesn't match the shape a template implies. Printed as `[CONFORMANCE]`, exit 0. Add `--strict` (or `graph_validate({strict:true})`) to make them fatal in CI.

- **Success / exit 0, no issues** → tell the user OK; if domain nodes exist, suggest `/generate-srs`; if only section shells, explain they need `/analyze` first.
- **Exit 0 with `[CONFORMANCE]` lines** → **do not stop.** Report the count and the lines, say the graph is usable, and continue. Raise a fix only if the issues touch the part of the graph the user is about to generate from.
- **Failure / non-zero** → **stop**. Use [cli-failures.md](../../ai-spector/references/cli-failures.md): paste every `[ERROR]` line, explain each, give fix steps (usually re-run `/analyze` or fix one node then re-validate).

**Do not:** guess validation in the agent, hand-fix the whole graph without showing the user, or proceed to `/generate-srs`.

## If blocked

Follow [cli-failures.md](../../ai-spector/references/cli-failures.md). Typical fixes:

- `DOMAIN-ANCHORED` → domain node missing `listedIn` / `describedIn` → re-run `/analyze` or fix one node and `graph merge` again.
- `SECTION-TREE` → structure edge wrong → re-run `npx ai-spector index` (agent), not manual graph surgery at scale.
- `REGISTRY-COMPLETE` → re-run `/analyze` step 0 (`npx ai-spector index`).

After fix, user re-runs **`/validate-graph`**.
