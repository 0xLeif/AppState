---
kind: session
id: 2026-11-16-demo-app-ui-tests
aliases: [demo-app-ui-tests]
objective: Add an iOS demo app with UI tests and an iOS CI job that runs them and the unit tests inside the app
intent_scope: ""
modules: []
stage: accept
stage_status: active
iteration: 1
callers: []
native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
pr: ""
criteria: []
requirements: []
cases: []
design: []
files: []
observations: []
bugs: []
blockers: []
waiting_on_human: []
run_consents: []
next: Continue accept
---
# Add an iOS demo app with UI tests and an iOS CI job that runs them and the unit tests inside the app

## Goal

Add an iOS demo app with UI tests and an iOS CI job that runs them and the unit tests inside the app

## Where it stands

- Demo app, UI tests and iOS workflow committed; PR 159 passes all five CI jobs including the iOS job; PR 157 closed as superseded by PR 158

## Decisions and why

- 0xLeif decided "Scope approval of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job": "Yes everything as 3.1.0 and yes add demo apps and ui tests and all" (Claude Code chat on 2026-11-16, in reply to the question whether to add the demo app and UI tests under Examples with an iOS CI job); recorded by claude-code; a relayed claim, not authenticated; ran specsync change approve add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job as 0xLeif
- 0xLeif decided "Implementation review of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job": "merged on rebase and fix the merge conflicts" (Claude Code chat on 2026-11-16, after he merged PR 159 into main); recorded by claude-code; a relayed claim, not authenticated

## What was verified

## Open threads

## Timeline

- 2026-11-16T15:15:17Z · start · intent → intent · Add an iOS demo app with UI tests and an iOS CI job that runs them and the unit tests inside the app ^t-4b3f31
  - revision: 07cf51e1cee0e6ec4469b75db25738dd8642268f
  - by: claude-code (hc t34)
- 2026-11-16T15:15:53Z · gate-opened · intent → intent · Scope approval of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job ^t-f3ad7c
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 07cf51e1cee0e6ec4469b75db25738dd8642268f
  - holds: intent
  - drives: approve
  - by: claude-code (hc t34)
- 2026-11-16T15:15:53Z · gate-closed · intent → intent · Scope approval of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job ^t-bc1720
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 07cf51e1cee0e6ec4469b75db25738dd8642268f
  - relayed_by:
    - decided_by: 0xLeif
    - words: Yes everything as 3.1.0 and yes add demo apps and ui tests and all
    - where: Claude Code chat on 2026-11-16, in reply to the question whether to add the demo app and UI tests under Examples with an iOS CI job
    - recorded_by: claude-code
    - native: specsync change approve add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
    - actor: 0xLeif
  - by: claude-code (hc t34)
- 2026-11-16T15:44:38Z · gate-opened · intent → intent · Implementation review of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job ^t-ab4b0f
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 5370142b88179b2ba356b7830f00436f7206c220
  - holds: intent
  - drives: none
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · gate-closed · intent → intent · Implementation review of add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job ^t-e5b245
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - relayed_by:
    - decided_by: 0xLeif
    - words: merged on rebase and fix the merge conflicts
    - where: Claude Code chat on 2026-11-16, after he merged PR 159 into main
    - recorded_by: claude-code
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · advance · intent → design ·  ^t-452fe3
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · advance · design → plan ·  ^t-e1fc99
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · advance · plan → build · ungated:sdd-disabled ^t-eac10c
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - gate: ungated:sdd-disabled
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · advance · build → test · ungated:sdd-disabled ^t-1b7e04
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - gate: ungated:sdd-disabled
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - by: claude-code (hc t34)
- 2026-11-16T23:23:23Z · advance · test → accept · ungated:sdd-disabled ^t-7c915f
  - native_change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
  - gate: ungated:sdd-disabled
  - revision: 69d692c665ddf38fcd8963a716376ceccc034476
  - by: claude-code (hc t34)
