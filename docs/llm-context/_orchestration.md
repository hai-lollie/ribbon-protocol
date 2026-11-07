# <plan-id> Herdr orchestration

Architect: <agent>, <provider/model#effort>
Plan revision: 1
Started: <YYYY-MM-DD HH:MM, with timezone>
Status: active                         # active | blocked | done
Integration branch: <branch>
Base commit: <hash>
Detection: `test "${HERDR_ENV:-}" = 1`, exit code 0

The architect owns and updates this file. It records execution evidence; it does not replace a
card report, an acceptance result, a decision-log entry or the independent review. Do not mark it
`done` or archive it while a timed-out decision awaits senior-architect disposition.

## Senior architect attention

Write `None` here when no question timed out. Otherwise, repeat the following subsection for every
timed-out decision and keep it under this exact heading until acknowledged or reversed:

### SENIOR ARCHITECT: TIMED-OUT DECISION

- Question: <the question asked>
- Question tool message/session and timer evidence: <ids and artifact>
- Asked and deadline: <timestamps, 45 minutes apart>
- Recommended default: <the option presented to the senior architect>
- Action after timeout: <what the architect chose, or "no action; affected card stopped">
- Evidence: <references, queries or spikes; a guess is labelled as a guess>
- Decision log: <entry id and date>
- Affected cards and revisions: <ids and revisions>
- Senior-architect disposition: pending

Never remove these entries. Add later acknowledgements and reversals with their dates. The live
handoff and decision log link here while any disposition is pending.

## Validation and assignments

Validated by: `<name>, <YYYY-MM-DD>`
Acceptance file: `docs/tasks/<plan-id>.acceptance.yaml`

| Card or review | Revision | Role | Herdr agent | Exact provider/model#effort | Tab and workspace/pane | First message verified | Briefing id and acceptance tests |
|---|---|---|---|---|---|---|---|
| <task-id> | 1 | general-coder | <agent> | <provider/model#effort> | `<Agent>@<plan-id>/card-<n>`, <ids> | <session/message id> | <prompt id>; <exact test names> |
| plan review 1 | <plan revision> | reviewer | <agent> | <provider/model#effort> | `<Agent>@<plan-id>/review-1`, <ids> | <session/message id> | <prompt id>; <commit range> |

A missing exact model, briefing-delivery evidence or first-message mismatch stops the assignment.
Never copy a model string from a footer or an assumption.

## Exclusive file ownership and integration

Integration owner: <visible coder agent; the only owner of plan handoff and done files>

| Card | Worktree and card branch, or sequential | Owned repository paths, including moves and evidence | Overlap/dependency check | Integration result |
|---|---|---|---|---|
| <task-id> | <absolute worktree and branch> | <complete ordered list> | disjoint from <live cards>; dependencies pass | <integration commit and checks> |
| <last task-id> | <worktree and branch> | <paths, including `<plan-id>-handoff.md` and `<plan-id>-done.md`> | sole shared-file owner | <integration commit and checks> |

The architect computes this table before spawning. Parallel work requires an isolated worktree,
index and card branch for every coder. An intersection, an unnamed generated file, an unproved
overlap or shared Git state makes the affected cards sequential. The architect integrates card
branches one at a time and records the checks after each integration.

## Permission enforcement

| Card or review | Existing sandbox or permission mechanism | Repository/review writes | Local Git metadata operations | Scratch roots | Verified before spawn | Diff check before acceptance |
|---|---|---|---|---|---|---|
| <task-id> | <mechanism and configuration identity, or `prompt-only` and why the harness cannot enforce it> | <approved paths> | <worktree, stage, local commit only> | `/tmp`, `~/tmp` | <evidence> | <`git diff --name-only <prev>..<commit>` and the untracked paths: every path inside the approved set, or the stop> |

A prompt-only restriction is not enforcement, so it carries the compensating controls of
`herdr-config.md`: the briefing names the boundary, and every card's changed and untracked paths
are checked against its approved set before the card is accepted. A path outside it stops the card.
A reviewer has no production write permission; its diff check expects the review file and its
evidence only.

## Monitoring events

| Time | Agent/card or review | Observed state or halt | Transcript or evidence | Architect action | Result |
|---|---|---|---|---|---|
| <timestamp> | <agent/id> | <working, blocked, unknown, stalled, lock, idle, done> | <command and output path> | <answer, revision, escalation or acceptance check> | <next state> |

A settled state alone is never a card pass. Link the card's report and commit as completion
evidence. Monitor reviewers as well as coders.

## Questions and timed-out decisions

| Question | Tool message/session | Asked | 45-minute deadline and timer evidence | Recommended default | Answer or timeout action | Decision-log entry |
|---|---|---|---|---|---|---|
| <question> | <id> | <timestamp> | <timestamp and artifact> | <default> | <answer, default or safe stop> | <id> |

Copy every timeout into "Senior architect attention" above. Security, permission, scope,
destructive and remote-action questions never receive approval by timeout. If nonblocking
questions or timer tracking are unavailable, record the safe stop of every live assignment; do
not execute an untracked autonomous default.

## Attempts and repair interventions

| Card | Every implementation/repair attempt and result | Cumulative repairs | Remaining budget in briefing | Exact architect solution and card revision | Mechanical application and one verification |
|---|---|---|---|---|---|
| <task-id> | <dated attempts across every coder and respawn> | 2 | 0 | <complete contract text and briefing id> | <report, checks and commit, or blocked without another edit> |

The count is cumulative across coders, respawns and card revisions. After two repairs, only a
mechanical application of the architect's complete solution and one verification remain. A need
to redesign, adapt or choose is an escalation, not a third repair.

## Research and spikes

| Parent | Research subagent or query | Read-only sources | Findings assessed | Architect decision or spike |
|---|---|---|---|---|
| <agent> | <agent/model when available> | <paths, URLs or read-only calls> | <facts and labelled guesses> | <decision, card revision or `/tmp`/`~/tmp` spike> |

Research subagents write no artifacts. Every persistent spike belongs to the architect or a Herdr
agent and stays under `/tmp` or `~/tmp`.

## Review cycles

| Cycle | Previous review | Repair range | Visible reviewer and first-message evidence | Verdict and report |
|---|---|---|---|---|
| 1 | none: initial review | not applicable | <agent and session/message id> | <verdict and `<plan-id>-review.md`> |

Cycle 3 is terminal. Record non-blocking findings as debt and unresolved blocking findings for the
senior architect's disposition. Never relabel the same findings or acceptance scope as a successor
plan to obtain another cycle.

## AFK and return review

AFK started: <timestamp and senior-architect message>
Integration branch and AFK start: <branch>, <hash>
Integration branch local head: <hash, updated until the senior architect returns>
Remote mutations during AFK: none
Pending trusted-verifier or deployment checks: <list, or none>

| Worktree or contract branch | AFK start/base | Local head | `git status --short`, including untracked work | Integrated or pending |
|---|---|---|---|---|
| <path or branch> | <hash> | <hash> | <status artifact> | <integration commit or pending> |

Return summary artifacts:

```text
git log --oneline <afk-start>..<local-head>   -> <output path>
git diff --stat <afk-start>..<local-head>    -> <output path>
git diff <afk-start>..<local-head>           -> <complete diff output path>
```

Record equivalent ranges for every unintegrated card branch and any contract commits outside the
integration branch. The return summary links every timed-out decision, pending remote check and
worktree status. Uncommitted or untracked work is shown separately, never omitted from a diff
range. Returning to chat does not itself authorize a push or deployment.
