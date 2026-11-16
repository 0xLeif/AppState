---
name: chough-workflow
description: Carry a request or bug from human intent through design, one scope approval, focused testing, local bugs, human acceptance and optional release, with a checkpoint any agent can resume from. Use for Chough-guided development, not unrelated single-file edits.
---

# Chough workflow

You are the agent doing the work. Chough keeps what was wanted, what was checked and
what comes next in project files, so you or another agent can continue later.
Native tools keep their records: HI owns human wording and criterion IDs, SpecSync
owns contracts, changes, approval, verification, review and archive, Fledge runs
tasks, and the actual environment produces evidence. Never copy their state into a
second ledger, and never record a human decision that a human did not make.

## Drive the workflow

Run HI, SpecSync and Fledge yourself. Native commands in references are agent
instructions; give the human outcomes and PRs.

Use explicit prior or standing human authorization for a concrete scope. Record the
agent actor, human source, scope and limits before native approval; do not ask again
just to run a tool. Ask when authority is missing or exceeded. Continuation, bot
reviews and actor labels are not human decisions; approvals are claims. A human's
gate decision runs the native step as them; on standing authority, record it as
`<agent>-<terminal>` ([plan](references/plan.md)).

Keep native checks and separate implementation acceptance and delivery authority.
See [lifecycle](references/lifecycle.md) for scope, provenance and ordering.

## Start or resume

1. Read applicable `AGENTS.md` files. Prefer Fledge for tasks it supports.
2. Find the checkpoint: run `chough next --environment <env>`. Without the helper,
   read the active session's `session.md` (see
   [checkpoint.md](references/checkpoint.md)), `.chough/README.md`, open bugs in
   `.chough/bugs/` and `chough change status <native_change>`.
3. Check what is still true: native state, evidence freshness, open blocking bugs,
   and open gates. A saved stage or next action is a suggestion; native status
   decides gates.
4. Before your first edit, state the handoff in your own message. Reading it in tool
   output is not the same as stating it. Say the goal; each recorded decision that
   binds the next task, with its reason, naming a rejected approach as rejected; the
   last failure, its bug and that bug's status; the lessons that apply and where they
   are recorded; and the next task. An edit is any file change, including a Chough
   command that writes a record. Where the records do not say one of these, say so
   instead of guessing.
5. Read [the stage contract](references/stages.md) and its fast path, then only
   the current stage's reference.

With no checkpoint, run
`chough init --objective "<outcome>" --intent-scope <HI-family> --module <module>`; it
never overwrites existing files and creates the first session; otherwise run
`chough session new <change-id>`. Repeat `--host` per host. A
0.5.x project needs `chough migrate` ([checkpoint.md](references/checkpoint.md)).

## Stages

| Stage | Reference | Human decision at the end |
|---|---|---|
| intent | [intent.md](references/intent.md), [roles.md](references/roles.md) | Approve the intent as a whole |
| design (only when visuals or interactions change) | [design.md](references/design.md) | Approve rendered prototype and companion together |
| plan | [plan.md](references/plan.md) | Apply existing human authorization, otherwise one scope decision |
| build | [build.md](references/build.md) | None for routine work inside scope |
| test | [testing.md](references/testing.md) | None; failures go to bugs |
| accept | [accept.md](references/accept.md), [lifecycle.md](references/lifecycle.md) | Native implementation review |
| release (optional) | [release.md](references/release.md) | Only on request or standing setting |
| bugs, validate, librarian (side stages) | [bugs.md](references/bugs.md), [validate.md](references/validate.md), [librarian.md](references/librarian.md) | Publication or optional runs need a human |

Checkpointing is mandatory in every stage: see [checkpoint.md](references/checkpoint.md).

## Working rules

- Talk naturally. Map requests such as "go back to design", "pause" or "skip design,
  it is a CLI change" to `chough stage …` commands, and say what you recorded.
- Resolve routine engineering and tool choices within applicable authorization.
  Ask the human when a consequential product choice, authority or optional execution
  policy remains unresolved. Synthesize findings first; do not return internal tool
  operations as new approval questions.
- Keep doing independent authorized work while a human gate is pending, and record
  the gate with `chough checkpoint --awaiting-human "<decision>"`.
- Never put a local path, user or host name, email or credential in a record
  (`refused:leak`; `--redact` replaces it).
- Evidence states what ran, where and on which inputs. A structural pass, exit code,
  actor label or agent review is not behavioral proof, human approval or deployment.
- Nothing is published, released or deployed as a side effect of finishing work.
- Chough's size bounds cover only its `.chough/` records and displays. Never edit HI
  intent or criteria, specs or SpecSync files to fit one; report a Chough bug.

## Host use

Chough runs in the current agent, with no provider API or runtime.
`chough init --host <openai|claude|codex|cursor|gemini|grok>` copies this bundle into
that host's project skill directory: openai, the default, and claude share
`.agents/skills`; gemini writes `.gemini/skills` (unexercised); Kimi Code CLI uses
`--host openai`. `chough skill status` shows whether a copy is current, edited or
outdated; an old `.claude/skills` copy is legacy, removed only by
`chough skill remove-legacy --host claude`. Discovery is host behavior: Claude Code
reaches this skill through `CLAUDE.md` and `AGENTS.md`. Confirm the host lists the
skill; otherwise give it this file. Subagents are optional:
[roles.md](references/roles.md) also works as sequential passes.
