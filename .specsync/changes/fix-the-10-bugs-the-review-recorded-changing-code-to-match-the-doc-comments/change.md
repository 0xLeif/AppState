---
id: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
state: implementing
type: bug_fix
base_commit: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
---

# Fix the 10 bugs the review recorded, changing code to match the doc comments

## Intent

Fix the 10 bugs the review recorded, changing code to match the doc comments

## Affected Canonical Specs

- `application`
- `property-wrappers`

## Acceptance Criteria

- ReviewFixTests has a test for each of the 8 library bugs in .chough/bugs and all pass; six of them fail on the sources of 7e4eb92, and the write-after-read bug, which XCTest could not show, is shown fixed by a plain executable; the two corrected documentation examples compile in Swift 6 mode; every test class passes on macOS under the strict build

## No-spec Rationale

Not applicable
