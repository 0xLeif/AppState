# Conditional design

Enter this stage only when the intent changes visuals or interactions. Otherwise run
`chough stage skip --reason "<why there is nothing visual>"`; the reason is kept.

## One canonical prototype

Keep one evolving prototype per product surface, by default `design/prototype/`:

- `index.html` with lightweight script only where interaction must be shown;
- `styles.css` built on the project's tokens (for CorvidLabs projects, the design
  system's `tokens.css`; never hardcode colors that a token covers);
- `COMPANION.md` with decisions, notes and questions against acceptance criteria,
  and mappings to HI, FRD and requirement IDs.

Start from [the prototype templates](../templates/prototype/). It may hold several
screens and responsive layouts, and should show relevant loading, empty, error,
disabled and success states. It should look like the intended product, following
the target project's conventions. Figma is optional; do not build a separate
dashboard just to exercise this stage.

Iterate in the same files. Earlier versions live in Git history. Never keep several
competing "current" prototypes.

## Review what renders

Source inspection is not rendered design QA. A browser- or vision-capable agent
opens the prototype, exercises the interactions, checks each listed state at each
target viewport, and saves screenshots with notes. Record them as observations
(`chough cases record <design-qa case> --method agent-assisted …`) with method and
limits. Check each screenshot for personal information before recording it; a session
commits at most 5 small key screenshots, each with `chough evidence add … --screenshot
<path>`, and larger ones are recorded by fingerprint (see [testing.md](testing.md)). A text-only host does the source checks, then hands rendered judgment to a
capable agent or the human and leaves the unperformed checks explicit.

Run the design, accessibility and user-advocate passes from [roles.md](roles.md).

## Approval

The human approves the rendered prototype and the companion notes together. Until
then, keep `--awaiting-human "Design approval of design/prototype"` in the
checkpoint and do not present the design as approved. Polish stays in this stage;
a discovery that changes what the product should do goes back to intent.
