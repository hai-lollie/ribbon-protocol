# Tasks: plans and cards

The architect writes here. The coder reads here and never edits here. The senior
architect validates every plan before a coder starts. Simplified Technical English:
one instruction per line, exact, no adjectives.

## Ids and files

- A **plan id** is lowercase kebab-case, for example `msq2-era-api`. Its file is
  `<plan-id>.plan.yaml`.
- A **card id** is the plan id plus a two-digit sequence, for example `msq2-era-api-02`.
  Its file is `<plan-id>-NN.yaml`. Numbers are never reused; repair cards take the next
  numbers.
- The same spelling everywhere: file names, prose, commit messages, report names.
- **A line is at most 150 characters.** Fold a longer string with `>-`, wrapped at
  about 120, and write a long `{given, expect}` row as a block map with one folded
  value per key.

## A plan

A story: one deliverable, one branch, one coder, one architect, one reviewer. Copy
`_template.plan.yaml`. Beside it, `<plan-id>.acceptance.yaml` names every acceptance
test of the story before any code exists: a test name, the input and the expected
output, in plain English, each tagged with the card that implements it. Copy
`_template.acceptance.yaml`. The coder implements that list test name for test name,
and the reviewer and the senior architect check the result against it.

| Field | Required | Meaning |
|---|---|---|
| `schema_version` | yes | `1` |
| `plan_id`, `title` | yes | the id above; a title a person reads |
| `revision` | yes | `1`, bumped by the architect on every change after validation |
| `branch`, `from` | yes | the branch the coder works on, and what it starts from |
| `compare_with` | no | another branch that did the same work another way |
| `arms` | no | when the same plan runs more than once for comparison, one row per run: `{coder, branch, from, started, status, review}`; the top-level `coder` and `branch` name the arm in flight, and an arm never reads another arm's branch |
| `architect`, `reviewer` | yes | two different agents, different vendors when possible |
| `coder`, `role` | yes | the coder, and the hat the plan needs: `general-coder` or `entry-coder`. A card may lower it, never raise it |
| `adrs` | yes | the accepted ADRs this plan implements |
| `story` | yes | one sentence: who asks for what, and what they get |
| `success` | yes | observable outcomes, each one checkable |
| `acceptance` | yes | the commands and verdicts that close the plan |
| `constraints` | yes | what holds across every card |
| `stop_line` | yes | plan-level stop lines, in addition to each card's |
| `tasks` | yes | the cards in execution order: `{id, title, status}`. Loaded verbatim into the coder's todo tool |
| `status` | yes | `proposed`, `validated`, `in-progress`, `done`, `abandoned` |
| `validated_by` | yes | empty until the senior architect writes a name and a date |

## A card

The smallest change that ends in a green commit. Copy `_template.task.yaml`. Empty
sections are omitted, not left blank.

| Field | Required | Meaning |
|---|---|---|
| `schema_version`, `task_id`, `plan`, `title`, `revision` | yes | as for a plan |
| `role` | yes | `general-coder` or `entry-coder` |
| `depends_on` | yes | the cards that must be `pass` first; `[]` when none |
| `adr` | no | the ADR this card implements, when one applies |
| `objective` | yes | one sentence of observable behaviour |
| `out_of_scope` | yes | what this card must not touch, even when it looks easy |
| `context.read_first` | yes | files to read before anything, in order |
| `context.reference_pattern` | no | a file that already does it the right way |
| `context.verified` | yes | facts the architect checked, with where: a signature, a path, a fixture. The coder re-checks them in preflight |
| `preconditions` | yes | what must be true before the first edit |
| `behavior` | yes | the matrix: `{given, expect}` rows, normal paths and counterexamples |
| `invariants` | yes | what must stay true across normal and failure paths |
| `decisions.architect` | yes | the decisions already made; the coder does not reopen them |
| `decisions.coder` | yes | the local choices left to the coder |
| `scope.writable` | yes | the only paths the diff may touch |
| `scope.protected` | yes | paths the coder never writes |
| `scope.forbidden` | yes | changes the coder never makes, whatever the path |
| `do`, `dont` | no | exact instructions for this card only |
| `verification.baseline` | no | the command run in preflight, before any edit |
| `verification.targeted` | yes | the command that proves this card |
| `verification.gate` | yes | the project's gate, in order |
| `verification.diff_policy` | yes | usually "changed paths are in scope.writable" |
| `stop_line` | yes | this card's stop lines, in addition to the protocol's |
| `repair_budget` | yes | focused repairs allowed before escalating; `2` by default |
| `completion` | yes | what done means: the report, the commit, the status |

## Lifecycle

- **Plan:** `proposed`, then `validated` when the senior architect writes
  `validated_by`, then `in-progress` at the coder's first commit, then `done` when the
  review says `APPROVE` for the plan, or `abandoned`.
- **Card:** `todo`, `in-progress`, then `pass`, `blocked` or `escalated`. The architect
  updates the plan's `tasks` from the reports; the coder's todo tool shows the live
  state.
- **Revision:** the architect bumps `revision` when a card changes after a note. The
  coder runs preflight again on a revised card.

## The todo list

At session start the coder loads `tasks` verbatim into its todo tool, one item per
card, in order, and marks each card as it starts and ends. The coder never adds an item.
A step the plan does not list is a question, written as a note.
