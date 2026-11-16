# Optional repeated validation and monitoring

Ordinary functional checks and project-required gates always run during approved
work. Repetition beyond that, and monitoring, are optional.

## Who decides

| Situation | What to do |
|---|---|
| Standing preference `always` | Run within its stated limits |
| Preference `off` | Do not run unless the human asks for this run |
| Preference `ask` (default) and the choice matters | Ask one short contextual question |
| The human agrees for this run | `chough consent grant repeat-validation --source "<their words>"` |
| The human says "always for this project" | `chough pref set repeat-validation always --source "<their words>"` |

A run consent ends with the objective and never becomes a standing preference.
Record preferences only from an explicit human statement. `chough pref show` lists
effective values and where each came from.

## Run, stop, resume

`chough validate run <case> --times N [--interval S] --environment <env>` repeats an
automated case in the foreground and records every attempt. A run is one evidence
entry, named `<date>-<case slug>-run`, holding each attempt with its start, result,
duration and the case-run entry it recorded, and a summary with the attempt and
failure counts and elapsed time; each attempt is also its own case-run entry, which
bugs link. Raw output stays in `.chough/local/logs/`. Timestamps determine chronology,
never names. The command needs a `repeat-validation` run consent or the standing
preference `always`; a `monitoring` consent or preference only allows entering the
validate stage, not `validate run`.

`chough validate stop` leaves a stop request in `.chough/local/validation.stop`. The running
repetition halts before its next attempt, and any later run halts at once, until
`chough validate resume <run>` clears the request and continues that run with the
same stored limits after re-checking authorization. Pausing the stage
(`chough stage pause`) pauses a run the same way. Run IDs from before 0.6.0 (`VAL-…`)
stay readable and resumable as aliases. Stop markers, stored limits, counts, elapsed
time and authorization behavior stay unchanged.

Each failure is kept locally: it opens or extends a bug for that case, which stays in
the backlog after a restart. Results are labelled as repeated runs with attempts,
failures and elapsed time. Retrying until one success is not soak testing, a file
watcher is not product health, and neither is authority to repair anything.

## Monitoring sources

Monitor with the project's own health, log or error sources, wrapped as cases with a
`command` binding and an `expect_output` assertion. No general production-health
service is assumed. Any real or live job needs explicit authorization.

Whether a monitor may open an investigation is unsettled. The default,
`monitor-initiation capture-only`, only records local findings. With
`propose-change`, Chough prints a suggested `specsync change new` command; it never
runs it. Any repair follows the normal scope and gates.
