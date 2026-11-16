# Optional release and delivery

The workflow does not proceed to release on its own. A completed or archived change
does not authorize a version bump, tag, publication, deployment or live-health job.

## Entering release

`chough stage enter release --reason "<request>"` from done needs either:

- a human request for this objective, recorded with `chough consent grant release
  --source "<their words>"`; or
- a standing project setting, recorded with `chough pref set release standing
  --source "<their words>"` only when a human asked for it.

Ask before the move into done. With release authorized then, the session stays open
for it (`kept_open`) and archives itself at the move from release into done. A
decision still to come, such as approval to publish, is a gate that holds release
(`--holds release`), so build, test and accept keep moving.

## Doing the work

Use the project's actual version, artifact and delivery commands (for example the
Fledge release or changelog commands the project defines). Observe each result and
record it as what it is:

| Kind | Means |
|---|---|
| `publication-observation` | An artifact or package was published |
| `installation-observation` | Someone installed it in a named environment |
| `deployment-observation` | It was deployed to a named target |
| `live-health-observation` | The deployed target was checked and behaved as expected |
| `dry-run` | A rehearsal or simulated adapter; never a delivery |

Simulated deploy scripts and dry runs are recorded as `dry-run`. A merged pull
request, a tag, a published package, a deployment and a healthy live target are
separate facts. Then `chough stage advance` returns to done.
