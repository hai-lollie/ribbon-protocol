# ADRs

One architecture decision record per design problem. The architect writes it from what
was understood of the assignment. The senior architect reads it, suggests changes, and
accepts it. No plan is cut into cards before every ADR it rests on is accepted. The
architect writes no plan and no card while one of those ADRs has a pending open question.

## Rules

- **File name** `NNNN-<slug>.md`: four digits, a lowercase slug, numbers never reused.
  The id is `NNNN`.
- **The title** is one small line after the id, in Simplified Technical English: the
  proposal in the user's words, what they get, at most eight words and no technical
  term. "Cached answers that never go stale", not "ETag over the body bytes".
- **1000 to 4500 words**, the whole file, checked with `wc -w`. Under the floor the ADR
  has not explained its problem; over the ceiling it holds two problems: split it.
- **Ten sections, in this order, every one present and never empty:** Abstract;
  Introduction; Glossary; Problem at hand; Proposed solution; Alternatives; Reconsider
  when; Open questions; References; Date and edits. Copy `_template.md`, which says what
  each section holds. The architect never drops a section, never leaves one blank, and
  never writes "n/a". When the architect cannot write a section from its own reading, it
  asks the senior architect an open question. References is the one exception, and it is
  rare: when the ADR rests on no pattern, no standard and no recorded decision,
  References holds the single line `None: <the reason>`.
- **The glossary** is a table, word and meaning, at most six rows, only the project's
  own words: the ones a reader cannot look up. A design pattern, an architectural term
  or a protocol term that is established stays out of it, and is linked under References
  where it is used.
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
- **Open questions:** what the architect needs answered to finish the design. The
  architect always brings at least one question to discuss. The questions are numbered
  from 1, one thing per question, and a question keeps its number. A question ends in one
  of two ways, and both put a check mark, ✅, in front of it. Answered: the answer is
  indented under it, `A: <the answer>. [YYYY-MM-DD]`. Closed, when it no longer matters:
  the question is also struck through, `✅ <del>the question</del>`. A question with no
  check mark is pending. The architect answers from its own reading or asks the senior
  architect. Every answer and every close is an edit, a row of "Date and edits". When the
  architect finds no question at all, the section holds the single line
  `No open questions found. 👀`. **The architect writes no plan and no card while a
  question is pending.**

  ```markdown
  1. ✅ Does it rain in September?

     A: Yes. In Brazil, September is the change from winter to spring. It rains a
     lot. [2026-10-22]

  2. ✅ <del>Do we take the bus?</del>

  3. Do we need an umbrella?
  ```
- **Simplified Technical English (ASD-STE100), always, with no exception.** The whole
  ADR follows it: one idea per sentence, at most 25 words; a simple tense (present, past,
  or future with "will"); the active voice; no "-ing" form as a verb; one word for one
  concept, the same word each time. The senior architect reads the ADR in ten minutes.
  What stays undecided is an open question. A decision the coder would have to make is a
  decision this ADR must make.
- **Implemented by:** the plan ids, written when the plans exist.
