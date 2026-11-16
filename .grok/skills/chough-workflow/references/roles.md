# Review roles

Use these roles to review intent, design, plans and implementation. They are lenses,
not people, and none of them stands in for a required human decision.

| Role | Looks for |
|---|---|
| Product and user advocate | Whether the outcome matches the want; missing user scenarios; scope creep |
| QA and QE | Observable expected outcomes; edge and failure cases; how each criterion can be tested |
| Design | Flows, states and consistency with the canonical prototype |
| Accessibility | Keyboard use, focus, contrast, labels, motion, assistive technology |
| Engineering | Feasibility, effort, dependencies, failure handling |
| Architecture | Ownership boundaries, data and contract changes, migration, security |

## Running them

- With subagents: give each role the specific files to read, the question to
  answer and the instruction to change nothing. Collect their findings.
- Without subagents: do the passes yourself in sequence, writing each role's findings
  before starting the next so one lens does not blur into another.

Pick only relevant roles. A CLI change rarely needs a design pass; a copy change
needs language review more than architecture.

## A useful finding

Each finding names its role, the concrete reference (criterion ID, FRD section,
prototype state, requirement or file), the problem (missing scenario, untestable
outcome, infeasible step, consequential tradeoff) and a suggested resolution.
Discard findings without a concrete reference.

Then synthesize: merge duplicates, resolve what you can within scope, and bring the
human only the decisions that change the product. Use
[the review-findings template](../templates/review-findings.md).
