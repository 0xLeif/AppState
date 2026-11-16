# Reproduce, classify, deduplicate and record a bug

Use this procedure for a suspected defect, including a failing case. Bugs live
locally first in `.chough/bugs/`, one Markdown file each, named by date and the
title's slug (`<date>-<slug>.md`). The front matter carries the IDs and links; the
body says what happened, the steps, what was expected, why it matters and the fix,
then an append-only `## Log` with one dated line per report, note, evidence link and
status change. Chough keeps every paragraph a person wrote and only appends to the
Log. Older IDs (`BUG-NNNN`, `BUG-<slug>-<hex>`) stay as aliases, so every command and
link still finds the bug by them. A request to investigate does not authorize
posting an issue, comment or message; publication needs an explicit request or an
authorization the human already established.

## Establish the failure

Find the applicable HI criterion, requirement and case. If the intended behavior is
unclear, keep the observation and ask the smallest question that separates a defect
from a new request. Do not rewrite intent to match the implementation.

Reduce the reproduction to the smallest safe fixture and steps. Run it and record the
result as an observation: `chough cases run <case> --environment <env>` for a bound
case, or `chough evidence add … --outcome failed --failing-lines "<key lines>"` taken
from the saved output, which stays uncommitted. A bug without a linked failed
observation is reported as `unverified`. Avoid real credentials, private data or
destructive production actions when a local fixture suffices.

## Classify from evidence

| Class | Evidence needed |
|---|---|
| product-defect | Observed behavior contradicts an applicable criterion or contract |
| regression | Fails now, and a passed observation at an earlier ancestor revision exists (`--regression-baseline <observation>`) |
| environment | The failure is isolated to an identified environment or tool input |
| requirement-gap | Behavior is observed, but the intended outcome is unresolved |
| evidence-gap | Existing claims cannot be reproduced or their evidence is missing or stale |

A plausible cause is a hypothesis until a test supports it. A remembered "it used to
work" is not a regression baseline. State impact separately from priority.

## Search, then record

```sh
chough bug search "<symptom and trigger>" --requirement <REQ> --case <case>
chough bug add --title "…" --symptom "…" --trigger "…" --expected "…" --actual "…" \
  --environment <env> --requirement <REQ> --case <case> --observation <failed-obs> \
  --step "…" --scope blocking|in-scope|out-of-scope --classification product-defect
```

`bug add` refuses when a similar bug exists. Compare symptom, trigger and affected
behavior, not titles. For the same defect, append to the existing record with
`chough bug update <BUG> --observation <id> --note "<what this adds>"`; for a related
but distinct one, add with `--distinct "<why>"` and link it with `--related`.

Search wider sources only when they are in scope, for example `fledge github issues
--state all --limit 100 --json`. That list is bounded and can hide fetch errors; say
what you searched and its limits.

## Scope decides the next step

- `blocking`: the acceptance-relevant behavior is wrong. `chough stage advance` from
  test refuses while it is open; go back to build, fix, and rerun the focused cases.
- `in-scope`: fix within the approved scope when practical.
- `out-of-scope`: keep it visible in the backlog for later work. It does not expand
  the current change.

After a fix, link the passing observation and set `--status verified`, which needs a
linked failed observation and a linked passed observation observed after the latest
linked failure; an older pass, or one in the same second, leaves the bug `reproduced`.
A failing check that is fixed in the same pull request still gets a bug record with
its failed and passed observations, or a lesson entry in the module's lesson source; a
fix that leaves no record teaches the next agent nothing. Bugs found after closure
normally become new native changes; use native recovery only when the original
recorded evidence needs repair.

A bug in another tool's behaviour that its owner fixed closes as `fixed-upstream`:
`chough bug update <bug> --status fixed-upstream --note "<the upstream fix, and who
checked it where>"`. The note is required. It is a closed status, like `verified`,
`duplicate` and `wont-fix`, but it never reads as verified by Chough. After the
session that holds a bug's evidence is archived, the bug reads that evidence from the
story's receipts, so its state does not change.

## Report candidates

`chough bug report <BUG>` prints a Markdown candidate built from the record, marked as
not published. Review it, and post it only when the human asks. Then return the
resulting URL and add it to the record with a note. Record a lesson in the native
module source only when its source, scope and future use are clear.
