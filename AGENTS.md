# Ribbon Protocol, ribbon 1

Guardrails for a multi-LLM engineering belt. Plan with intelligence. Implement with
constraints. Verify with evidence. The architect defines what must be true, the coder
makes it true inside agreed boundaries, and the harness verifies, independently, whether
it became true. Nobody grades their own work, and "tests passed" is never proof. A
project copies this file into its root `AGENTS.md` and replaces every `TODO(belt)`. The
long-form guide is `docs/field-guide.md`, the PDF as text; the schemas and the templates
live under `docs/`.

## The belt

Six roles. The senior architect is a person and never an LLM; "the architect" alone always
means the LLM seat, so neither a coder nor a reviewer confuses the two. The other roles are
LLMs, named by a nickname or by a vendor and a model id.

| Role | Agent | Model | Writes | Never |
|---|---|---|---|---|
| Senior architect | TODO(belt): a person's name | human | the problem, the constraints, what success looks like, the acceptance criteria or test bodies; validates ADRs and plans | reads code line by line |
| Architect | TODO(belt): "Kuro-chan" or "Claude Opus" | TODO(belt): claude-opus-5-5 | ADRs, plans, cards, answers to notes | production code for its own card |
| Independent reviewer | TODO(belt): "Kodo-chan" or "GPT Sol" | TODO(belt): gpt-6.1-sol | findings and verdicts | code; a review of a plan it architected |
| General coder | TODO(belt): "Lyn-chan" or "GLM 5.3" | TODO(belt): glm-5.3 | the patch and its evidence, inside scope | a shape the contract does not define; a protected path |
| Entry-level coder | TODO(belt): "Lyn-chan flash" or "GLM 5.3 Flash" | TODO(belt): glm-5.3-flash | small patches inside the allowlist | a correctness decision |
| Trusted verifier | the gate: TODO(belt): the exact commands | tools | machine PASS or FAIL | trust a sentence |

- The architect and the reviewer of one plan are different models, from different
  vendors when possible; they may swap roles between plans, and every plan names both.
- A coder reads its plan, its cards, and what they name: the root `AGENTS.md` once per
  session, the five-line handoff, the decision-log entries under the plan's `decisions`,
  each card's `read_first`; nothing else before the first edit, and never a report, a
  note, a review or a journal. What the architect left undecided is a note for the
  architect, not a guess; what the card's rules and the file answer together is the
  coder's decision, written in the report.
- Route by task class and risk, never by price: the entry-level coder for low ambiguity
  and a small blast radius, the general coder for multi-file work on known interfaces,
  the architect, before any code, for ambiguous correctness or risky architecture.

## The loop

1. **Architect.** The senior architect states the problem, the constraints, what success
   looks like and when to stop and ask; the architect resolves semantics and risk, one
   ADR per design problem, and brings what it cannot decide as open questions; the
   senior architect validates the ADRs and their answers.
2. **Contract.** The architect cuts the design into one plan (one deliverable, one
   branch) and its cards (one green commit each), in dependency order, never while an
   ADR they rest on has a pending open question; the senior architect validates the plan.
3. **Execute.** One coder runs the plan, card by card, inside each card's scope, and
   leaves evidence on disk after every card.
4. **Verify.** The gate runs outside the coder's control; the reviewer reads the commit
   range against the plan and the cards; the senior architect reads verdicts, not diffs.
   The plan is done by the five of "Done, and when the loop stops", never by a round
   that finds nothing.

## The decision budget

The architect decides semantics, failure modes, public interfaces, invariants and
compatibility; the coder decides local naming, formatting, minor decomposition and
mechanics inside those bounds. If the coder would have to invent a domain policy, design
an abstraction, decide the correctness criteria, or read a tree to classify its files,
the task is still a planning task: keep it. A card that moves, splits or reshapes many
files lists every file and its destination under `moves`, and the coder moves them. A
card never sends the coder to a report, a note or a journal: what it needs from one, the
architect copies into `context.verified`.

## The homes

| Path | Who writes | What |
|---|---|---|
| `docs/` | the architects | most of the project's prose |
| `docs/adrs/` | the architect | one ADR per design problem: markdown of 1000 to 4500 words in Simplified Technical English, the ten sections of `docs/adrs/README.md` in order and none empty, its diagrams embedded, no plan while an open question is pending; the senior architect validates, and again after every edit |
| `docs/diagrams/` | the architect | `<adr-id>-<diagram-name>.mmd` (mermaid): a flow is a sequence diagram with `alt` paths and notes that carry the call or the schema; another kind only when the idea is not a flow; `.puml` only when mermaid cannot draw it |
| `docs/tasks/` | the architect | `<plan-id>.plan.yaml` and its cards `<story-id>-NN.yaml`; a story larger than one review is phase plans, `<story-id>-pN.plan.yaml` |
| the decision log (`CHANGELOG.md`) | the architect | one entry per decision or regroup; the newest ten in full, every older one three lines under 200 characters (`What:`, `Why:`, `Now:`), compressed by the commit that appends the eleventh |
| `docs/llm-context/` | the coders, the reviewer | `<task-id>-report.md` per card; `<task-id>-<slug>.md` on a block or a question; `<plan-id>-handoff.md`, five lines, rewritten each session; `<plan-id>-review.md` by the reviewer |

Ids are lowercase everywhere; a YAML line is at most 150 characters, folded with `>-`. A
coder never edits `docs/adrs/`, `docs/diagrams/` or `docs/tasks/`. Only the architect
revises a card and bumps its `revision`, on the main branch: a coder whose branch has
diverged reads it there (`git show main:docs/tasks/<task-id>.yaml`) and rebases only
when the architect says so, after a gate. Proof is a command, its exit code and its
output, on disk under `docs/llm-context/`, committed with the work; nothing an LLM
decided lives only in its context window. After the commit, the architect appends the
card's measured cost to its report from the harness's own records, the model, the effort
and the tokens as they ran, never retyped.
`docs/llm-context/history/` holds what no live plan reads: the journals of closed work,
outside reviews, comparisons, and the reports, notes, handoff and review of a plan once
it merges or is abandoned. The architect moves them there with `git mv` at every
clean-up, in one commit with the references that name them, so the listing a coder sees
holds the templates, the README and the live plan's files.

## A plan and its cards

A plan is a story: one deliverable, one branch, one coder, one architect, one reviewer,
and under `decisions` the decision-log entries that bind it, which the coder reads and
no other. A card is the smallest change that ends in a green commit. At session start
the coder loads the plan's `tasks` verbatim into its todo tool, in order, and marks each
card as it goes; it never adds an item, since a step the plan does not list is a
question. `<plan-id>.acceptance.yaml` names every acceptance test before any code (the
name, the input, the expected output, the card that implements it); the coder implements
it name for name, and the reviewer checks against it. The schemas, every field explained,
are `docs/tasks/README.md` and the two `_template` files.

A session is as many cards as the coder's window holds with the card still in context;
the senior architect names that number per coder, one at 256K tokens or less. The
handoff bridges sessions in five lines, rewritten each session: the next session reloads
the plan and its card, not the history, which is in git.

A story larger than one review is cut into phases, each a plan with its own branch,
review and handoff: a phase stays `proposed` until the plan under `after` is `done`, and
merging is optional at every APPROVE, since every phase is a deliverable on its own,
green and whole, its `title`, `story` and `success` the pull request's title and body.
Every card carries `size`, the architect's estimate of its inserted lines under one unit
(`git diff -M -I'^\(ns ' --shortstat`, no markdown, no `docs/llm-context`); a phase is
400 to 900 lines, 400 the target, under 400 joined, over 900 split and recut until each
half is a story. The rules are `docs/tasks/README.md`, "The phases of a story".

## The coder's seven steps, per card

1. **Preflight, read only.** Read `context.read_first` in order and nothing else before
   the first edit (a line names a file, with a section or a line range when it is long);
   check every precondition and every line of `context.verified` against the files; run
   the baseline; write the preflight block, `READY` with the evidence or `BLOCKED` with
   the missing facts. Never fill in a precondition. Commit the block alone,
   `<task-id>: preflight READY` or `BLOCKED`, before the first edit: git proves the
   order, and a block written after the edits proves nothing.
2. **Authorize.** Proceed only on `READY`, the preflight commit in the log.
3. **Implement.** The smallest change inside `scope.writable`, as the project's rules ask
   (test first where they say so), reading what the change touches. Source is edited
   with the tools the root `AGENTS.md` names per language, one file at a time, never with
   a text-munging script; when a required tool fails, the coder stops and says where
   (step 5), and does not fall back to another writer (TODO(belt)). A probe is a command
   or an evaluation, never a file written into the tree.
4. **Verify.** The targeted command, the gate, then the whole suite: everything green
   stays green. A new test comes from the acceptance file or the behaviour rows, never
   from the implementation's output. Every command's output goes to a file the report
   names; the coder reads its last lines and greps the words the gate forbids. Output is
   evidence on disk, never context.
5. **Repair, or stop the line.** A mechanical failure gets a focused repair, at most
   `repair_budget` times. The coder stops, writes a note, and makes no edit when: a
   precondition cannot be verified; correctness needs an edit outside `scope.writable`,
   a protected path or a forbidden change; the contract is silent on a shape, a policy
   or a failure mode the card must answer; a semantic failure (an ambiguous behaviour, a
   fixture against the contract, a missing API) appears, or persists after one repair,
   or the budget is spent; a file, an API or a signature the card names does not exist and
   its absence changes the meaning; a required tool fails. A doubt the card's rules and
   the file answer together (a home a layer table gives, a schema for an argument that
   exists) is the coder's: decided, written under `decisions` in the report with the rule
   it followed, reviewed there. `BLOCKED` is progress; an invented answer is not. Only the
   architect or the senior architect revises a card.
6. **Report.** The completion block of `_report.md`: changed files, verified invariants,
   each check with its command, exit code and artifact, the repair count, the failure
   class, the risks, the next owner, and `PASS`, `BLOCKED` or `ESCALATED`.
7. **Commit and continue.** One code commit per card after its preflight commit, the
   task id first in the message, the report inside it; then the next card, and at the end
   of the session the handoff.

## The reviewer's brief

The reviewer reads the plan, its cards, the reports, the ADRs and the commit range, and
writes `docs/llm-context/<plan-id>-review.md`: a verdict per card and one for the plan
(`APPROVE`, `CHANGES` or `ESCALATE`), every finding with a counterexample or a concrete
path, never praise; a test that restates its implementation is a finding. The plan's
verdict measures the range with the unit against the cards' `size`, a measure over 900 a
finding of class SIZE on the plan and never on the coder, and says in one line whether
the plan is a deliverable on its own. Coverage: every new namespace at or above 95
percent of lines and the project total not lower, with what the measure excludes named
in the plan at validation (a process entry, a socket bind, a line no test may reach under
the plan's own invariants); an exclusion found later is a regroup by the architect, never
a lowered number. The reviewer never edits code, never regenerates a fixture, never
reviews a plan it architected. The reviewer runs the boot itself and writes the five of
"Done, and when the loop stops" in the review, each with its evidence. `CHANGES` means
the architect cuts repair cards with the next numbers for the findings that break one of
the five, and lists the rest under `debt`; a `CHANGES` whose findings are all debt reads
as `APPROVE` with debt.

## Done, and when the loop stops

A review finds something every round, so the loop converges by a rule, never by a round
that finds nothing; the deliverable is a working product, not a perfect one. A plan is
done when five things hold on its head, each proven by a command, its exit code and its
output on disk, never by a sentence:

1. the gate is green locally and on the trusted verifier;
2. the application boots by its documented entry point, the one a person runs (a binary,
   a `main`, a service command), answers its smoke check and stops, on a clean checkout;
   a suite that starts the system in-process does not count as the boot;
3. every test of the plan's acceptance file passes under its canonical name;
4. coverage meets the plan's line;
5. no open finding is `SEMANTIC` or `SCOPE` against production code: the behaviour, the
   contract, the public interfaces.

Every other open finding, the strength of a test, a test's lifecycle, a record, the
process, goes under `debt` in the plan: the finding id, one line, the next owner. A
`CHANGES` verdict whose findings are all debt reads as `APPROVE` with debt, and the
senior architect merges on it. A plan gets at most two review rounds, the first review
and one over its repair cards; what the second leaves is debt or the senior architect's
disposition, never a third round. Debt opens the next plan on the same code as its first
cards, reviewed with that plan.

The limits, by seat. The reviewer reports every finding it can prove, classifies each,
runs the boot itself and writes the five under "Done" in the review, each with its
evidence; it never asks for a repair of a finding that breaks none of the five. The
architect cuts a repair card only for a finding that breaks one of the five, lists the
rest under `debt`, and never opens a third round. The senior architect decides what the
second round leaves, merges on debt, and is the only seat that can ask for more.

## Security

Approved providers only. Never copy proprietary code, credentials or customer data into a
personal agent, a prompt or a note. The organisation's security policy overrides this
protocol wherever the two differ.
