# Checkpoint and cold resume

Essential state must never live only in model context. The checkpoint is the single
writable record of where work stands: the front matter of the active session's
`.chough/sessions/<id>/session.md` (see [Sessions](#sessions)). It works without the
librarian and without any other storage adapter.

## What it holds

| Field | Content |
|---|---|
| `objective`, `stage`, `stage_status`, `iteration`, `callers` | Current outcome, stage, status, side-stage callers and iteration |
| `native_change` | The SpecSync change ID; native status decides its state |
| `criteria`, `requirements`, `cases`, `design`, `files` | What is in scope |
| `observations`, `bugs`, `blockers` | The records that show the work, and what blocks it |
| `waiting_on_human` | Real gates still waiting for a person, each with the stage it holds (`holds`), the native step it drives (`drives`) and when it opened |
| `run_consents` | Consent for this objective only |
| `next` | Suggested next step; never overrides native state |

These are the front matter of `.chough/sessions/<id>/session.md`. Decisions with
their reasons, completed work and open questions live in its Decisions and why, Where
it stands and Open threads sections, and transitions in its Timeline. Standing
preferences are in `.chough/preferences.json`. `.chough/local/active-session` names the
active session; `.chough/local/` stays in each worktree and is never committed.
Evidence entries live in the session's `evidence/` folder and fold into its archived
story at finish; bugs are in `.chough/bugs/` and case definitions in `.chough/cases/`.
`.chough/README.md` names every folder and its rule.

## When to save

Save after each meaningful increment, before handing off, before context is cleared,
and whenever a human gate opens or closes:

```sh
chough checkpoint --completed "<what was done>" --observation <id> \
  --decision "<decision, because reason>" --next-action "<next step>"
```

Opening a gate with `--awaiting-human "<gate>"` appends one `gate-opened` entry to the
session's Timeline, only when that gate is not already open. `--close-gate` and
`--clear-awaiting-human` append one `gate-closed` entry per gate they close. They
record when a gate waited, and `chough timing` reads them to show waiting-on-human
time. Open and close gates through these flags rather than by editing the session
file, or the waiting time is lost.

Each gate holds one stage and drives one native step. `--holds <stage>` names the
stage it holds, the current stage by default; only a move out of that stage waits for
it, so a release decision opened at build never stops build, test or accept.
`--drives approve|review|none` names the native step a human's decision runs:
`approve` by default for a gate held at plan, `review` for one held at accept, and
`none` otherwise.

When the human decides a gate, record their decision on their behalf:

```sh
chough checkpoint --close-gate "<gate>" --decided-by "<who>" \
  --words "<their exact words>" --where "<where and when, and who relayed it>" \
  --recorded-by "<agent>-<terminal>"
```

It closes only that gate, puts the four values on its `gate-closed` entry and adds one
decision. For a gate that drives a native step, Chough first runs it as that human:
`specsync change approve` for a scope gate, or `specsync change review` with the
`--verdict pass|block` you give for a review gate (never read from the words). It
reads the human from `.chough/local/identity.toml`, or else `chough/identity.toml` in
the user configuration directory: each `[[human]]` has a `name`, optional `aliases`
and the `specsync_actor` SpecSync records. A decision that is neither an approval nor
a review, such as "change this first", closes with `--no-native` and runs nothing.
Every close names a configured human, whatever the gate drives and with or without
`--no-native`: `refused:human-identity-unknown` means `--decided-by` matches no
configured human, or two: add them to the identity file, never fall back to an agent
account. A SpecSync
refusal passes through and records nothing. The relay is a claim, not authenticated.
Each refusal saves nothing and names its recovery.

`--clear-awaiting-human` withdraws every open gate and records no decision: use it
for gates no human decision closes. To withdraw some gates and keep the others, pass
the gates still waiting with `--awaiting-human` in the same call; they are logged
closed and opened again, so their waiting time restarts there.

Write decisions with a prefix and a reason, so a fresh agent can tell what was chosen,
what was ruled out and what already failed:

```text
decided: <what> because <reason>
rejected: <approach> because <reason>
failed: <experiment> because <reason>
```

This is a convention, read best-effort: the prefix starts the entry, lowercase, with a
colon, and the reason is the text after the last ` because `. Any other entry, such as
older free text or a dated note, is still kept and shown whole. Decisions stay plain
strings in the checkpoint; nothing validates the convention. Record a human's decision
only in their words, and label an agent's own assumption as the agent's, without a
`decided:` prefix.

Write decision summaries and observations, not private reasoning transcripts.
SpecSync's `Handoff:` line says whether its own records are safe to clear; follow it
too.

## Resume cold

A fresh agent with none of the earlier conversation:

1. Reads `AGENTS.md`, then this skill.
2. Runs `chough next --environment <env>` (or reads the files above directly); it is
   the focused view, and `chough status` is the full one. Besides the stage, native
   state, next action and gates, it shows the 5 newest decisions with their kind and
   reason, the latest failed observation by recorded time with the status of each bug
   that links it, and where each module's lessons live (`<module>.3md`, or the
   `## Lessons` line of `context.md`) with the newest archived SpecSync lesson
   bundles. It points to lessons and never prints them; read the source it names.
3. Checks native status for `native_change`, freshness of the referenced evidence,
   open blocking bugs and the gates in `waiting_on_human`. A referenced entry is
   `current`, `historical` (present but stale), `removed` (dropped by the 0.6.0
   migration, naming its receipt), `ambiguous` (a merge left two records with that
   name, naming their places) or `unavailable` (missing); only a current one counts,
   so rerun the others rather than treat them as passed. `chough next` also
   shows the last acting agent and, with its count, each corrected decision.
4. Continues with `next_valid_action` under the same scope, preferences and gates. It
   never records a pending human decision itself. The move into done archives the
   session, so new work starts with `chough session new <key>`, then
   `chough change new "<outcome>" --spec <module> --path <path>` and
   `chough checkpoint --native-change <id> --next-action "<next step>"`. When the
   native change is already archived at an earlier stage, `chough next` names the
   archive instead of continuing, after `chough stage advance` to done at accept.

## Schema and concurrency

The checkpoint is the front matter of the active session's `session.md`; the story
sections and the Timeline are in the same file. Hand edits are allowed: Chough keeps
any key it does not know and every line a person wrote outside the sections it
appends to, and refuses front matter outside its strict YAML subset with the file,
line and rule. With several agents, one agent owns live checkpoint writes; others
report through the inbox.

A 0.5.x project (`.chough/session.json`, JSON sessions or bugs, `history/`,
`transitions.jsonl`) is refused as `refused:unmigrated`. `chough migrate` previews its
upgrade as text for the human (`--json` for JSON), writes nothing and prints a digest.
Then
`chough migrate --apply <digest> --consent "<who, their words, where>"` applies that
exact plan, only with the human's consent, never while a native change is open, and
only when Git holds every byte it removes. It writes a receipt in
`.chough/archive/migrations/`; old IDs stay as aliases.

There is no checkpoint merge. Each session is its own folder, so two branches that
work on different sessions merge with no conflict. Two branches that change the same
session conflict in Git like any file; resolve by keeping both Timelines' entries
and one coherent checkpoint, never by inventing a decision.

## Sessions

Each piece of work is a session folder, `.chough/sessions/<date>-<slug>/`, holding
`session.md`, `evidence/` and `agent/`. Start one with `chough session new <key>`; the
key is kept as an alias, and `chough session use <id, alias or slug>` switches. A
session only ever closes itself: at its own move into done it writes one story,
`.chough/archive/sessions/<id>.md`, removes each file of its folder whose bytes are
committed at HEAD, keeps and reports the rest, and clears the active pointer; then
start the next one with `chough session new`. It stays open while its inbox has
unfolded entries or release is authorized (ask for release before done). Starting or
switching work never archives, closes or changes another session, even a finished
one; `chough session list`, `chough next` and `chough doctor` name each finished open
session with its fix, `chough doctor --fix`. Close abandoned work with `chough session
close <key> --reason <text>`. The move into done takes two commits: first commit the
story with the journal post and the refreshed knowledge index, then run
`chough doctor --fix` to remove the now-committed session folder and commit that.
Chough removes a file only when its exact bytes are committed at HEAD, so nothing
uncommitted is ever lost; what it keeps it reports. When a fresh
worktree refuses to enter Chough, run `chough doctor` to see the debt and
`chough doctor --fix` to clear it; decisions also need `--reason`. Subagents do not
edit the session: they run `chough inbox add --session <key> --from <name> --kind
observation|decision|completed|question --text <text>`, and the agent that owns the
session runs `chough inbox fold`. Inbox entries never approve, review, consent, clear a
gate or move a stage.

## The Timeline

Every transition is one entry of the session's `## Timeline`, `- <time> · <kind> ·
<from> → <to> · <text> ^t-xxxxxx`, with its fields as indented lines, written in the
same save as the checkpoint change it goes with. Chough only appends entries and
never edits one; `chough history show` lists them. Recent guidance reads at most the
newest 128 entries. A timeline holds at most 4,096 entries of 64 KiB each; a refusal
at that bound leaves the session unchanged and names `chough session close` and
`chough session new`. An entry that is not a valid transition is refused, never
shown as history. Each entry's `by` line names the acting agent, model and hc
terminal when known (`CHOUGH_ACTOR`, `CHOUGH_ACTOR_MODEL` and `CHOUGH_HC_TERMINAL`,
or Claude Code's `CLAUDECODE` and `HC_TERMINAL_ID`); it is a claim, never a human
decision.

To fix a wrong entry, never edit it: `chough correct '^<entry id>' --reason "<what is
true instead>"` appends a `correction` entry linked to it (`<session>#^<entry id>`
reaches another session or an archived story). `chough next` and `chough status` show
the corrected text, marked as corrected. `chough doctor` reports a Timeline whose
committed entries were rewritten.
