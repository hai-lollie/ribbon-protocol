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
  - {command: "the per-file checks the root AGENTS.md names for the language", exit_code: 0, artifact: "<one line per edited file>"}
repair_attempts: 0
failure_class: NONE                      # NONE | SEMANTIC | SCOPE | TEST | CONTEXT
unresolved_risks: []
decisions: []                            # doubts the card's rules and the file answered, each with its rule
next_owner: reviewer                     # reviewer | architect | senior architect
commit: <hash, filled in the next commit when it cannot be known yet>
```

## Scorecard

```yaml
task_id: <task-id>
model: <the model string the session shows, effort included; never copied from the plan>
task_class: <bounded-feature | bounded-bugfix | scaffold | refactor | docs>
card_revision: 1
first_pass_accepted: true
repair_attempts: 0
failure_codes: []
human_minutes: 0                         # the senior architect fills this in, when known
lines: 0                                 # inserted lines under the unit (docs/tasks/README.md, The phases of a story), on this card's commit
wall_minutes: 0                          # the preflight timestamp to the completion timestamp
tokens: measured                         # the architect appends the measured block below after the commit
```

## Cost, measured

Appended by the architect after the commit, from the harness's own records, never retyped: the model, the effort
and the tokens as they ran, priced in the unit the harness or the plan uses; a card the coder handed to a child
session counts the child with it.

```yaml
cost_measured:
  window: "<YYYY-MM-DD HH:MM .. YYYY-MM-DD HH:MM>"   # the previous card's commit to this card's commit
  model: "<model#effort (messages)>"
  agents: "<agent (messages), child agent (messages, children of its sessions)>"
  messages: 0
  tokens: {input: 0, cache_read: 0, cache_write: 0, output: 0, reasoning: 0}
  context_per_message: 0
  price: "<the amount and its unit, from the harness's records>"
```
