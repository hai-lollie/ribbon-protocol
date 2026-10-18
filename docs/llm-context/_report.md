# <task-id> report

Coder: <agent>, <model id>
Card revision: 1

## Preflight, <YYYY-MM-DD HH:MM>, before any edit

```yaml
status: READY                            # READY | BLOCKED
verified_files: ["<path>", "<path>"]
verified_interfaces: ["<name and signature, with the file>"]
baseline: {command: "<verification.baseline>", exit_code: 0}
expected_changed_files: ["<path>"]
unknowns: []
reasons_to_stop: []                      # non-empty means BLOCKED, and a note names them
```

## Completion, <YYYY-MM-DD HH:MM>, before the commit

```yaml
status: PASS                             # PASS | BLOCKED | ESCALATED
changed_files: ["<path>"]
verified_invariants: ["<invariant, and the test that covers it>"]
checks:
  - {command: "<verification.targeted>", exit_code: 0, artifact: "<the last lines of its output>"}
  - {command: "<each gate command>", exit_code: 0, artifact: "<...>"}
  - {command: "<the per-file check the project's AGENTS.md names after every edit>", exit_code: 0, artifact: "<one line per edited file>"}
repair_attempts: 0
failure_class: NONE                      # NONE | SEMANTIC | SCOPE | TEST | CONTEXT
unresolved_risks: []
next_owner: reviewer                     # reviewer | architect | human
commit: <hash, filled in the next commit when it cannot be known yet>
```

## Scorecard

```yaml
task_id: <task-id>
model: <model id>
task_class: <bounded-feature | bounded-bugfix | scaffold | refactor | docs>
card_revision: 1
first_pass_accepted: true
repair_attempts: 0
failure_codes: []
human_minutes: 0                         # the senior architect fills this in, when known
tokens_in: 0                             # this card's share, from the session's usage view; 0 when the provider shows none
tokens_out: 0
wall_minutes: 0                          # the preflight timestamp to the completion timestamp
cost_usd: null                           # null on a subscription plan; then the tokens and the minutes are the cost
```
