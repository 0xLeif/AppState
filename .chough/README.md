# Chough records

This folder holds Chough's records for this project. Each record is one Markdown file:
people read its body, agents parse its front matter.

- `sessions/<id>/session.md`: an open piece of work. Its front matter says where the
  work stands; its Timeline lists every move, appended and never rewritten.
  `evidence/` holds what was checked and `agent/` an agent's notes and inbox. The
  folder leaves once the session's story is written and committed.
- `archive/sessions/<id>.md`: the story of a finished session, kept for good, with its
  key screenshots beside it in `archive/sessions/<id>/`.
- `archive/shelved/<id>/`: a session set aside unread.
- `archive/migrations/<id>.md`: the receipt of a migration from Chough 0.5.x.
- `bugs/<id>.md`: one bug each, kept for good; its Log only grows.
- `cases/*.cases.toml`: test-case definitions, which a person edits.
- `preferences.json`: the project's standing preferences, which a person edits.
- `local/`: this machine's state (the active session, the writer lock, gate lists,
  logs). It is never committed.

Intent lives in [hi/](../hi/), contracts in [specs/](../specs/) and change history in
[.specsync/archive/](../.specsync/archive/). Chough links them and copies nothing.
