# Build loop

`chough stage advance` from plan enters build only when native status shows the
definition approved. Then:

1. Take the next task from the native `tasks.md`. Stay inside the approved paths.
2. Implement with the project's conventions. Keep contracts, requirements
   traceability, tests and documentation in step.
3. Add or update case definitions for the affected requirements (see
   [testing.md](testing.md)).
4. Run focused checks through Fledge (`fledge run test`, `fledge run lint`, project
   lanes) and inspect the output, not just the exit code.
5. Fix failures and repeat. Record a genuine product failure as a bug.
6. Mark the task done in `tasks.md`, then save a checkpoint:
   `chough checkpoint --completed "<increment>" --next-action "<next step>"`.

## Keep it composable

Keep specs and source lean and composable, without being dogmatic about it:

- Split independent behavior into its own spec module and source module. Do not grow
  one spec for everything. Keep coupled behavior together, because splitting coupled
  code only adds indirection.
- Treat a source file heading past about 1,000 lines as a candidate to split along a
  real seam (a separate responsibility, data type or command), not by line count alone.
- Spec files have no size limit. Chough reads them at any size. Size is a hint to look
  for independent parts, never a gate. Chough's own records keep their bounds, so the
  thing to keep lean is generated proof and logs, not the contract.
- Chough's bounds never reach native sources: every gate and check reads them at full
  size. Never shorten, reword or split HI intent or criteria, specs or SpecSync change
  and archive files to fit a Chough limit; if one exceeds a Chough bound, stop and
  report a Chough bug.

## Ownership

When subagents help, give each explicit files or modules, the relevant contract and
requirements, and instructions to preserve others' edits. Only one agent edits a
shared file at a time. The checkpoint has one writer; other agents report back
instead of editing it.

## Escalate only what matters

Ordinary choices inside the approved scope are yours. Escalate a genuine blocker or
a decision that would change intent, contract, acceptance criteria or scope. Record
it with `--blocker` or `--awaiting-human`, and go back to plan if scope must change.

A model saying a task is done is not a native transition, a passed test or a review.
Native records and process results are what count.
