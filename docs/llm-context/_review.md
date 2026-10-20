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

## The plan as a deliverable

- Lines: <measured with the unit over the range> against <the sum of the cards' size>;
  over 900 is a finding of class SIZE
- Deliverable on its own: <yes, because the story holds with nothing from the next
  phase; or the finding>

## Findings

### F1. <title, the defect in one sentence>

- Card: <task-id>
- Class: SEMANTIC                        # SEMANTIC | SCOPE | TEST | CONTEXT | ARCHITECTURE | SIZE
- Where: <path:line>
- Counterexample: <the input or state, and the wrong output or missing refusal>
- Evidence: <the command you ran, and what it printed>
- Next owner: architect                  # architect | coder | senior architect
