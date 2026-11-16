# Acceptance and native closeout

Acceptance is where the human decides whether the implementation is what they
wanted. Agent review, a passing command, scope approval or an actor label never
stands in for that decision. A native review is a recorded claim bound to the
reviewed content, not proof of who reviewed.

## Prepare the review

Follow this order, so that one verification covers both the code and Chough's
records. Follow native status where it names a different next action.

1. When the delta adds or modifies requirements, run
   `chough change check <id> --no-commit` first, SpecSync's check without `--commit`,
   so the requirement text that cases link is materialized (cases already link it
   from the approved delta while the checkpoint records the change). It refuses while
   `tasks.md` has an unchecked box, so the cases in step 2 are never a box there. Run
   through Chough, it is never recorded as a direct lifecycle write.
2. Write any lesson from this change now, in its module's lesson source (see
   [Compounding](#compounding)): a change under `specs/` makes every run not current,
   so with the lesson written first, one run covers it. Then run the affected cases:
   `chough cases run <ID> --environment <env>`, plus the project lanes, and rerun any
   case whose latest run is not current, as after step 1; `chough next` names each
   rerun before the review gate.
3. Record the gate: `chough checkpoint --awaiting-human "Implementation review of <id>"`.
   At accept it holds accept and drives the native review by default.
4. Commit the source together with Chough's records.
5. Run `chough change check <id>`, which runs SpecSync's `change check <id>` with
   `--commit` (stage new source files first).
6. Present to the human: what changed, the current verification, the relevant case
   observations with freshness, open bugs and limits, and what was not checked.
   Report product tests, structural checks, native lifecycle state, provenance and
   platforms separately.
7. Do not wait on CI yet. The hosted Archive gate refuses while the change is open, so
   CI is observed after finalize, below. Pushing the branch now only shows the work
   early: expect the Archive gate red and do not wait on it.

Between the check in step 5 and finalize, nothing else is committed. Committing Chough
records or SpecSync bookkeeping does not make Chough observations stale, but
SpecSync's verification digest covers every file it does not ignore. With
`.chough/sessions/`, `.chough/archive/` and `.chough/bugs/` listed in
`verification_ignored_paths` in `.specsync/sdd.json` (SpecSync 6.1.2 and later),
Chough's records may be written in that window, and the case definitions in
`.chough/cases/` stay verified because they sit outside those folders. Without the
entries, write nothing under `.chough/` until finalize, or another `change check` is
needed. `chough next` says which applies, and `chough doctor` reports
`records_in_verification` while an entry is missing (see
[lifecycle.md](lifecycle.md)).

If native archive checks are red because review has not happened, say exactly that.
Do not claim all checks are green and do not bypass the gate.

## After the human decides

Only after a real implementation acceptance decision, the current agent records
it and closes natively, following native status rather than a remembered sequence.
The user reviews the implementation or PR; the agent handles these internal commands
and never asks the human to run one. The human's decision at the review gate records
the native review as that human:

```sh
chough change ship <id> --close-gate "Implementation review of <id>" \
  --decided-by "<who>" --words "<their exact words>" \
  --where "<where and when, and who relayed it>" --recorded-by "<agent>-<terminal>"
```

Chough runs `specsync change review` as the human configured in
`.chough/local/identity.toml` or the user `chough/identity.toml`, with verdict pass,
then ships. `refused:human-identity-unknown` means the human is not configured: add
them there, and never record the review as an agent instead. A block or a request for
changes is not a ship: close the gate with `chough checkpoint --close-gate …
--verdict block`, or `--no-native` for a request that is not a review, and go back to
build.

Only when an applicable standing authority covers acceptance itself, and the human
does not answer the gate, does the agent record the review in its own name,
`<agent>-<terminal>`, quoting that authority and where it was given, and then ship.
If SpecSync refuses that actor, stop and report it; never retry as the human:

```sh
specsync change review <id> --reviewer "<agent>-<terminal>" --verdict pass
```

To present several gates at once, run `chough gate list`. It numbers them, each with
a one-screen summary and its digest. Record the human's one reply with `chough gate
record <list> --gates <n>,… --decided-by … --words … --where … --recorded-by …`. For the
review gate of a change that is verifying, pass `--list <list> --gate <n>` to
`chough change ship` instead of `--close-gate`.

Do not commit between review and ship. `chough change ship` checks the session, the
stage, the open gates and the relay before anything runs, then runs SpecSync's
`change ship <id>` (which finalizes). After that it closes the gate with the
actual acceptance source and moves accept to done. The gate keeps who decided, their
words, where and the recording agent as a relayed claim, not authenticated. If a step
after the ship is refused, the output says the change is shipped and names the
command left to run.

Before the move into done, give the journal post a short human title and a real
summary: `chough checkpoint --title "<title>" --summary "<what changed and why; what
was verified, with its final numbers; what is next>"`, one paragraph per line, at
most 72 and 900 bytes. Without them, Chough derives both from the objective and the
story.

The move into done archives the session into one story,
`.chough/archive/sessions/<id>.md`, with every evidence entry as a receipt. With the
librarian on, it also writes a journal post and refreshes `knowledge/index.md` and its
feed. The finish then takes two commits:

1. Commit the story, the journal post and the knowledge directory with the archive.
2. Run `chough doctor --fix`, which removes the session folder now that its bytes are
   committed, and commit that removal.

Then push both commits on the same pull request, observe hosted CI at the real tip,
and merge through the repository's normal process. If several changes share a pull
request, review and finalize them one at a time. If evidence went stale, use the
recovery action that `chough change status` names. Finishing never enters release;
ask for release before done, so the session stays open for it.

## Compounding

Lessons can be recorded at any stage. Put them in the module's native lesson source
(`<module>.3md` later plane when present, otherwise the Lessons section of
`context.md`) with the source, the scope where it applies and the future action it
changes. `chough next` points to that source; Chough keeps no lesson store of its own.

Each lesson carries a certainty label:

- `observation`: something seen once, with what was run and where.
- `hypothesis`: a likely explanation not yet tested. It is a prompt to check, not a
  rule.
- `verified`: supported by a test or a repeated observation.

Each lesson names its source (an observation ID, a bug ID or a commit) and its limits
(where it applies and where it was not checked).

In `context.md`, start each lesson with its date, `YYYY-MM-DD`, then a space, comma or
colon, as an item of the `## Lessons` section or as a `### YYYY-MM-DD` heading: the
knowledge index counts only dated lessons, and an undated one counts as none. In
`<module>.3md`, each plane after the first is one lesson. For example:

```markdown
## Lessons

- 2026-11-12, verified: an order of exactly fifty dollars ships free, so the
  threshold check is inclusive. Source: bug 2026-11-12-shipping-charged-at-fifty.
  Limits: checkout totals only; refunds were not checked.
```

A project decision, meaning a
checkpoint decision, a `docs/DECISIONS.md` entry or an approved contract, always
outranks a lesson. A lesson never changes a decision; if a lesson argues against one,
raise it with the human. A lesson that changes behavior or policy may need its own
native change. Write lessons from a change before its cases run at accept (step 2 of
[Prepare the review](#prepare-the-review)), inside the open native change (see
[librarian.md](librarian.md)), since a change under `specs/` makes every run not
current. Archival does not mean no bug remains;
open bugs stay in the backlog.
