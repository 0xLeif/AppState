# Technical design and plan

SpecSync drives this stage with its own adaptive artifacts. Read source
instructions, existing architecture and the native lessons first; `specsync change
new` prints the lessons of the modules you declare.

0. In a project whose `specsync init` left SpecSync's change workflow off, run
   `specsync change adopt` first; until then no native gate checks the stages.
1. Create the change with installed help as the authority, for example
   `chough change new "<one outcome>" --spec <module> --path <path>`.
   Declare every path you expect to touch: scope freezes at approval.
2. Answer the deterministic interview with `chough change answer <id> <question>
   "<answer>"`.
3. Complete the selected artifacts: requirements, research, design, plan (approach,
   out of scope, steps, risks, constraints consulted), tasks, testing, docs, and a
   semantic delta per affected module: `.specsync/changes/<id>/deltas/<module>.md`,
   with each requirement it adds under `## ADDED` and each one it changes, with its
   whole new text, under `## MODIFIED`, each as `### REQUIREMENT <id>`, the text and
   its `Acceptance Criteria` list (docs/cli.md, "A new project and its first change").
   The deltas name exactly the specs the change affects; check they exist before the
   scope approval, since SpecSync can call a draft ready without one.
   Run `chough change ready <id>` before the scope approval. It lists everything
   still missing and names the command that fixes each piece.
4. Estimate meaningful increments with relative size and the main uncertainty. Do not
   invent precise hours. Run `chough timing` and use its history ranges (per stage, bug
   fix and human gate) as the basis: they are elapsed wall-clock time, not effort, and
   estimates from recorded history, not targets. When it reports too few samples, say
   that history is too thin and estimate by relative size alone; never present a range
   as a deadline.
5. If several agents will build, assign file or module ownership in the plan.
6. Record the change: `chough checkpoint --native-change <id>`.

## One approval

Prepare one coherent concrete package: outcome, contract delta, plan, verification
and consequential choices. Apply the main skill's authorization rule before asking
for a decision. Exactly one of two cases applies, and the records say which.

**Authority given in advance.** If an actual prior or standing human instruction
covers this scope, that authorization already exists: record its source, scope and
limits in the checkpoint and native context, then run the native operation yourself,
as the acting agent account `<agent>-<terminal>` (for example `claude-code-t382`):

```sh
specsync change approve <id> --actor "<agent>-<terminal>" --note "Approved under <the human's words> (<where they said them>); covered scope: <scope>; limits: <limits>. Recorded by <agent> (<model>, hc <terminal>)."
```

The acting agent account is the actor; the human instruction supplies the authority.
Do not use the human's name merely because they authorized the agent's work, and do
not ask the operator to execute this command or repeat covered permission. If
SpecSync or the project's configuration refuses that actor, stop and report the
refusal; never record the approval in the human's name instead.

**A decision at the gate.** When a consequential decision or authority is actually
missing, ask one concise question and record that real gate. At plan it holds plan
and drives the native approval by default:

```sh
chough checkpoint --awaiting-human "Scope approval of <id>"
```

Keep doing independent preparation while it is pending. When the human answers,
record their decision; Chough runs `specsync change approve` as that human, from the
configured identity (see [checkpoint.md](checkpoint.md)), and only then closes the
gate:

```sh
chough checkpoint --close-gate "Scope approval of <id>" --decided-by "<who>" \
  --words "<their exact words>" --where "<where and when, and who relayed it>" \
  --recorded-by "<agent>-<terminal>"
```

A decision that is not an approval, such as "change this first", closes the gate with
`--no-native` and approves nothing. Chough never decides which case applies from the
words. An actor label alone never supplies human authority, and neither Chough nor
SpecSync authenticates who decided.

Lessons learned from rehearsing SpecSync 6.1: the delta is frozen once approved and
`change check` refuses an edited delta; `change check` also refuses while `tasks.md`
has unchecked boxes, so list human gates, and running or recording Chough cases, as
plain text rather than checkboxes. A requirement the delta adds reaches the
companion only when `change check` materializes it; until then Chough cases may link
it only while the checkpoint records the approved change and its delta is
unchanged, and a box for those cases would still block that check.

## What needs reapproval

A change to approved intent, contract, acceptance criteria or affected scope needs
native reapproval. Routine implementation, tests, evidence, delta materialization
and lifecycle metadata do not.
