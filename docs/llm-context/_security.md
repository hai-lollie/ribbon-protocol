# <adr-id> security design review, r<N>

ADR: <path and title; list related ADRs in this review>
Report revision: <N, starting at 1>
Previous report: <path, or none>
Security engineer: <agent and fresh session id>
Actual provider/model/effort: <from the verified harness record, not a footer or alias>
First assistant message verification: <session/message id and evidence path>
Date: <YYYY-MM-DD HH:MM, with timezone>
Outcome: <FINDINGS | NO_FINDINGS | BLOCKED>

This report advises the architect. It does not approve the ADR or accept residual risk. The
engineer writes the report and returns to the architect, then stops without a commit. No praise.
After handback, preserve the engineer's sections; only the architect appends the response below.

## Assignment and boundaries

- Selection: <eligible approved Sol 6.1+ and Kimi K3.1+ models; coin-flip result, or why only one qualified>
- Effort: <Sol xhigh, or high if unavailable; Kimi high>
- Launch: <Herdr workspace/tab/pane and agent ids; subagent only if Herdr is absent from the system>
- Briefing and selection evidence: <delivery id and evidence paths>
- Read access: <named ADRs, diagrams, constraints and references; no unrelated trees or secrets>
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

Constraints and references reviewed: <paths, sections and source links>

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

Unverified assumptions, unavailable inputs and review limits: <explicit list, or none>
`NO_FINDINGS` means no findings in this snapshot, not proof of safety. Use `BLOCKED` when required
inputs or model verification are missing; it does not complete the checkpoint.

## Findings

Repeat this subsection for each finding, with stable ids across revisions. With no findings,
write `None in the reviewed snapshot` and retain the coverage and limits above.

### <adr-id>-sec-01: <specific exposure or design gap>

- Severity and reason: <critical | high | medium | low; impact and prerequisites, not a label alone>
- Location: <ADR section or diagram participant/message>
- Evidence and sources: <design excerpt or concrete omission, relevant standard/documentation links>
- Attack path or counterexample: <actor, access/preconditions, action and violated boundary or invariant>
- Impact: <asset, unauthorized capability, availability loss or design consequence>
- Mitigation: <specific design change; distinguish required controls from optional hardening>
- Verification condition: <observable acceptance condition that can enter a plan/card>
- Assumptions or open question: <what must be confirmed, or none>

## Handback

Report returned to architect: <message id and timestamp>
Unresolved questions: <ids and questions, or none>
Engineer stopped: <timestamp; no further edits or commit>

## Architect response

Architect-only append after the engineer stops. Account for every finding without rewriting it.
Incorporate applicable suggestions into the current ADR or justified focused, reciprocally linked
ADRs. New technical ADRs pass the same security checkpoint and go to senior review with the design.

| Finding | Disposition | Reason | ADR section or linked ADR | Remaining action and owner |
|---|---|---|---|---|
| <adr-id>-sec-01 | <incorporated/adapted/deferred/rejected; choose one> | <reason> | <link and section> | <action and owner, or none> |

- Actual model verification and report-only scope check: <commands/records, results and evidence paths>
- Final design coverage: <this snapshot still covers the security-relevant design, or link the new report revision>
- Serious unresolved risks: <explicit ADR open questions, impact, alternatives and senior-architect decision; never silent acceptance>
- Senior-review bundle: <reconciled ADRs, diagrams, reports and response; commit on the contract branch before asking for review>
- Follow-through: <accepted mitigations and verification conditions to carry into acceptance criteria and card contracts>
