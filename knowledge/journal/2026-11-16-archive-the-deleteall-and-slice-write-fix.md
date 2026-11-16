---
id: 2026-11-16-archive-the-deleteall-and-slice-write-fix
title: Archive the deleteAll and slice-write fix
type: journal
tags: [chough/journal, chough/shipped]
date: 2026-11-16
time: 2026-11-16T04:49:59Z
kind: shipped
links:
  - .chough/archive/sessions/2026-11-16-make-modelstate-deleteall-remove-related-models-and-make.md
  - .specsync/archive/changes/2026-11-16-make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick/
record: .chough/archive/sessions/2026-11-16-make-modelstate-deleteall-remove-related-models-and-make.md
actor:
  - terminal: t34
---
# Archive the deleteAll and slice-write fix

ModelState.deleteAll now fetches without a limit or offset and deletes each match, including models with relationships. A struct DependencySlice write is stored back on the live cached dependency.

Focused dogfood, ModelState, slice, and Keychain tests passed on macOS, and Ubuntu CI passed swift test on the prior tip. This archives the change. It does not merge or tag.

Read more: [the story](../../.chough/archive/sessions/2026-11-16-make-modelstate-deleteall-remove-related-models-and-make.md) · [the archived change](../../.specsync/archive/changes/2026-11-16-make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick/)
