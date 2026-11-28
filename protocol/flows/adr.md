## The loop, steps 1 and 2: the design

1. **Architect.** The senior architect states the problem, the constraints, what success
   looks like and when to stop and ask; the architect resolves semantics and risk, one
   draft ADR per design problem, and brings what it cannot decide as open questions.
2. **Security review.** The architect launches a fresh security engineer for each run, at most
   three. The engineer questions the draft ADR and its diagrams, writes its report and returns
   it to the architect. The architect answers every question itself, with research and, where a
   change needs trying, its own experiments, in the current ADR or a justified linked ADR, and
   records a disposition for each finding. Only then does the architect commit the ADRs, diagrams
   and reports on the contract branch and ask the senior architect to validate the design.
   The section "Security design review" defines this checkpoint and its repeat conditions.

## Security design review

Every technical ADR passes this checkpoint before its first commit for senior-architect review.
The architect finishes the draft and diagrams first. The security engineer reviews that exact
draft in a fresh session, not the architect's own session. It advises; it never approves the ADR,
accepts residual risk, edits the design or replaces the later independent implementation reviewer.
One design, the ADRs that go to the senior architect together, gets at most three runs: a run is
one engineer's review of one snapshot, with its report revision. Until the senior architect
accepts the design, an ADR that splits, replaces or supersedes one of them for the same problem
stays inside the same runs; a later ADR that supersedes an accepted design is a new design.

### Selection and launch

The architect resolves two eligible families against the harness's available, approved models:
OpenAI GPT Sol 6.1 or newer, and Moonshot Kimi K3.1 or newer at high effort. Sol uses xhigh, or high
when xhigh is unavailable. A model alias alone is not proof of its version. When both families
are eligible, the architect makes an equal-chance coin-flip selection and records the result.
When only one is eligible, it selects that family and records why the other is unavailable.
With neither, it stops and asks the senior architect; it never silently lowers the minimum.
Each run makes a new selection and starts a fresh session; no session of an earlier run continues.

When Herdr is installed, the architect launches the engineer in a new tab in the current workspace,
without taking focus, under the Herdr overlay. If Herdr is installed but the session is not
Herdr-managed, the architect stops and asks how to proceed. Only when Herdr is absent from the
system may it use a report-writing subagent instead. This narrow fallback permits only the assigned
security report and evidence, not hidden coding or design authorship. Both routes enforce the same
access boundaries, exact-model verification and approved-provider policy. No live attack, load test,
credential access, configuration change or remote mutation is authorized by a design-review assignment.

### Review and report

The briefing names the draft ADRs, diagrams and relevant constraints; the full list of files under
the project's `docs/adrs/` and `docs/diagrams/`; the project's language, framework and `rules/`;
the reviewed snapshot; the run number and, from the second run, every earlier report with its
response; the exact provider, model and effort; and the permitted report and evidence paths. It
states facts and no opinion: no verdict on the design, no expected finding, and no area to skip or
to favour beyond the senior architect's constraints; an area that those constraints leave out is a
review limit in the report. The snapshot records each input's path and content hash, since the
draft is not yet committed. The engineer reads the supplied design and references, the other ADRs
and diagrams of the project under `docs/adrs/` and `docs/diagrams/` that bear on the design, the
project's conventions under `rules/` and the code that the design changes or builds on, never
unrelated repository trees or secrets. It names in its report each relevant input that the
briefing left out.

It checks, where applicable:

- assets, trust boundaries, entry points, attack surface and unnecessary public exposure;
- authentication, authorization, tenant isolation, least privilege and fail-closed behavior;
- token scope, expiry and revocation; key rotation and recovery; secret storage and redaction;
  cryptographically secure entropy for keys, tokens and seeds, never predictable seeds for secrets;
- injection, untrusted input, dependency and supply-chain risks, and unsafe design assumptions;
- abuse, denial of service and DDoS: request and payload limits, bounded work, concurrency, queues,
  timeouts, backpressure and deployment-layer controls; an application rate limit alone is not DDoS protection;
- sensitive-data lifecycle, auditability, safe errors and failure or recovery paths;
- anti-patterns of the project's language and framework, and those that its own conventions
  under `rules/` forbid, in the design and in the code that it builds on.

The engineer questions the architect relentlessly about these areas: every gap that the draft
leaves in them is a question, and an answer that opens a new gap gets a new question. Every
question says where to look for the answer: a reference, a standard, an ADR, a project file or a
code example, named precisely enough to find the part that applies, such as a section, a line or a
version. The engineer stays practical. It asks for the smallest change that the project can deploy
and that closes the path, never for a perfect control that the project cannot deploy. It cites a
common pattern or a best practice once, where it applies, and does not audit the design against
every practice there is. It does not hunt for nitpicks, and it may leave out one that it notices.
From the second run, it checks every earlier response against the ADR. It asks no circular
question: none that the draft answers, and none that an earlier report asked, unless the ADR does
not hold what that report's response claims; then it asks again and cites that response.

Each finding has one label, and a finding that fits two takes the higher one:

- `critical`: as designed, an attacker takes a core asset or the whole system, for example by an
  authentication bypass, remote code execution, access across tenants or an exposed secret;
- `security incident`: as designed, a realistic path leads to a breach, a leak or an outage that
  is narrower than `critical`, for example one user's data, one feature down or a lost audit trail;
- `best-practice violation`: the design departs from an established practice for its stack or
  its problem, cited once, with no exploit path shown in this design;
- `desirable`: defense in depth against a threat that the design already blocks;
- `nitpick`: wording, naming or form, with no effect on security.

The engineer writes `docs/llm-context/<adr-id>-security-r<N>.md` from `_security.md`, then reports
back and stops. Each finding has a stable id, its question, its label with a reason, an ADR or
diagram location, a concrete attack path or design-gap counterexample, impact, mitigation, where
to look and a verification condition. In place of an attack path and its impact, a `desirable`
finding names the threat that the design already blocks and what the extra control adds, and a
`nitpick` names the wording or form to change; for both, the mitigation is that control or that
change. It distinguishes a supported finding from an assumption, cites its sources, states review
limits and writes no praise. `NO_FINDINGS` means no findings in this snapshot, not proof of
safety. The report records the actual model and effort, not only the intended assignment.

### Incorporation and senior approval

The architect reads the whole report and answers every question itself; it does not ask the
senior architect what a question means or where to look. It checks each claim, follows the
engineer's pointers, and searches the project, its references and, when the harness and the
organisation's policy allow it, the internet, under the rules of "Security".

To try a proposed change before the ADR holds it, the architect writes an experiment card and
runs it itself, only under `/tmp` or `~/tmp`. Before the run, the card names the finding, the
change it tries and the result that confirms or refutes it; after the run, the command, its exit
code, its output's path and the result. The card lives in the run's report, under the architect's
response. An experiment changes nothing in the project and is not production evidence: the
plan's cards still implement the change and prove it.

The architect may revise the current ADR, or write a separate focused ADR when the extent of the
changes justifies another design decision. The ADR under review links the new ADR; the new ADR
links back. A separate ADR is not a way to postpone a required mitigation: it follows the same
security checkpoint inside the same three runs, and all ADRs needed by the design go to the
senior architect together.

The architect has the final say on what to solve and when, within one rule: in each response it
solves every `critical` and `security incident` finding that it can and escalates the others, and
it solves at least 51 percent of the report's findings other than nitpicks and escalated ones. A
finding is solved when the ADR, or a linked ADR, holds its verification condition and either a
change that closes the gap that the finding names (its path, a departure from practice, a missing
extra control or a wording) or the evidence that this gap does not exist. Any other finding that the
architect does not solve is deferred to a named later ADR or plan, with an owner, or rejected with
the reason; neither counts as solved.

The engineer's report remains intact. Under its `## Architect response`, the architect appends a
disposition for every finding: incorporated, adapted, deferred, rejected or escalated, with the
reason, the ADR section or linked ADR, its experiment cards and an owner for any remaining action,
then the count. Only a `critical` or `security incident` finding that the architect cannot solve
is escalated. The response names the constraint, the missing evidence or the reserved decision
that prevents a solution, and why each viable option does not close the path now; the finding
becomes an explicit open question of the ADR for the senior architect, with its impact and
alternatives, and needs her decision. The architect never defers it, rejects it or accepts it as a
risk. Escalation completes that finding's disposition, earns no solve credit and waives nothing
else that the response must meet; an otherwise complete response goes to the senior architect
with the design and that open question.

The architect commits the reconciled ADRs, diagrams, reports and responses on the contract branch
before asking for senior-architect review. A missing report or incomplete response stops that
request. The senior architect alone accepts the ADRs and every later edit. Before another approval
request, a security-relevant change to the design, trust boundaries, exposure or mitigations gets
the next run, a new snapshot and a new report revision; editorial-only edits do not. The third
run is the last: its findings get the architect's response under the same rules, and a
security-relevant change after it goes to the senior architect with the architect's analysis,
never to a fourth run. The architect checks that the reports cover the final security-relevant
design, including its own mitigation changes; after the third run, it names what no run covered.
A blocked run stops the checkpoint; it is not a pass, and it does not count as a run. The
architect moves its report into the run's evidence folder, and the next attempt writes the same
revision.

This design checkpoint is separate from the plan's three implementation-review cycles. Accepted
mitigations and verification conditions become ADR rules, acceptance criteria and card contracts;
coders never need to read security reports. The later reviewer still checks implementation against
those contracts. Archive the reports with the closed work under the ordinary history rules.
