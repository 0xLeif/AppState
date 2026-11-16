# Stage contract

Every stage uses the same shape so any agent can tell where work stands. The helper
embeds only the stage names, order and gates; this file holds the meaning. Use the
fields as a checklist for your own reasoning, not as a form to fill in front of the
human.

Each stage below states: purpose; inputs; outputs and their owners; useful roles
and tools; completion evidence; approval and preference policy; consequential
questions; what to checkpoint; and transitions.

## Fast path for a routine change

A bug fix or small feature inside one module needs only this section, the stage
reference `chough next` names, and the code. Local and small-context agents start here.

1. Read: `AGENTS.md`, the issue, the one requirement you change in
   `specs/<module>/requirements.md`, and the files you edit. Not `docs/` or whole specs.
2. `chough session new <change-id>`, `chough checkpoint --criterion <id>` for the
   HI criterion it serves, then `chough next`. When that criterion already holds the
   intent, `chough stage advance` leaves intent; when nothing visual changes,
   `chough stage skip --reason "<why>"` skips design.
3. `chough change new "<outcome>" --kind <kind> --spec <module> --path <path>…`,
   declaring every path. Answer its questions with `specsync change answer`, and
   write `deltas/<module>.md` for each affected spec (`## MODIFIED` with each changed
   requirement's full new text), unless the change is `--no-spec-change`.
4. Fill the change's artifacts, run `chough change ready <id>`, then stop: scope approval belongs to the human unless
   standing authorization covers it ([plan.md](plan.md)).
5. Make the first code edit soon. Search for the names you need; don't survey.
6. Add a test that fails without the fix and a case in its own
   `.chough/cases/<module>.<topic>.cases.toml`; update the changelog and docs.
7. `fledge run fmt`, `fledge run test`, `fledge run lint`, then `chough change check
   <id>`, commit, and stop for the human's review.

Work only in your own checkout and branch; other branches are not inputs.

## Transitions shared by every stage

| Intent | Command | Notes |
|---|---|---|
| Next stage | `chough stage advance` | Every move meets its destination's native prerequisite (build, test, accept, done) |
| Several stages at once | `chough stage advance --to <stage>` | Every step is checked first, on one native read; a refused step records nothing, and into done it reads native status once |
| Not applicable | `chough stage skip --reason "<why>"` | `skip` skips the current stage, not the next one, and records `skip · <current> → <next>`; the reason is required and kept |
| Another pass | `chough stage iterate --note "<what changed>"` | |
| Go back | `chough stage back --to <stage> --reason "<why>"` | Lists what to refresh; history is kept |
| Start over | `chough stage reset [--to <stage>] --reason "<why>"` | History is kept; intent, design and plan are always reachable |
| Pause, resume | `chough stage pause --reason "<why>"`, `chough stage resume` | Resume only marks the stage active and checks nothing itself; then run `chough next --environment <env>` to re-check native state and freshness |
| Side stage | `chough stage enter <side> --reason "<why>"`, then `chough stage return` | Sides: bugs, validate, librarian; the caller is restored |

Going back to intent or plan after native approval means native reapproval if
intent, contract, acceptance criteria or scope change. Follow `specsync change
status`; Chough never changes native state. Dependent design approval, test
observations and evidence named in the refresh list must be redone by their owners.

## intent

- Purpose: capture what the human wants and derive an appropriately sized FRD.
- Inputs: conversation, `INTENT.md`, `hi export <scope>`, existing FRD and module requirements.
- Outputs: HI criteria (HI), FRD sections (`docs/FRD.md`), review findings (working notes).
- Roles and tools: product and user advocate, QA, design, accessibility, engineering, architecture; `hi`.
- Completion evidence: criteria captured with `hi`, FRD traced to them, findings synthesized.
- Approval: the human approves the intent stage as a whole; no per-criterion ceremony.
- Questions: only those that change the product or a consequential assumption.
- Checkpoint: criteria and requirement references, decisions, open questions.
- Transitions: advance to design; back is not available; reset restarts here.

## design

- Purpose: define visuals and interactions in one canonical local HTML and CSS prototype.
- Applicability: when the change has no relevant visuals or interactions, skip design at
  design. Once the intent is approved, advance from intent into design with
  `chough stage advance`, then run `chough stage skip --reason "<why>"` at design, which
  records `skip · design → plan`. A skip at intent records `skip · intent → design` and
  skips intent.
- Inputs: approved intent, FRD, project conventions and design tokens.
- Outputs: canonical prototype and `COMPANION.md` (design owner), rendered review notes.
- Roles and tools: design, accessibility, user advocate; a browser-capable agent for rendered review.
- Completion evidence: rendered review of states and viewports, companion mappings to HI and FRD.
- Approval: the human approves the rendered prototype and companion together.
- Questions: design choices that change scope go back to intent.
- Checkpoint: prototype and companion paths in `design`, the pending design approval as a gate in `waiting_on_human`.
- Transitions: advance to plan; back to intent.

## plan

- Purpose: technical design, task plan, estimates and ownership in the native change.
- Inputs: intent, design, contracts, architecture, native lessons and principles.
- Outputs: native change package and deltas (SpecSync), estimates and ownership (plan artifact).
- Roles and tools: engineering, architecture, QA; `chough change new/answer`.
- Completion evidence: native artifacts complete and status ready for approval.
- Approval: one human scope approval over the concrete definition, recorded natively: the human's decision at the scope gate runs it as that human, or the agent records it on authority given in advance (see plan.md).
- Questions: consequential open choices, batched into the one approval question.
- Checkpoint: `native_change`, the scope gate in `waiting_on_human` (holds plan, drives approval).
- Transitions: advance to build only after native approval; back to intent or design.

## build

- Purpose: implement the approved tasks, keeping contracts, tests and docs in sync.
- Inputs: approved native definition, owned files, case definitions.
- Outputs: code, tests, case definitions, documentation (project owners).
- Roles and tools: engineering; Fledge tasks and lanes; subagents with explicit file ownership.
- Completion evidence: focused checks pass locally, tasks updated, checkpoint saved.
- Approval: none for routine work inside scope; scope changes go back to plan.
- Questions: genuine blockers and scope-changing decisions only.
- Checkpoint: completed work, files, blockers, next action after each increment.
- Transitions: advance to test; back to plan, design or intent.

## test

- Purpose: focused verification of the affected criteria and behavior.
- Inputs: selected cases (`chough cases select`), project-required lane.
- Outputs: evidence entries in the session's `evidence/` folder (raw logs stay local and in CI), bugs for failures.
- Roles and tools: QA; `chough cases run/record`; browser for design QA.
- Completion evidence: selected cases observed; failures captured; omissions explained.
- Approval: none; blocking bugs send work back to build.
- Questions: whether a gap is a product decision rather than a defect.
- Checkpoint: case and observation references, open bugs, test debt.
- Transitions: advance to accept (refused while blocking bugs are open); back to build.

## accept

- Purpose: present the implementation and evidence for the human's review, then close natively.
- Inputs: verification, product evidence, remaining bugs and limits.
- Outputs: native review and archive (SpecSync), lessons (native module sources).
- Roles and tools: the human reviewer; `chough change check`, then `chough change ship`, which records the human's review through their gate decision.
- Completion evidence: native state `archived`.
- Approval: the human implementation review, recorded natively as that human only after it happens.
- Questions: the review itself.
- Checkpoint: the review gate in `waiting_on_human` (holds accept, drives review), PR and CI references.
- Transitions: advance to done only once archived; back to build or test.

## done

- Purpose: the change is archived. Merge follows the repository's process.
- Outputs: the move into done archives the session into one story in `.chough/archive/sessions/`, a journal post and a refreshed knowledge index. Commit them, then run `chough doctor --fix` and commit that.
- Transitions: release only with authorization, asked before done so the session stays open; start new work with `chough session new <key>`.

## release

- Purpose: optional publication, installation or deployment with real project commands.
- Entry: a human request recorded as run consent, or a standing project setting.
- Outputs: distinct publication, installation, deployment and live-health observations.
- Checkpoint: a decision still to come, such as a publish approval, is a gate that holds release, so earlier stages keep moving.
- Transitions: advance to done, which archives the session.

## bugs

- Side stage for reproducing, classifying, deduplicating and recording a defect locally.
- Returns to its caller; blocking bugs send the main flow back to build.

## validate

- Side stage for optional repeated validation or monitoring.
- Entry needs a run consent or standing preference; findings are kept locally.

## librarian

- Side stage for keeping the knowledge vault current: its generated index and feed, journal posts and cross-project lessons.
- Returns to its caller; the vault links records and never copies them, so it never becomes a second current source.
