# llm-context

The coders' and the reviewer's home. The architect and the senior architect read here.
A file here is evidence, committed with the work it describes. A report may be long:
this is where the detail that a card cannot hold goes, and the reviewer reads it whole.
A coder writes here and reads one file, the five-line handoff; never a report, a note, a
review or a journal. What a card needs from one, the architect copies into the card.

| File | Who writes | When | Template |
|---|---|---|---|
| `<task-id>-report.md` | the coder | every card: the preflight block before any edit, the completion block before the commit | `_report.md` |
| `<task-id>-<slug>.md` | the coder | only on a block, a misleading card or a question | `_note.md` |
| `<plan-id>-handoff.md` | the coder | at the end of every session, rewritten, five lines | `_handoff.md` |
| `<plan-id>-review.md` | the reviewer | after the plan's last card, over the branch's commit range | `_review.md` |

## Rules

- **Lowercase ids**, the same spelling as `docs/tasks/`.
- **A report is written in two moments**, preflight and completion, and nothing in it is
  edited afterwards. A card run twice (a revised card) gets a second report section,
  dated, under the first.
- **A note is answered by a revised card on the main branch**, and by one line under
  `## Answer` naming the revision and the decision-log entry, or "no change" and why.
  The coder reads the revised card, never the note. A note is never deleted or rewritten.
- **A handoff is five lines, rewritten at the end of every session.** The previous handoff
  is in git history; the detail is in the card's report. A coder resuming a plan reads
  it, then the plan, and nothing else in this folder.
- **Questions never block the plan.** Write the note, then continue on the next card
  that does not depend on the answer. Stop when every remaining card does.
- **No praise in a review.** A finding has a counterexample or a concrete path, a class,
  and a next owner.
