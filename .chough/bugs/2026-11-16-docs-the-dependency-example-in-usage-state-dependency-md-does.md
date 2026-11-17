---
kind: bug
id: 2026-11-16-docs-the-dependency-example-in-usage-state-dependency-md-does
aliases: []
title: "Docs: the dependency example in usage-state-dependency.md does not compile in Swift 6 mode"
status: verified
classification: product-defect
scope: in-scope
impact: The first dependency example a reader meets fails in a new Swift 6 project. Every other Swift block in README and documentation/en type-checked, apart from snippets that need context from earlier blocks.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-docs-dependency-example-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-docs-dependency-example-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:28Z
updated: 2026-11-17T00:30:15Z
---
# Docs: the dependency example in usage-state-dependency.md does not compile in Swift 6 mode

**What happened:** error: type 'any NetworkServiceType' does not conform to the 'Sendable' protocol

Actual: Dependency requires Value: Sendable. The protocol does not inherit Sendable and NetworkService is a non-final class. The errors are on the Dependency<NetworkServiceType> declaration and both @AppDependency uses. The same code builds without diagnostics in Swift 5 mode.

**Steps:** Trigger: Compile the NetworkServiceType example from usage-state-dependency.md with the Swift 6 language mode.
1. copy lines 64-99 of documentation/en/usage-state-dependency.md into a Swift 6 target that depends on AppState
2. swift build

**Expected:** The example compiles.

**Why it matters:** The first dependency example a reader meets fails in a new Swift 6 project. Every other Swift block in README and documentation/en type-checked, apart from snippets that need context from earlier blocks.

**Fix:** The example declares the protocol Sendable, the class final, and uses any NetworkServiceType, in all eight languages. Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:28Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted, in all eight languages: Sendable protocol, final class, any NetworkServiceType. The English blocks compile in a Swift 6 scratch target. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: The example declares the protocol Sendable, the class final, and uses any NetworkServiceType, in all eight languages. Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 the two English example blocks were compiled in a Swift 6 target against main at 0821de7. The blocks from 7e4eb92 fail with: type 'any NetworkServiceType' does not conform to the 'Sendable' protocol. The blocks from 0821de7 build. Only the English page was compiled. · by claude-code (hc t34)
- 2026-11-17T00:30:15Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-docs-dependency-example-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-docs-dependency-example-after-fix · by claude-code (hc t34)
