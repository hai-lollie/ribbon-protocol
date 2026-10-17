# ADRs

One architecture decision record per design problem. The architect writes it from what
was understood of the assignment. The senior architect reads it, suggests changes, and
accepts it. No plan is cut into cards before every ADR it rests on is accepted.

## Rules

- **File name** `NNNN-<slug>.md`: four digits, a lowercase slug, numbers never reused.
  The id is `NNNN`.
- **Under 2000 characters**, the whole file, checked with `wc -m`. A problem that needs
  more is two problems: split it before writing.
- **Sections, in this order:** Status, Context, Decision, Consequences, Alternatives
  considered. Copy `_template.md`.
- **Status line:** `proposed`, then `accepted by <name>, <date>`, then
  `superseded by NNNN` when that happens. An accepted ADR is never edited; a change is
  a new ADR that supersedes it.
- **Plain words.** The senior architect reads it in two minutes. Tables and diagrams
  where they save words; a diagram lives in `docs/diagrams/` as `NNNN-<name>.mmd` and
  the ADR links it on its `Diagram:` line. A short mermaid block may sit inline.
- **Name what stays undecided**, and who decides it. A decision the coder would have
  to make is a decision this ADR must make.
- **Implemented by:** the plan ids, written when the plans exist.
