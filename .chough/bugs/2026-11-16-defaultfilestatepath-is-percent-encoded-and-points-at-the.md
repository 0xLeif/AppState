---
kind: bug
id: 2026-11-16-defaultfilestatepath-is-percent-encoded-and-points-at-the
aliases: []
title: defaultFileStatePath is percent-encoded and points at the wrong directory
status: verified
classification: product-defect
scope: in-scope
impact: On macOS with such a home folder the literal directory cannot be created, so every default-path FileState write fails and is only logged; values do not survive a relaunch.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-path-encoding-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-path-encoding-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:14Z
updated: 2026-11-17T00:29:49Z
---
# defaultFileStatePath is percent-encoded and points at the wrong directory

**What happened:** FileState files are written to a directory whose name contains %20, or the write fails.

Actual: The default uses URL.path(), which percent-encodes, and the result is later passed to URL(filePath:), which takes it literally (FileManager+AppState.swift:13). Observed for a directory named 'appstate path check': computed path ends in appstate%20path%20check/Documents/App; 'file under real Documents: false'; 'file under literal %20 directory: true'.

**Steps:** Trigger: The documents directory path contains a space or a non-ASCII character, for example a macOS user folder with a space or an accent.
1. let p = documentsURL.appending(path: "App").path() where the URL contains a space
2. write a file through URL(filePath: p)
3. look for the file under the real directory

**Expected:** Files land in Documents/App.

**Why it matters:** On macOS with such a home folder the literal directory cannot be created, so every default-path FileState write fails and is only logged; values do not survive a relaunch.

**Fix:** The default path is built with path(percentEncoded: false). Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: path(percentEncoded: false), in a helper that ReviewFixTests.testDefaultFileStatePathIsNotPercentEncoded calls. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: The default path is built with path(percentEncoded: false). Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 the test was run on macOS against the pre-fix sources at 7e4eb92 and against main at 0821de7 (3.1.0 is tagged at 69d692c with the same sources). ReviewFixTests.testDefaultFileStatePathIsNotPercentEncoded passes on 0821de7. On 7e4eb92 the helper it calls does not exist, so the same assertion was run on the old expression, appending(path:).path(), and failed. · by claude-code (hc t34)
- 2026-11-17T00:29:49Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-path-encoding-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-path-encoding-after-fix · by claude-code (hc t34)
