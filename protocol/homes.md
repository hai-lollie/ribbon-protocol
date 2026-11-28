## The homes

| Path | Who writes | What |
|---|---|---|
| `docs/` | the architects | most of the project's prose |
| `docs/adrs/` | the architect | one ADR per design problem: markdown of 1000 to 4500 words in Simplified Technical English, the ten sections of `docs/adrs/README.md` in order and none empty, its diagrams embedded, no plan while an open question is pending; the senior architect validates, and again after every edit |
| `docs/diagrams/` | the architect | `<adr-id>-<diagram-name>.mmd` (mermaid): a flow is a sequence diagram with `alt` paths and notes that carry the call or the schema; another kind only when the idea is not a flow; `.puml` only when mermaid cannot draw it |
| `docs/tasks/` | the architect | `<plan-id>.plan.yaml` and its cards `<story-id>-NN.yaml`; a story larger than one review is phase plans, `<story-id>-pN.plan.yaml` |
| the decision log (`CHANGELOG.md`) | the architect | one entry per decision or regroup; the newest ten in full, every older one three lines under 200 characters (`What:`, `Why:`, `Now:`), compressed by the commit that appends the eleventh |
| `docs/llm-context/` | the architect, the security engineer, the coders, the reviewer | `<adr-id>-security-r<N>.md` by the security engineer, with the architect's appended response; `<task-id>-report.md` per card; `<task-id>-<slug>.md` on a block or a question; `<plan-id>-handoff.md`, five lines, rewritten each session; `<plan-id>-done.md`, the coder's five of "Done" at the plan's last card; `<plan-id>-review.md` by the reviewer; `<plan-id>-orchestration.md` by a Herdr architect |
| `rules/` | the project — conventions are decisions; the senior architect approves | coding conventions, one file per theme: `testing.md` is universal test-craft, `<language>.md` holds per-language idioms; a card names its themes in `context.read_first`, the coder reads them before the first edit, the reviewer checks adherence |

Ids are lowercase everywhere; a YAML line is at most 150 characters, folded with `>-`. A
coder never edits `docs/adrs/`, `docs/diagrams/` or `docs/tasks/`. Only the architect
revises a card and bumps its `revision`, on the story's contract branch, and merges it
into the main branch before the coder is told: a coder whose branch has diverged reads it
there (`git show main:docs/tasks/<task-id>.yaml`) and rebases only when the architect says
so, after a gate. Proof is a command, its exit code and its output, on disk under
`docs/llm-context/`, committed with the work; nothing an LLM decided lives only in its
context window. After the commit, the architect appends the card's measured cost to its
report from the harness's own records, the model, the effort and the tokens as they ran,
never retyped. `docs/llm-context/history/` holds what no live plan reads: the journals of
closed work, outside reviews, comparisons, and the reports, notes, handoff and review of a
plan once it merges or is abandoned. The architect moves them there with `git mv` at every
clean-up, in one commit with the references that name them, so the listing a coder sees
holds the templates, the README and the live plan's files. A Herdr orchestration report
with an unacknowledged timed-out decision remains live until the senior architect's
disposition.
