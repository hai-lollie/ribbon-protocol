# ADRs

One architecture decision record per design problem. The architect writes it from what
was understood of the assignment. The senior architect reads it, suggests changes, and
accepts it. No plan is cut into cards before every ADR it rests on is accepted.

## Rules

- **File name** `NNNN-<slug>.md`: four digits, a lowercase slug, numbers never reused.
  The id is `NNNN`.
- **Under 3000 words**, the whole file, checked with `wc -w`. A problem that needs more
  is two problems: split it before writing.
- **Eight sections, in this order, every one present:** Abstract; Introduction; Problem
  at hand; Proposed solution; Alternatives; Reconsider when; References; Date and edits.
  Copy `_template.md`, which says what each section holds.
- **Three header lines** before the sections: `Status`, `Implemented by`, `Diagrams`.
- **Status line:** `proposed`, then `accepted by <name>, <date>`, then `superseded by
  NNNN` when that happens. An ADR is edited in place while it answers the same problem
  (a correction, a sharper recipe, a section rewritten): every edit is a row of "Date
  and edits", and an accepted ADR goes back to `proposed` until the senior architect
  accepts the edit. A different answer to the same problem is a new ADR that supersedes
  this one.
- **The proposed solution names its pattern** and reads as a pattern does: what we will
  implement, why it is good here, what it costs. "We will implement X. X will allow us to
  ... This gives us ... at the cost of ...". A pattern or a community practice is cited
  with a link under References.
- **Tables and diagrams.** A table for the examples of the problem, for the rules of the
  solution, for the edits. A diagram for every flow: a sequence diagram, kept in
  `docs/diagrams/NNNN-<name>.mmd` and embedded in the ADR as a mermaid block under its
  relative path, the block a copy of the file. `docs/diagrams/README.md` says how a
  diagram is drawn.
- **Alternatives:** about 75 words each: two lines on why it was considered, two on why
  it was ruled out.
- **Reconsider when:** the conditions that reopen the decision, one per bullet, each one
  checkable. If it starts raining, we reconsider going outside.
- **Plain words.** The senior architect reads it in ten minutes. Name what stays
  undecided, and who decides it. A decision the coder would have to make is a decision
  this ADR must make.
- **Implemented by:** the plan ids, written when the plans exist.
