---
kind: bug
id: 2026-11-16-filestate-with-isbase64encoded-false-loses-values-that-look
aliases: []
title: FileState with isBase64Encoded false loses values that look like Base64
status: fix-pending-verification
classification: product-defect
scope: in-scope
impact: Silent loss of persisted values for unencoded files. The cache hides it until the process restarts.
criteria: []
requirements: []
cases: []
evidence: []
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:14Z
updated: 2026-11-16T05:25:09Z
---
# FileState with isBase64Encoded false loses values that look like Base64

**What happened:** After a relaunch a FileState<Bool> written as true reads false, and a FileState<Int> written as 1234 reads 0.

Actual: FileManager.data(path:filename:) always tries Data(base64Encoded:) first (FileManager+AppState.swift:67), decodes the plain JSON into garbage, JSON decoding throws, and the getter returns initial. Observed: XCTAssertEqual failed: ("false") is not equal to ("true"); ("0") is not equal to ("1234"); the 3-digit control passed.

**Steps:** Trigger: isBase64Encoded: false and a JSON text that is also valid Base64: true, null, or a number with 4, 8, 12 digits.
1. fileState(initial: false, filename: name, isBase64Encoded: false); write true
2. remove the cache entry, as a relaunch does
3. read the value

**Expected:** The stored value is read back.

**Why it matters:** Silent loss of persisted values for unencoded files. The cache hides it until the process restarts.

**Fix:** Not fixed yet.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: FileManager.in falls back to the raw bytes. ReviewFixTests.testUnencodedFileStateReadsBackBase64LookingValues fails on 7e4eb92 sources and passes now. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
