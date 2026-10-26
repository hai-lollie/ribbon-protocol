# Ribbon Protocol 🎀

Guardrails for a multi-LLM engineering belt: plan with intelligence, implement with
constraints, verify with evidence. This repository is a project template, a reference
guide, and the schemas a belt of mixed-capability models needs to work together without
anybody grading their own work.

The rule worth remembering: **the architect defines what must be true, the coder chooses
how to make it true within agreed boundaries, and the harness independently verifies
whether it became true.**

Kawaii does not mean casual about correctness. Pink bows on the outside, strong
invariants on the inside.

## The belt in one screen

| Role | Does | Output |
|---|---|---|
| Senior architect, a person | brings the problem, the constraints, what success looks like, when to stop; validates ADRs and plans | decisions |
| Architect | resolves semantics and risk; writes one ADR per design problem; cuts a plan into cards with contracts and dependency order | ADRs, plans, cards |
| Independent reviewer | reads the commit range against the plan and the cards; writes findings with counterexamples | a review with verdicts |
| General coder | implements one plan, card by card, inside each card's scope; leaves evidence after every card | patches, reports |
| Entry-level coder | small mechanical patches inside an allowlist | small patches, reports |
| Trusted verifier | runs the gate outside the coder's control | machine PASS or FAIL |

The architect and the reviewer are different models, from different vendors when
possible, and may swap roles between plans. The loop is Architect, Contract, Execute,
Verify, and it stops by the five of "Done, and when the loop stops": a plan is done when
the gate, the boot, the acceptance file, coverage and the absence of open semantic
findings hold on its head; the rest is debt, and two review rounds are the most. The
whole protocol is `AGENTS.md`, about 200 lines; read it first.

## What is in this repository

```
ribbon-protocol/
├── README.md                                  this file
├── AGENTS.md                                  the protocol: the belt, the loop, the decision budget, the homes,
│                                              the plan and its cards, the seven steps, the reviewer's brief, done. Copied into every project
├── VERSION                                    "ribbon N"
├── Ribbon-Protocol-Multi-LLM-FieldGuide.pdf   the reference guide, October 2026, working edition 1.0
└── docs/                                      copied into every project
    ├── README.md                              the homes: who writes where, who reads what
    ├── field-guide.md                         the PDF as text, for a model without PDF tooling
    ├── adrs/                                  README.md and _template.md: one ADR per design problem
    ├── diagrams/                              README.md: <adr-id>-<name>.mmd, mermaid first
    ├── tasks/                                 README.md, _template.plan.yaml, _template.task.yaml
    └── llm-context/                           README.md, _report.md, _note.md, _handoff.md, _review.md
```

## Seed a project

From the root of your project, with this repository cloned at `~/dev/ribbon-protocol`:

```sh
RIBBON=~/dev/ribbon-protocol
cp -r "$RIBBON/docs" docs                 # 1. the homes, the schemas, the templates
cat "$RIBBON/AGENTS.md" >> AGENTS.md      # 2. the protocol, appended to your agent rules (or cp when none exist)
printf '@AGENTS.md\n' > CLAUDE.md         # 3. only if your tool reads CLAUDE.md and the file does not exist
cat "$RIBBON/VERSION"                     # 4. write this version into docs/README.md, first line
git add AGENTS.md CLAUDE.md docs && git commit -m "Seed the Ribbon Protocol, ribbon 1"   # 5.
```

Then fill the belt (next section), and tell your architect to read `AGENTS.md`,
`docs/README.md` and `docs/field-guide.md`, in that order. That is the full context: an
architect who has never heard of the protocol can start from those three files.

## Fill the belt

Open your project's `AGENTS.md`, find the table under **The belt**, and replace every
`TODO(belt)`:

- **Senior architect:** a person's name. This role is never an LLM.
- **Architect, Independent reviewer, General coder, Entry-level coder:** the agent's
  nickname, or the vendor and model id when the agent has no nickname. Few people give
  cute names to their partners in crime, and the protocol does not need them.
- **Trusted verifier:** the exact command or commands your gate runs, in order.
- Keep the rule that the architect and the reviewer are different models.

Two example belts:

| Role | Belt with nicknames | Belt with vendors |
|---|---|---|
| Senior architect | Lollie | Ana |
| Architect | Kuro-chan, `claude-opus-5-5` | Claude Opus 5.5 |
| Independent reviewer | Kodo-chan, `gpt-6.1-sol` | GPT 6.1 Sol |
| General coder | Lyn-chan, `glm-5.3`; Kimi-chan, `kimi-for-coding` at high effort | GLM 5.3 |
| Entry-level coder | Lyn-chan flash, `glm-5.3-flash`; Kimi-chan K2.8, `kimi-for-coding` at low effort | GLM 5.3 Flash, Claude Haiku |
| Trusted verifier | `clj-kondo`, `lein nsorg`, `lein splint`, `lein test` | `make check` |

Model names are candidate assignments, not quality rankings. Route by measured task
class and risk; see "Which LLM should do what?" in the field guide.

## Versioning

`VERSION` holds `ribbon N`. A project writes the version it was seeded from on the first
line of its `docs/README.md`. To re-seed, diff your `docs/` against the template's and
copy what changed; the protocol text in `AGENTS.md` is replaced whole.

## The reference guide

`Ribbon-Protocol-Multi-LLM-FieldGuide.pdf` at the root is the source. `docs/field-guide.md`
is its text, page for page, so a model can read it without PDF tooling. The guide is a
reusable engineering framework, not a claim that any model will follow every
instruction. Verify current model capabilities, pricing and provider terms when you
implement routing. Organisational security policy always overrides personal workflows.
