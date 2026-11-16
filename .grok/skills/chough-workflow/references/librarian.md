# Project librarian

The librarian is a project-local knowledge folder, on by default in `knowledge/` at
the project root. Opt out when the human asks: `chough pref set librarian off --source
"<their words>"`. The folder name can be changed with `chough pref set library-dir
<name> --source …`. It is not a shared cross-project vault, not a ledger, and no gate
reads it. `chough next` names its index.

It holds only what has no other home (REQ-cli-044):
- `index.md`, the reading guide: where to start, the journal, where things live, the
  open bugs (at most 20, blocking first, with the total), the rules, skills and
  decisions, each module's lesson source with its lesson count, and the snapshots and
  briefs. It links and copies no text.
- `journal/`, one short dated post per finished piece of work, each recording the UTC
  `time` it was written, and `journal/feed.xml`, an Atom feed of the newest 20 posts,
  newest first by time. The journal is the timeline of archived changes.
- `lessons/`, lessons that span projects. A module's own lessons stay in its spec's
  lesson source.
- Existing `snapshots/` and `briefs/`, and an earlier `library/` folder, as they are.

It is an Obsidian-style vault: every note Chough writes starts with YAML front matter
(`id`, `title`, `type`, `tags`, ISO dates) and links with standard relative Markdown
links, so it reads in Obsidian and on GitHub alike. A link to a folder, such as
`../specs/`, opens on GitHub; Obsidian opens only links to files.

`chough init` creates the folder. Every `chough stage advance` into done writes the
session's `shipped` post, and `chough session close` a `closed` post, then regenerates
`index.md` and the feed (`applied.journal_post` and `applied.librarian_index` under
`chough stage advance --json`; the default text names them on its `Closeout:` line). Commit
them with the work. Chough never rewrites a post, so a person's edit is kept, and
nothing is trimmed or moved out of `.chough/` at done.

`index.md` and `journal/feed.xml` are generated. They merge with
`merge=chough-generated`, and bugs with `merge=chough-bug`: `chough init` declares both
in `.gitattributes` and sets the drivers in the clone's Git config. A fresh clone has
no drivers, since Git does not clone config; `chough doctor` reports that as
`merge_drivers`, and `chough doctor --fix` sets them. A merge keeps ours, and `chough
library index` rebuilds both; `chough library index --check` fails until it does.

## From any stage

Enter it as a side stage and return to the caller:

```sh
chough stage enter librarian --reason "Note what the prototype review taught us"
chough journal add --kind learned --title "Prototype review" --body "One short paragraph." --link design/prototype/COMPANION.md
chough stage return --note "Journal post written"
```

- `library init` creates `index.md`, `journal/` and `lessons/`.
- `journal add --kind <kind> --title <title> --body <text> [--link <link>]...` writes
  one post by create-new. The kind is `shipped`, `closed`, `intent`, `spec`, `broke`
  or `learned`. The body is at most 1,200 bytes: say less and link the record that
  holds the rest. Each link is a project path Git tracks or an http(s) URL. A
  leading `./` is dropped, and a `#fragment` is kept on the link.
- `library index` regenerates `index.md` and the feed. A `README.md` that an earlier
  release generated is removed once its bytes are committed; an edited one is kept.
- Briefs in `briefs/` are focused next-session summaries written from
  [the brief template](../templates/brief.md), linking to originals.

## Closeout

Closeout is one quiet skill pass inside the open native change, before `specsync
change check <id> --commit` and finalize. It is a skill step, not a command or a gate,
and it works whether the librarian is on or off (REQ-cli-015):

1. Write the supported lessons from this change into the module lesson source, each
   starting with its date, `YYYY-MM-DD`, so the knowledge index counts it, with its
   certainty label (`observation`, `hypothesis` or `verified`), source and limits (see
   [accept.md](accept.md)).
2. Check that new checkpoint decisions carry a reason and that verified bugs link
   their failed and passed observations.
3. Add one `completed` checkpoint entry for the closeout.
4. End with one closeout summary of at most 12 lines.

Closeout never edits specs after archive: a lesson found later goes into a new native
change. A library brief is written only when the librarian is on.

## Boundaries

Living HI, prototypes, contracts and native archives stay in their owning locations;
the vault links them and holds no second current copy. Summaries complement originals.
Unfixed bugs remain in the live backlog. The mandatory checkpoint does not depend on
the librarian.
