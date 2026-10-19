# llm-context

The coders' and the reviewer's home. The architect and the senior architect read here.
A file here is evidence, committed with the work it describes. A report may be long:
this is where the detail that a card cannot hold goes, and the reviewer reads it whole.
A coder reads a report only when a card's `read_first` names it, with the section.

| File | Who writes | When | Template |
|---|---|---|---|
| `<task-id>-report.md` | the coder | every card: the preflight block before any edit, the completion block before the commit | `_report.md` |
| `<task-id>-<slug>.md` | the coder | only on a block, a misleading card or a question | `_note.md` |
| `<plan-id>-handoff.md` | the coder | at the end of every session, appended | `_handoff.md` |
| `<plan-id>-review.md` | the reviewer | after the plan's last card, over the branch's commit range | `_review.md` |

## Rules

- **Lowercase ids**, the same spelling as `docs/tasks/`.
- **A report is written in two moments**, preflight and completion, and nothing in it is
  edited afterwards. A card run twice (a revised card) gets a second report section,
  dated, under the first.
- **A note is answered by the architect**, appended under `## Answer`, with the card
  revision it produced. A note is never deleted or rewritten.
- **A handoff is append-only:** one section per session, newest last. A section is the
  five lines of `_handoff.md`; detail belongs in the card's report. A coder resuming a
  plan reads the newest section, then the plan, and nothing older.
- **Questions never block the plan.** Write the note, then continue on the next card
  that does not depend on the answer. Stop when every remaining card does.
- **No praise in a review.** A finding has a counterexample or a concrete path, a class,
  and a next owner.
