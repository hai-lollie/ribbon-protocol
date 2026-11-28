# <adr-id> security design review, r<N>

ADR: <path and title; list the other ADRs of this design in this review>
Run and report revision: <N, from 1 to 3; the third run is the last>
Earlier reports read: <each path with its architect response, or none: first run>
Security engineer: <agent and fresh session id>
Actual provider/model/effort: <from the verified harness record, not a footer or alias>
First assistant message verification: <session/message id and evidence path>
Date: <YYYY-MM-DD HH:MM, with timezone>
Outcome: <FINDINGS | NO_FINDINGS | BLOCKED>

This report advises the architect. It does not approve the ADR or accept residual risk. The
engineer writes the report and returns to the architect, then stops without a commit. No praise.
After handback, preserve the engineer's sections; only the architect appends the response below.

## Assignment and boundaries

- Selection: <eligible approved Sol 6.1+ and Kimi K3.1+ models; this run's coin-flip result, or why only one qualified>
- Effort: <Sol xhigh, or high if unavailable; Kimi high>
- Launch: <Herdr workspace/tab/pane and agent ids, a new tab and session for this run; subagent only if Herdr is absent from the system>
- Briefing and selection evidence: <delivery id and evidence paths>
- Read access: <named ADRs, diagrams, constraints and references; the project's `rules/` and the code that the design changes or builds on; no unrelated trees or secrets>
- Write access: <this report and the exact evidence allowlist>
- Permission enforcement: <mechanism, or prompt-only limitation and compensating controls>
- Baseline and post-review scope comparison: <evidence paths; the architect records the result in its response>
- Prohibited: design/code/test edits, commits, live attacks, load tests, credential access and remote mutations.

## Reviewed snapshot

The draft is not yet committed. Record every reviewed design input's path and SHA-256 content hash.
Do not substitute a branch name or an earlier commit for these draft identities.

| Input path | SHA-256 | Relevant sections or purpose |
|---|---|---|
| <ADR or diagram path> | <hash> | <sections> |

Constraints and references reviewed: <paths, sections and source links; the language, framework and `rules/` files read>

## Coverage and limits

For each area, state what the design specifies, the gap found, or why it does not apply. Do not
invent deployment facts or treat an absent control as implemented.

| Area | Design evidence, gap, or justified non-applicability |
|---|---|
| Assets, trust boundaries, entry points and unnecessary exposure | <evidence> |
| Authentication, authorization, isolation, least privilege and fail-closed behavior | <evidence> |
| Token scope/expiry/revocation, key rotation/recovery, secret storage/redaction and secure entropy | <evidence> |
| Untrusted input, injection, dependencies and supply-chain assumptions | <evidence> |
| Abuse, DoS/DDoS, payload/work/concurrency limits, timeouts, queues and deployment controls | <evidence> |
| Sensitive-data lifecycle, audit, safe errors and recovery | <evidence> |
| Anti-patterns of the language, framework and `rules/`, in the design and the code it builds on | <evidence> |

Unverified assumptions, unavailable inputs and review limits: <explicit list, or none>
`NO_FINDINGS` means no findings in this snapshot, not proof of safety. Use `BLOCKED` when required
inputs or model verification are missing; it does not complete the checkpoint or count as a run.

## Findings

Repeat this subsection for each finding, with stable ids across runs: a later run continues the
numbering. Each finding is a question to the architect, as AGENTS.md, "Review and report", asks.
With no findings, write `None in the reviewed snapshot` and retain the coverage and limits above.

### <adr-id>-sec-01: <the question to the architect, in one sentence>

- Label and reason: <critical | security incident | best-practice violation | desirable | nitpick; why this label>
- Location: <ADR section or diagram participant/message>
- Attack path or counterexample: <actor, access/preconditions, action and violated boundary or invariant>
- Impact: <asset, unauthorized capability, availability loss or design consequence>
- Mitigation: <the smallest change that the project can deploy and that closes the path>
- Where to look: <references, standards, ADRs, project files or code examples that answer the question>
- Verification condition: <observable acceptance condition that can enter a plan/card>
- Evidence and sources: <design excerpt or concrete omission; a common pattern or a best practice is cited once>
- Earlier run: <the earlier finding and response that this question follows up, and what the ADR lacks; or none>
- Assumptions: <what must be confirmed, or none>

## Learnings

Record additional learnings from the reviewed snapshot for the architect, with sources and
limits. Keep design gaps under Findings. Write `None` if there are no additional learnings.
Leave persistent memory unchanged.

## Handback

Report returned to architect: <message id and timestamp>
Unresolved questions about the assignment: <ids and questions, or none>
Engineer stopped: <timestamp; no further edits or commit>

## Architect response

Architect-only append after the engineer stops. Account for every finding without rewriting it.
The architect answers every question itself, as AGENTS.md, "Incorporation and senior approval",
asks. Solve findings in the current ADR or justified focused, reciprocally linked ADRs. New
technical ADRs pass the same security checkpoint inside the same three runs and go to senior
review with the design.

| Finding | Label | Disposition | Solved | Reason | ADR section or linked ADR | Experiment cards | Remaining action and owner |
|---|---|---|---|---|---|---|---|
| <adr-id>-sec-01 | <label> | <incorporated/adapted/deferred/rejected; choose one> | <yes: the ADR holds the change that closes the path, or the evidence that the path does not exist, and the verification condition; or no> | <reason> | <link and section> | <ids, or none> | <action and owner, or none; deferred: the named later ADR or plan> |

Count: <solved critical and security incident findings, of their total: every one>;
<solved findings other than nitpicks, of their total: at least 51 percent>

- Actual model verification and report-only scope check: <commands/records, results and evidence paths>
- Final design coverage: <this run covers the security-relevant design; or the next run; after the third run, what no run covered>
- Unsolved critical or security incident findings: <the ADR open questions for the senior architect, with impact and alternatives; or none>
- Senior-review bundle: <reconciled ADRs, diagrams, reports and responses; commit on the contract branch before asking for review>
- Follow-through: <accepted mitigations and verification conditions to carry into acceptance criteria and card contracts>

### Experiment card <adr-id>-experiment-01

Repeat for each experiment, numbered across runs. The architect writes the first four lines
before the run, runs it itself only under `/tmp` or `~/tmp`, and changes nothing in the project.

- Finding: <adr-id>-sec-NN
- Change it tries: <the change>
- Confirms when: <the observable result, written before the run>
- Refutes when: <the observable result, written before the run>
- Scratch root and command: <the `/tmp` or `~/tmp` folder; the exact command>
- Exit code and output: <the exit code; the output's evidence path>
- Result: <confirms | refutes | inconclusive; what the output shows; not production evidence>
