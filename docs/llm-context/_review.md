# <plan-id> review

Reviewer: <agent>, <model id>
Review cycle: 1                           # 1, 2 or 3; never greater than 3
Previous review: <path and verdict, or "none: initial review">
Repair range reviewed: <previous review head>..<head commit, or "not applicable">
Range: <base commit>..<head commit>
Read: the plan at revision N, cards 01 to NN, their reports, ADRs NNNN and NNNN
Date: <YYYY-MM-DD>

## Verdicts

| Card | Verdict | Findings |
|---|---|---|
| <plan-id>-01 | APPROVE | |
| <plan-id>-02 | CHANGES | F1 |
| plan | CHANGES | F1 |

`APPROVE`, `CHANGES` or `ESCALATE`. `CHANGES` means the architect cuts repair cards for
the findings that break one of the five of "Done" and lists the rest under the plan's
`debt`; a `CHANGES` whose findings are all debt reads as `APPROVE` with debt.
`ESCALATE` means the senior architect decides. Cycle 1 is the initial review; cycles 2 and 3 cover
repair cards and name the previous review and repair range. Cycle 3 is terminal: its non-blocking
findings become debt and its blocking findings need the senior architect's disposition. A successor
plan may address recorded debt but may not repeat the same findings or acceptance scope as a
fourth cycle.

## Done

The five of "Done, and when the loop stops" in the root `AGENTS.md`, each with its
evidence; the reviewer runs the boot itself.

| Holds | Evidence |
|---|---|
| the gate, locally and on the trusted verifier | <each command, its exit code, the verifier's run id> |
| the boot by the entry point a person runs, its smoke check, its stop | <the command, its output's first lines, the exit code> |
| the acceptance file, name for name | <the count, and the table under Findings or its own section> |
| coverage at the plan's line | <the numbers> |
| no open SEMANTIC or SCOPE finding on production code | <the finding ids that remain, each with its class> |

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
