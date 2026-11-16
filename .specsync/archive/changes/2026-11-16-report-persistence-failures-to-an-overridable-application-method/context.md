---
change: report-persistence-failures-to-an-overridable-application-method
artifact: context
---

# Context

A failed FileState read, write or delete, and a StoredState or SyncState value that cannot be encoded, were visible only in the log. Logging is off by default, and on Apple platforms the logger is `os.Logger`, so an app could not react in code. A read silently returned the initial value, which looks the same as a state that was never written.

This came out of the review that produced the 3.0.3 fixes. Three other ideas from that review were checked and dropped:

- The collection-typed state crash on Linux does not reproduce on Swift 6.1, so the cache was left alone.
- Every English documentation example compiles once placeholder types are supplied, so no documentation build was added.
- CI already runs the whole test suite unfiltered on three platforms, so test isolation was left alone.

Keychain writes are not covered. `Keychain.set` discards the `OSStatus`, and no test here can force Security.framework to fail, so reporting it would be untested code.

The branch is stacked on the 3.0.3 fix branch.
