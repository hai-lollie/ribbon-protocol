Seeded from the Ribbon Protocol, <ribbon-version>.

# docs

The homes of the belt. The protocol itself is the "Ribbon Protocol" section of the root
`AGENTS.md`; this file says who writes where and who reads what.

| Path | Who writes | What | Who reads |
|---|---|---|---|
| `docs/` | the senior architect, the architect | most of the project's prose: specifications, guides, the files below | everyone |
| `docs/adrs/` | the architect | one architecture decision record per design problem, markdown, under 2000 characters, with tables and diagrams where they save words | the senior architect, who validates it; the reviewer; the coder, through a card's `adr` line |
| `docs/diagrams/` | the architect | `<adr-id>-<diagram-name>.mmd`, mermaid first, `.puml` only as a fallback | whoever reads the ADR |
| `docs/tasks/` | the architect | `<plan-id>.plan.yaml` and its cards `<plan-id>-NN.yaml` | the senior architect, who validates the plan; the coder; the reviewer |
| `docs/llm-context/` | the coders, the reviewer | reports, notes, handoffs, reviews | the architect, who answers; the senior architect, who reads verdicts |

Each folder has a `README.md` with its rules and a `_template` file to copy. Ids are
lowercase everywhere.

`field-guide.md` is the long-form guide, the reference PDF as text. An architect new to
the protocol reads the root `AGENTS.md`, this file, and then the field guide. That is
the full context.
