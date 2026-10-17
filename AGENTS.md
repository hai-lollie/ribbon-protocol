# Ribbon Protocol, ribbon 1

Guardrails for a multi-LLM engineering belt. Plan with intelligence. Implement with
constraints. Verify with evidence.

The architect defines what must be true. The coder chooses how to make it true, inside
agreed boundaries. The harness verifies, independently, whether it became true. Nobody
grades their own work, and a sentence that says "tests passed" is never proof.

This file is the protocol. A project copies it into its root `AGENTS.md` and fills the
belt below. The long-form guide is `docs/field-guide.md`; the PDF at the root of the
template is the reference. The schemas and the templates live under `docs/`.

## The belt

Six roles. Fill the Agent and Model columns for your project: every `TODO(belt)` below
is an example to replace. The senior architect is a person. The others are LLMs, named
by a nickname or by a vendor and a model id.

| Role | Agent | Model | Writes | Never |
|---|---|---|---|---|
| Senior architect | TODO(belt): a person's name | human | the problem, the constraints, what success looks like, the acceptance criteria or test bodies; validates ADRs and plans | reads code line by line |
| Architect | TODO(belt): "Kuro-chan" or "Claude Opus" | TODO(belt): claude-opus-5-5 | ADRs, plans, cards, answers to notes | production code for its own card |
| Independent reviewer | TODO(belt): "Kodo-chan" or "GPT Sol" | TODO(belt): gpt-6.1-sol | findings and verdicts | code; a review of a plan it architected |
| General coder | TODO(belt): "Lyn-chan" or "GLM 5.3" | TODO(belt): glm-5.3 | the patch and its evidence, inside scope | a shape the contract does not define; a protected path |
| Entry-level coder | TODO(belt): "Lyn-chan flash" or "GLM 5.3 Flash" | TODO(belt): glm-5.3-flash | small patches inside the allowlist | a correctness decision |
| Trusted verifier | the gate: TODO(belt): the exact commands | tools | machine PASS or FAIL | trust a sentence |

Rules of the belt:

- The architect and the reviewer of one plan are different models, from different
  vendors when possible. They may swap roles between plans. Every plan names both.
- A coder reads its plan and its cards. What the architect left undecided is a note
  for the architect, not a guess.
- Route by task class and risk, never by price alone. Low ambiguity and a small blast
  radius: the entry-level coder. Multi-file work on known interfaces: the general
  coder. Ambiguous correctness or risky architecture: the architect, before any code.

## The loop

Four beats, in order, for every plan.

1. **Architect.** The senior architect states the problem, the constraints, what success
   looks like, and when to stop and ask. The architect resolves semantics and risk and
   writes one ADR per design problem. The senior architect validates the ADRs.
2. **Contract.** The architect turns the validated design into one plan (a story: one
   deliverable, one branch) and its cards (one card: one green commit), in dependency
   order. The senior architect validates the plan.
3. **Execute.** One coder runs the whole plan, card by card, inside each card's scope,
   and leaves evidence on disk after every card.
4. **Verify.** The gate runs outside the coder's control. The reviewer reads the commit
   range against the plan and the cards and writes findings. The senior architect reads
   the verdicts, not the diff.

## The decision budget

The architect decides semantics, failure modes, public interfaces, invariants and
compatibility. The coder decides local naming, formatting, minor decomposition and
implementation mechanics inside those bounds.

The pre-flight question for the architect: if the coder would have to invent a domain
policy, design an abstraction, or decide the correctness criteria, the task is still a
planning task. Keep it.

## The homes

| Path | Who writes | What |
|---|---|---|
| `docs/` | the architects | most of the project's prose |
| `docs/adrs/` | the architect | one ADR per design problem, markdown, under 2000 characters; the senior architect validates |
| `docs/diagrams/` | the architect | `<adr-id>-<diagram-name>.mmd` (mermaid); `.puml` only when mermaid cannot draw it |
| `docs/tasks/` | the architect | `<plan-id>.plan.yaml` and its cards `<plan-id>-NN.yaml` |
| `docs/llm-context/` | the coders, the reviewer | `<task-id>-report.md` for every card; `<task-id>-<slug>.md` on a block, a misleading card or a question; `<plan-id>-handoff.md` at the end of every session; `<plan-id>-review.md` by the reviewer |

Ids are lowercase everywhere: file names, prose, commit messages. A YAML line is at most
150 characters: fold a longer string with `>-`. A coder never edits `docs/adrs/`,
`docs/diagrams/` or `docs/tasks/`. Only the architect revises a card, and bumps its
`revision` when it does.

## A plan and its cards

A plan is a story: one deliverable, one branch, one coder, one architect, one reviewer.
A card is the smallest change that ends in a green commit. The plan lists its cards in
execution order. At session start the coder loads that list verbatim into its todo tool,
one item per card, and marks each card as it goes, so the senior architect sees where
the coder is without asking. The coder never adds an item: a step the plan does not
list is a question, not a todo.

The schemas, every field explained, are `docs/tasks/README.md`,
`docs/tasks/_template.plan.yaml` and `docs/tasks/_template.task.yaml`. A card carries
the objective and what is out of scope; the verified context (files, signatures,
patterns); the preconditions; the behaviour matrix (given, expect) and the invariants;
the decisions the architect owns and the ones left to the coder; the scope (writable,
protected, forbidden); the verification commands; the stop lines; the repair budget;
and what completion means.

## The coder's seven steps, per card

1. **Preflight, read only.** Read `context.read_first`. Check every precondition and
   every line of `context.verified` against the files. Run the baseline command. Write
   the preflight block of the report: `READY` with the evidence, or `BLOCKED` with the
   missing facts. Never fill in a precondition.
2. **Authorize.** Proceed only when the preflight says `READY`.
3. **Implement.** The smallest change inside `scope.writable`, in the way the project's
   own rules ask (test first where they say so).
4. **Verify.** The targeted command, then the gate. Keep the actual output.
5. **Repair or escalate.** A mechanical failure gets a focused repair, at most
   `repair_budget` times. A semantic failure (an ambiguous behaviour, a fixture that
   disagrees with the contract, a missing API) is escalated at once.
6. **Report.** The completion block: changed files, verified invariants, each check with
   its command, exit code and artifact, the repair count, the failure class, the
   unresolved risks, the next owner, and the status `PASS`, `BLOCKED` or `ESCALATED`.
7. **Commit and continue.** One commit per card, its message starting with the task id,
   the report inside it. Then the next card. At the end of the session, the handoff.

## Stop the line

The coder stops, writes a note, and makes no edit when:

- a precondition cannot be verified;
- correctness needs an edit outside `scope.writable`;
- a protected path or a forbidden change is required;
- the contract is silent on a shape, a policy or a failure mode the card must answer;
- a semantic failure persists after one repair, or the repair budget is spent;
- an API, a signature or a file the card names does not exist.

`BLOCKED` is progress. An invented answer is not. Only the architect or the senior
architect revises a card.

## The reviewer's brief

The reviewer reads the plan, its cards, the reports, the ADRs and the branch's commit
range, and writes `docs/llm-context/<plan-id>-review.md`: one verdict per card and one
for the plan, `APPROVE`, `CHANGES` or `ESCALATE`, every finding with a counterexample or
a concrete path, never praise. The reviewer never edits code, never regenerates a
fixture, and never reviews a plan it architected. `CHANGES` means the architect cuts
repair cards with the next numbers.

## Evidence

Proof is a command, its exit code and its output, on disk. A report, a note, a handoff
and a review are files in `docs/llm-context/`, committed with the work. Nothing an LLM
decided lives only in its context window.

## Security

Use approved providers only. Never copy proprietary code, credentials or customer data
into a personal agent, a prompt or a note. The organisation's security policy overrides
this protocol wherever the two differ.
