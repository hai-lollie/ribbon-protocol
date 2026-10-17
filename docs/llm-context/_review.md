# <plan-id> review

Reviewer: <agent>, <model id>
Range: <base commit>..<head commit>
Read: the plan at revision N, cards 01 to NN, their reports, ADRs NNNN and NNNN
Date: <YYYY-MM-DD>

## Verdicts

| Card | Verdict | Findings |
|---|---|---|
| <plan-id>-01 | APPROVE | |
| <plan-id>-02 | CHANGES | F1 |
| plan | CHANGES | F1 |

`APPROVE`, `CHANGES` or `ESCALATE`. `CHANGES` means the architect cuts repair cards.
`ESCALATE` means the senior architect decides.

## Findings

### F1. <title, the defect in one sentence>

- Card: <task-id>
- Class: SEMANTIC                        # SEMANTIC | SCOPE | TEST | CONTEXT | ARCHITECTURE
- Where: <path:line>
- Counterexample: <the input or state, and the wrong output or missing refusal>
- Evidence: <the command you ran, and what it printed>
- Next owner: architect                  # architect | coder | human
