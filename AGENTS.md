# Ribbon Protocol, ribbon 1

Guardrails for a multi-LLM engineering belt. Plan with intelligence. Implement with
constraints. Verify with evidence. The architect defines what must be true, the coder
makes it true inside agreed boundaries, and the harness verifies, independently, whether
it became true. Nobody grades their own work, and "tests passed" is never proof. A
project copies this file into its root `AGENTS.md` and replaces every `TODO(belt)`. The
long-form guide is `docs/field-guide.md`, the PDF as text; the schemas and the templates
live under `docs/`. The optional Herdr overlay is `herdr-config.md`, copied beside this file.
An architect inside Herdr reads it before any Herdr execution; its rules govern orchestration
only. A Claude-based project's `CLAUDE.md` includes it with `@herdr-config.md`.

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
senior architect merges on it. A plan gets at most three review cycles, the first review
and at most two over its repair cards; what the third leaves is debt or the senior architect's
disposition, never a fourth review. Recorded non-blocking debt may open the next plan on the same
code. A successor may not repeat the same blocking findings or acceptance scope as a disguised
fourth cycle; unresolved blocking work needs the senior architect's disposition. Acceptance
criteria, executable behavior, the gate and the configured linters and validators define good
enough; style-only polishing does not justify another cycle.

The coder reads the five too, and answers them first. At the plan's last card it runs
the boot itself by the entry point a person runs, keeps the command, its output and its
exit code under `docs/llm-context/evidence/<plan-id>-done/`, and writes
`docs/llm-context/<plan-id>-done.md` from `_done.md`: the five, each with its evidence,
and "the reviewer's" for the fifth. A plan whose coder cannot write the five is not ready
for review; a coder who can is done, and asks for nothing more.

The limits, by seat. The coder claims the five with evidence and stops. The reviewer
verifies the coder's five, reports every finding it can prove, classifies each, runs the
boot itself and writes the five under "Done" in the review, each with its evidence; it
never asks for a repair of a finding that breaks none of the five. The architect cuts a
repair card only for a finding that breaks one of the five, lists the rest under `debt`,
and never opens a fourth review. The senior architect decides what the third review leaves and
merges on debt; only recorded non-blocking debt may start a new plan on the same code.

## The belt

Seven roles. The senior architect is a person and never an LLM; "the architect" alone always
means the LLM seat, so neither a coder nor a reviewer confuses the two. The other roles are
LLMs, named by a nickname or by a vendor and a model id, except the trusted verifier, which is tools.

| Role | Agent | Model | Writes | Never |
|---|---|---|---|---|
| Senior architect | TODO(belt): a person's name | human | the problem, the constraints, what success looks like, the acceptance criteria or test bodies; validates ADRs and plans | reads code line by line |
| Architect | TODO(belt): "Kuro-chan" or "Claude Opus" | TODO(belt): claude-opus-5-5 | ADRs, plans, cards, answers to notes | directly editing production code for its own card; a Herdr post-budget solution is contract text applied and verified by the coder |
| Security engineer | a fresh agent selected by the architect | OpenAI GPT Sol 6.1+ or Moonshot Kimi K3.1+; Kimi at high effort | an ADR security report with findings and mitigations | ADRs, code, commits; accepting risk for the senior architect |
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
   draft ADR per design problem, and brings what it cannot decide as open questions.
2. **Security review.** The architect launches a fresh security engineer. The engineer
   reviews the draft ADR and its diagrams, writes its report and returns it to the architect.
   The architect incorporates the findings, in the current ADR or a justified linked ADR,
   and records a disposition for each finding. Only then does the architect commit the ADRs,
   diagrams and report on the contract branch and ask the senior architect to validate the design.
   The section "Security design review" defines this checkpoint and its repeat conditions.
3. **Contract.** The architect cuts the design into one plan (one deliverable, one
   branch) and its cards (one green commit each), in dependency order, never while an
   ADR they rest on is unaccepted or has a pending open question; the senior architect validates
   the plan. The design and contract steps happen on the story's contract branch, merged into
   `main` at validation ("The branches").
4. **Execute.** One coder runs the plan, card by card, inside each card's scope, and
   leaves evidence on disk after every card. Under the Herdr overlay, several visible coders
   may execute independent cards in parallel only with exclusive file ownership.
5. **Verify.** The gate runs outside the coder's control; the reviewer reads the commit
   range against the plan and the cards; the senior architect reads verdicts, not diffs.
   The plan is done by the five of "Done, and when the loop stops" above, never by a
   round that finds nothing.

## Security design review

Every technical ADR passes this checkpoint before its first commit for senior-architect review.
The architect finishes the draft and diagrams first. The security engineer reviews that exact
draft in a fresh session, not the architect's own session. It advises; it never approves the ADR,
accepts residual risk, edits the design or replaces the later independent implementation reviewer.

### Selection and launch

The architect resolves two eligible families against the harness's available, approved models:
OpenAI GPT Sol 6.1 or newer, and Moonshot Kimi K3.1 or newer at high effort. Sol uses xhigh, or high
when xhigh is unavailable. A model alias alone is not proof of its version. When both families
are eligible, the architect makes an equal-chance coin-flip selection and records the result.
When only one is eligible, it selects that family and records why the other is unavailable.
With neither, it stops and asks the senior architect; it never silently lowers the minimum.

When Herdr is installed, the architect launches the engineer in a new tab in the current workspace,
without taking focus, under `herdr-config.md`. If Herdr is installed but the session is not
Herdr-managed, the architect stops and asks how to proceed. Only when Herdr is absent from the
system may it use a report-writing subagent instead. This narrow fallback permits only the assigned
security report and evidence, not hidden coding or design authorship. Both routes enforce the same
access boundaries, exact-model verification and approved-provider policy. No live attack, load test,
credential access, configuration change or remote mutation is authorized by a design-review assignment.

### Review and report

The briefing names the draft ADRs, diagrams and relevant constraints; the reviewed snapshot;
the exact provider, model and effort; and the permitted report and evidence paths. The snapshot
records each input's path and content hash, since the draft is not yet committed. The engineer
reads the supplied design and references, not unrelated repository trees or secrets.

It checks, where applicable:

- assets, trust boundaries, entry points, attack surface and unnecessary public exposure;
- authentication, authorization, tenant isolation, least privilege and fail-closed behavior;
- token scope, expiry and revocation; key rotation and recovery; secret storage and redaction;
  cryptographically secure entropy for keys, tokens and seeds, never predictable seeds for secrets;
- injection, untrusted input, dependency and supply-chain risks, and unsafe design assumptions;
- abuse, denial of service and DDoS: request and payload limits, bounded work, concurrency, queues,
  timeouts, backpressure and deployment-layer controls; an application rate limit alone is not DDoS protection;
- sensitive-data lifecycle, auditability, safe errors and failure or recovery paths.

The engineer writes `docs/llm-context/<adr-id>-security-r<N>.md` from `_security.md`, then reports
back and stops. Each finding has a stable id, severity with a reason, an ADR or diagram location,
a concrete attack path or design-gap counterexample, impact, mitigation and a verification condition.
It distinguishes a supported finding from an assumption or open question, cites its sources, states
review limits and writes no praise. `NO_FINDINGS` means no findings in this snapshot, not proof of safety.
The report records the actual model and effort, not only the intended assignment.

### Incorporation and senior approval

The architect reads the whole report, checks its claims and incorporates applicable suggestions.
It may revise the current ADR, or write a separate focused ADR when the extent of the changes
justifies another design decision. The ADR under review links the new ADR; the new ADR links back.
A separate ADR is not a way to postpone a required mitigation: it follows the same security
checkpoint, and all ADRs needed by the design go to the senior architect together.

The engineer's report remains intact. Under its `## Architect response`, the architect appends a
disposition for every finding: incorporated, adapted, deferred or rejected, with the reason,
the ADR section or linked ADR, and an owner for any remaining action. Serious unresolved risks
are explicit open questions for the senior architect, never silently accepted or converted to debt.
Any proposed risk acceptance names the impact and alternatives and needs her explicit decision.

The architect commits the reconciled ADRs, diagrams, report and response on the contract branch
before asking for senior-architect review. A missing report or incomplete response stops that
request. The senior architect alone accepts the ADRs and every later edit. Before another approval
request, a security-relevant change to the design, trust boundaries, exposure or mitigations gets
another security pass, a new snapshot and a new report revision; editorial-only edits do not.
The architect checks that the report covers the final security-relevant design, including its own
mitigation changes. A blocked review stops the checkpoint; it is not a pass.

This design checkpoint is separate from the plan's three implementation-review cycles. Accepted
mitigations and verification conditions become ADR rules, acceptance criteria and card contracts;
coders never need to read security reports. The later reviewer still checks implementation against
those contracts. Archive the reports with the closed work under the ordinary history rules.

## The branches

Every story has a short prefix, and every branch of the story starts with it (`quiz/` in the
examples below). The main branch takes merges only, and each merge is a state the senior
architect validated, so the history of `main` reads as a list of decisions.

- **The contract branch, `<prefix>/adr-plan-cards`.** The architect writes the story's
  contract there: its ADRs and diagrams, its plans, acceptance files and cards, its
  decision-log entries, and the architect's own records (a journal, an orchestration
  report). The senior architect reviews the branch, by a compare view or a pull request,
  and answers there.
- **The merge.** When the senior architect accepts the ADRs and validates a plan, the
  architect merges the contract branch into `main` with `git merge --no-ff`. A coder
  starts only after that merge.
- **A plan's branch, `<prefix>/<plan slug>`** (for example `quiz/scoring-p1`), named in the
  plan's `branch` field, starts from `main` after the merge. The coder works there, and the
  reviewer reads its range.
- **A revision during execution** (a repair card, an answer to a note, a timed-out
  decision) is a commit on the contract branch, merged into `main` before the coder is
  told. The coder never edits the architect's paths, so these merges never conflict with
  the plan's branch.
- **Work outside a story** (a protocol port, a tooling change) takes its own short branch,
  `<topic>/<slug>`, under the same rule: reviewed there, merged into `main` when accepted.
- **Parallel and unrelated work stays apart:** two stories never share a branch, and a
  plan's branch never carries the architect's records.

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
| `docs/llm-context/` | the architect, the security engineer, the coders, the reviewer | `<adr-id>-security-r<N>.md` by the security engineer, with the architect's appended response; `<task-id>-report.md` per card; `<task-id>-<slug>.md` on a block or a question; `<plan-id>-handoff.md`, five lines, rewritten each session; `<plan-id>-done.md`, the coder's five of "Done" at the plan's last card; `<plan-id>-review.md` by the reviewer; `<plan-id>-orchestration.md` by a Herdr architect |

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

## A plan and its cards

A plan is a story: one deliverable, one branch, one coder by default, one architect, one
reviewer, and under `decisions` the decision-log entries that bind it, which the coder reads and
no other. Only the Herdr overlay may assign several coders, under its exclusive-ownership rule.
A card is the smallest change that ends in a green commit. At session start the coder loads its
assigned rows of the plan's `tasks` verbatim into its todo tool, in order, and marks each card as
it goes; outside Herdr, its assignment is the whole plan. It never adds an item, since a step the
plan does not list is a question. `<plan-id>.acceptance.yaml` names every acceptance test before
any code (the name, the input, the expected output, the card that implements it); the coder implements
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
   architect or the senior architect revises a card. The sole exception to "no edit" is the
   Herdr overlay's single mechanical application of the architect's complete solution after the
   repair budget is spent; every other stop line still applies.
6. **Report.** The completion block of `_report.md`: changed files, verified invariants,
   each check with its command, exit code and artifact, the repair count, the failure
   class, the risks, the next owner, and `PASS`, `BLOCKED` or `ESCALATED`.
7. **Commit and continue.** One code commit per card after its preflight commit, the
   task id first in the message, the report inside it; then the next card, and at the end
   of the session the handoff; at the plan's last card, the boot and `<plan-id>-done.md`.

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
as `APPROVE` with debt. The review names its cycle, the previous review and the repair range;
cycle 3 is terminal.

## Security

Approved providers only. Never copy proprietary code, credentials or customer data into a
personal agent, a prompt or a note. The organisation's security policy overrides this
protocol wherever the two differ.
