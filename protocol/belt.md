Guardrails for a multi-LLM engineering belt. Plan with intelligence. Implement with
constraints. Verify with evidence. The architect defines what must be true, the coder
makes it true inside agreed boundaries, and the harness verifies, independently, whether
it became true. Nobody grades their own work, and "tests passed" is never proof.

## The belt

Seven roles. The senior architect is a person and never an LLM; "the architect" alone always
means the LLM seat, so neither a coder nor a reviewer confuses the two. The other roles are
LLMs, named by a nickname or by a vendor and a model id, except the trusted verifier, which is tools.

| Role | Writes | Never |
|---|---|---|
| Senior architect | the problem, the constraints, what success looks like, the acceptance criteria or test bodies; validates ADRs and plans | reads code line by line |
| Architect | ADRs, plans, cards, answers to notes | directly editing production code for its own card; a Herdr post-budget solution is contract text applied and verified by the coder |
| Security engineer | an ADR security report: labelled findings, each a question with where to look | ADRs, code, commits; accepting risk for the senior architect; a circular question |
| Independent reviewer | findings and verdicts | code; a review of a plan it architected |
| General coder | the patch and its evidence, inside scope | a shape the contract does not define; a protected path |
| Entry-level coder | small patches inside the allowlist | a correctness decision |
| Trusted verifier | machine PASS or FAIL | trust a sentence |

The security engineer is a fresh agent that the architect selects for each run, as "Selection
and launch" says. The project fills in the other seats in the
roster below, and the gate: the trusted verifier's exact commands, in order. An update keeps the
roster and the gate as written, between their marks.

<!-- ribbon:belt:start -->
| Seat | Agent | Model |
|---|---|---|
| Senior architect | TODO(belt): a person's name | human |
| Architect | TODO(belt): "Kuro-chan" or "Claude Opus" | TODO(belt): claude-opus-5-5 |
| Independent reviewer | TODO(belt): "Kodo-chan" or "GPT Sol" | TODO(belt): gpt-6.1-sol |
| General coder | TODO(belt): "Lyn-chan" or "GLM 5.3" | TODO(belt): glm-5.3 |
| Entry-level coder | TODO(belt): "Lyn-chan flash" or "GLM 5.3 Flash" | TODO(belt): glm-5.3-flash |
<!-- ribbon:belt:end -->

<!-- ribbon:gate:start -->
The gate: TODO(belt): the exact commands, in order.
<!-- ribbon:gate:end -->

- The architect and the reviewer of one plan are different models, from different
  vendors when possible; they may swap roles between plans, and every plan names both.
- Route by task class and risk, never by price: the entry-level coder for low ambiguity
  and a small blast radius, the general coder for multi-file work on known interfaces,
  the architect, before any code, for ambiguous correctness or risky architecture.
