# Intent and FRD

## Capture the want

Start from the conversation or existing intent. Run `hi export <scope>` and read
`INTENT.md` before allocating any ID. Keep four kinds of statement apart in your
notes and in what you show the human:

| Kind | How to write it |
|---|---|
| Direct human statement | Quote it exactly, with where it came from |
| Your interpretation | Mark it as yours |
| Proposed addition | Mark it proposed until the human agrees |
| Unresolved choice | Name the options and why it matters |

Never present your paraphrase as a quote. HI criteria are plain sentences about
what somebody wants, not what the code will do. Capture agreed criteria with `hi
<FAMILY-N> "<sentence>"`; a new family file is created on first use. Never reuse or
renumber an ID; withdraw one with `hi retire <ID> "<reason>"`.

## Derive the FRD

Write the smallest FRD that makes the scope testable, using
[the FRD template](../templates/frd.md): purpose, traceability to HI, scope,
exclusions, consequential assumptions, dependencies and open questions. Put stable
`REQ-*` requirements in the native module `requirements.md` through SpecSync and
link a cross-module FRD to them rather than writing competing requirements.

## Review before asking

Run the role passes in [roles.md](roles.md), as parallel subagents or one after
another. Keep findings that point to a concrete criterion or FRD section and name a
missing scenario, a testability problem, a feasibility concern or a consequential
tradeoff. Drop generic advice and routine choices you can make yourself.

Synthesize the remaining findings with
[the review-findings template](../templates/review-findings.md) into a short list of
decisions only the human can make. Re-interview where an answer changes the
product. Then ask for one decision: approval of the intent stage as a whole. Do not
ask the human to approve criteria one by one.

## Later discoveries

When later work reveals something new about what is wanted, append a new criterion
with the next free ID and return the affected scope to this stage with `chough stage
back --to intent --reason "<discovery>"`. Do not rewrite an approved criterion to
fit what was built.

## Checkpoint

Record criteria and requirement IDs (`chough checkpoint --criterion … --requirement
…`), decisions with their reasons, open questions, and the pending intent decision
in `--awaiting-human` until the human answers.
