# Native lifecycle and evidence

`chough change status <id>` (SpecSync's own status, passed through unchanged),
`specsync change ship-status <id>` and installed command help are authoritative for
the current state and recovery path. This reference follows SpecSync 6.3; do not
hardcode it over another version's output.
Match the SpecSync version used by lifecycle writers and CI.

You run the native commands in this reference as part of Chough's current-agent
workflow. The human gives the goal and authorization and reviews the resulting PR;
they do not need to dispatch SpecSync or Fledge operations themselves. Report the
result and genuine decisions still needed, then perform authorized recovery steps.

## Shape of a change

```text
new → interview → artifacts and delta → one human scope approval → implement →
check (when requirements change) → cases run → review gate → commit →
check --commit → present → human implementation review → chough change ship
(review as the human, ship, close gate, done) → commit the story → doctor --fix →
commit → push, then CI on the archived tip → merge
```

SpecSync's verification digest covers every file it does not ignore. Chough writes its
records in three folders, `.chough/sessions/`, `.chough/archive/` and `.chough/bugs/`,
and keeps everything a change's verification needs (`.chough/cases/`,
`.chough/preferences.json`, `.chough/README.md`, `knowledge/`) outside them. With the
three folders listed in `verification_ignored_paths` in `.specsync/sdd.json`
(SpecSync 6.1.2 and later), Chough's records may be written and committed at any
point. Without them, commit Chough's records before `check --commit` and write
nothing under `.chough/` until finalize, or another `change check` is needed.
`chough next` says which order applies (its "Chough writes" line, `chough_writes` in
JSON), and `chough doctor` reports `records_in_verification` while an entry is
missing. Chough never edits SpecSync's policy: adding the entries is an ordinary
reviewed change to `.specsync/sdd.json`. See [accept.md](accept.md) for the full
order.

| Native state | Chough stage | Gate |
|---|---|---|
| draft | intent, design, plan | build, test, accept and done refused |
| approved, implementing, verifying, with `approval_valid` true | build, test, accept | build, test and accept allowed; done refused |
| archived, with authenticated `terminal_evidence` | test, accept, done | done allowed; build refused (new work needs a new change) |

Chough reads `summary.state`, `summary.approval_valid`, `summary.correction_valid` and,
for archived changes, `summary.terminal_evidence.validity`. The same prerequisite
applies whichever command moves the stage (advance, skip, back, reset, return or
release → done). It refuses when status is missing, cannot be decoded or reports an
invalid approval or a correction reported invalid (`correction_valid` false), when no
native change is recorded in the checkpoint (`refused:no-native-change`; record one
with `chough checkpoint --native-change <id>`), and when `.specsync/sdd.json` is not a
valid SpecSync policy. Two cases are not gated at all: with no SpecSync configuration
the gate reads `ungated:not-configured`, and with no `.specsync/sdd.json` or one with
`"enabled": false` it reads `ungated:sdd-disabled`. A stage move never runs `approve`,
`review` or `finalize`. Those native writers run in one of two ways, and the records
say which: a human's decision at a gate that drives one, recorded through Chough,
runs it as that human; otherwise the current agent runs it on applicable human
authority given in advance.

## Approval

**At the gate.** The scope gate (`chough checkpoint --awaiting-human "Scope approval
of <id>"`, which holds plan and drives approval by default) closes with the human's
decision through `chough checkpoint --close-gate … --decided-by "<who>"`. Chough runs
`specsync change approve` as the configured human, with their words, where they said
them and the recording agent in the note. See [plan.md](plan.md) and
[checkpoint.md](checkpoint.md).

**On authority given in advance.** When the human does not answer that gate, identify
the actual human authority that covers this concrete definition before recording
`specsync change approve <id> --actor "<agent>-<terminal>"`. It may be an explicit
prior decision or a standing instruction authorizing a bounded class of changes,
such as repository ticket implementations delivered through PRs. Record the source,
covered scope and limits in the checkpoint decisions and native context, and quote
that source in the native approval note with where it was given. Record the acting
agent account, `<agent>-<terminal>`, as the native actor, separately from the human
authorization source, then continue without asking the human to repeat permission
for this internal operation. Do not use the human's name merely because they
authorized the agent's work. If SpecSync or the project's configuration refuses that
actor, stop and report the refusal; never retry it as the human. A native step
already archived is never edited to change its actor.

If the proposed work exceeds that authority, ask the consequential scope question.
An ordinary keep-working instruction without applicable authority, an agent label,
a bot review or a passing check does not create human approval. A changed approved
definition follows native reapproval rules; existing standing authority applies
only while it still covers the new scope. Actor text is a portable claim, not
identity. Scope authorization leaves implementation acceptance and delivery
boundaries separate.

## Verification

`chough change check <id> --no-commit`, SpecSync's check without `--commit`,
materializes the approved delta. Cases may link the requirements it adds or
modifies before then while the checkpoint records the approved change (see
testing.md). `chough change check <id>`
(SpecSync's `change check <id> --commit`) also records targeted structural verification; run it after committing the
source. Stage new source files first. It does not run the project's
tests; product checks are separate observations. It refuses an edited delta and
incomplete tasks. Fix real failures; if evidence is stale, follow the exact recovery
action status names.

## Review, archive, merge

The hosted Archive gate refuses while any native change is open, so the closeout is
archive-first: finish it locally before you wait on CI. After the applicable local
gates, present the work; after the human reviews the change package, diff, delta and
evidence, record their acceptance at the review gate, which holds accept and drives
review by default:

```sh
chough change ship <id> --close-gate "Implementation review of <id>" \
  --decided-by "<who>" --words "<their words>" --where "<where>" \
  --recorded-by "<agent>-<terminal>"
```

`chough change ship` first records the review as that human with verdict pass, from
the configured identity, then runs SpecSync's `change ship <id>`, which finalizes,
then closes the gate with the relay and moves the session to done. A human's block,
or a request for changes, closes the gate with `chough checkpoint --close-gate …
--verdict block` or `--no-native` instead, and the work goes back to build.

Only when an applicable standing authority covers acceptance itself, and the human
does not answer the gate, does the agent record the review in its own name, quoting
that authority, before shipping:

```sh
specsync change review <id> --reviewer "<agent>-<terminal>" --verdict pass
```

Show the human the gates being decided with `chough gate list`. Each has a one-screen
summary and its digest, and one reply covers only listed gates (`chough gate record`).

Direct `specsync` lifecycle calls still work. The next stage move or gate close
records them as `direct-native-write` Timeline entries, before its own entry, so the
need can be seen (DRIVE-21).

The native review is a recorded claim bound to the reviewed content, not proof of who
reviewed; the relay is a claim too. The reviewer may be the scope approver. Do not
commit between review and ship or finalize. The move into done archives the session
into one story, `.chough/archive/sessions/<id>.md`, writes a journal post and
refreshes `knowledge/index.md` and its feed. Commit those, then run
`chough doctor --fix`, which removes the now-committed session folder, and commit
that. Archive on the same pull request, then push and observe required CI at the
actual tip, and merge only when every change on that pull request is archived. A push
before the review only shows the work early: expect the Archive gate red and do not
wait on it. Review and finalize several changes one at a time.

Merge, package publication, release, deployment and live health are separate
observations; see [release.md](release.md).

## Evidence records

`chough cases run` and `chough evidence add` record with an observation the Git
revision, a working content identity, the environment, artifacts and, for cases, the
definition digest. In 0.6.0 each observation is an evidence entry in the session's
`evidence/` folder, carrying the exact command and a SHA-256 fingerprint; raw logs
stay in `.chough/local/logs/` and in CI, never in a commit. At finish each entry
becomes a receipt in the archived story, which freshness reads the same way.
Freshness compares the content identity, not the revision: it
covers every tracked or untracked non-ignored file except `.chough/`, `target/`, the
generated knowledge directory (`knowledge/` by default) and SpecSync lifecycle
bookkeeping (a change's `state.json`, `approvals.json`,
`verification.json`, `verification-attempts.json`, `review.json`,
`review-attempts.json`, `finalization.json`, `accepted-state.json`,
`lesson-bundle.md` and the front-matter `state:` value of `change.md`). So committing
only Chough records, an empty commit, `change check --commit` and finalize keep an
observation current, while a change to source, specs, configuration or a change's
deltas and other artifacts makes it stale. A record without a content identity, from
an earlier Chough or migrated from one, keeps the revision-bound comparison and is
stale after any commit.
The records do not authenticate a witness or verify a remote artifact. A changed
input, artifact, case definition or environment makes the observation stale.

## Moves that already happened

When a stage moved outside Chough (for example in a subagent), record it with
`chough stage backfill --at <original time> --commit <rev> --quote "<the words it rests
on>"` rather than advancing now with "recorded after the fact" in a note. Native state
is still read now and every advance refusal applies. The quote is evidence only: it
never records a human approval or review, so record human gates and native approvals
the usual way when they happen.
