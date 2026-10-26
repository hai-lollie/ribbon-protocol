# Tasks: plans and cards

The architect writes here. The coder reads here and never edits here. The senior
architect validates every plan before a coder starts. Simplified Technical English:
one instruction per line, exact, no adjectives.

## Ids and files

- A **story id** is lowercase kebab-case, for example `msq2-era-api`: one problem to solve,
  and one acceptance file, `<story-id>.acceptance.yaml`. A story that fits one review is one
  plan, `<story-id>.plan.yaml`, and its plan id is the story id. A larger story is cut
  into phases, each a plan, `<story-id>-pN.plan.yaml`, in order.
- A **card id** is the story id plus a two-digit sequence, for example `msq2-era-api-02`.
  Its file is `<story-id>-NN.yaml`. Numbers run once across the phases of a story and are
  never reused; repair cards take the next numbers.
- The same spelling everywhere: file names, prose, commit messages, report names.
- **A line is at most 150 characters.** Fold a longer string with `>-`, wrapped at
  about 120, and write a long `{given, expect}` row as a block map with one folded
  value per key.

## A plan

One deliverable, one branch, one coder, one architect, one reviewer: a whole story, or
one phase of a story too large for one review (see "The phases of a story"). Copy
`_template.plan.yaml`. Beside it, `<story-id>.acceptance.yaml` names every acceptance
test of the story before any code exists: a test name, the input and the expected
output, in plain English, each tagged with the card that implements it. Copy
`_template.acceptance.yaml`. The coder implements that list test name for test name,
and the reviewer and the senior architect check the result against it.

| Field | Required | Meaning |
|---|---|---|
| `schema_version` | yes | `2`; `1` on a plan written before the phases rule, whose cards have no `size` |
| `plan_id`, `title` | yes | the id above; the pull request's title, which a person reads and which stands without the next phase |
| `story_id`, `after` | no | on a phase only: the story this plan is one phase of, and the plan that must be `done` before this one is validated |
| `revision` | yes | `1`, bumped by the architect on every change after validation |
| `branch`, `from` | yes | the branch the coder works on, and what it starts from: `main`, or the approved head of the plan under `after` |
| `compare_with` | no | branches that did the same work another way, one or a list; the coder never reads them |
| `architect`, `reviewer` | yes | two different agents, different vendors when possible |
| `coder`, `role` | yes | the coder, and the hat the plan needs: `general-coder` or `entry-coder`. A card may lower it, never raise it |
| `adrs` | yes | the accepted ADRs this plan implements, none with a pending open question |
| `decisions` | yes | the entries of the project's decision log that bind this plan, by id, for example `[D-067, D-073]`; `[]` when none. The coder reads those entries and no other |
| `story` | yes | one sentence: who asks for what, and what they get; with `success`, the pull request's body |
| `success` | yes | observable outcomes, each one checkable |
| `acceptance` | yes | the commands and verdicts that close the plan |
| `constraints` | yes | what holds across every card |
| `stop_line` | yes | plan-level stop lines, in addition to each card's |
| `debt` | no | the findings the last review left open that break none of the five of "Done, and when the loop stops" (root `AGENTS.md`): `{finding, line, owner}` rows; the next plan on the same code opens with them |
| `tasks` | yes | the cards in execution order: `{id, title, size, status}`, `size` copied from the card. Loaded verbatim into the coder's todo tool |
| `status` | yes | `proposed`, `validated`, `in-progress`, `done`, `abandoned` |
| `validated_by` | yes | empty until the senior architect writes a name and a date |

## A card

The smallest change that ends in a green commit. Copy `_template.task.yaml`. Empty
sections are omitted, not left blank.

| Field | Required | Meaning |
|---|---|---|
| `schema_version`, `task_id`, `plan`, `title`, `revision` | yes | as for a plan |
| `role` | yes | `general-coder` or `entry-coder` |
| `size` | yes | the architect's estimate of the card's inserted lines under the unit of "The phases of a story"; a card over 900 splits |
| `depends_on` | yes | the cards that must be `pass` first; `[]` when none |
| `adr` | no | the ADR this card implements, when one applies |
| `objective` | yes | one sentence of observable behaviour |
| `out_of_scope` | yes | what this card must not touch, even when it looks easy |
| `context.read_first` | yes | what to read before anything, in order, and nothing else: a file, with its section or line range when the file is long; a decision by id, never its whole log; never a report, a note or a journal, whose facts the architect copies into `verified`. The architect keeps the list to what the card needs |
| `context.reference_pattern` | no | a file that already does it the right way |
| `context.verified` | yes | facts the architect checked, with where: a signature, a path, a fixture. The coder re-checks them in preflight |
| `preconditions` | yes | what must be true before the first edit |
| `behavior` | yes | the matrix: `{given, expect}` rows, normal paths and counterexamples |
| `invariants` | yes | what must stay true across normal and failure paths |
| `decisions.architect` | yes | the decisions already made; the coder does not reopen them |
| `decisions.coder` | yes | the local choices left to the coder |
| `moves` | no | when the card moves, splits or renames files: one `{from, to}` row per file, computed by the architect. The coder moves and never classifies |
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

## The phases of a story

A story larger than one review is cut into phases, each a plan with its own branch, its
own review and its own handoff. The cards keep the story id and one numbering, and
the acceptance file is the story's.

**The unit.** Inserted lines under the plan's writable roots, measured with

```
git diff -M -I'^\(ns ' --shortstat <from>..<head> -- <writable roots> ':(exclude)*.md'
```

Insertions only: tests count, deletions do not, markdown does not, `docs/llm-context` is
never a root. `-M` counts a file moved whole as zero; `-I'^\(ns '` counts a hunk made only
of `ns` lines as zero, the lines a Clojure move always changes. A project in another
language puts its own pure-rename pattern after `-I`.

**The size.** Every card carries `size`, the architect's estimate under the unit, and the
plan's `tasks` rows copy it. The project's first plans are the scale: the numbers the
reviewer measures calibrate the next estimates.

**The range.** A phase is 400 to 900 estimated lines, and 400 is the target.

| The phase's estimated lines | Rule |
|---|---|
| under 400 | join the next phase, unless the join passes 900 or breaks either story |
| 400 to 900 | in range |
| over 900 | split; when the halves are not each a story, recut the cards until they are |
| one card over 900 | the card splits |

The reviewer measures the range with the unit and writes the number beside the estimate.
A measure over 900 is a finding of class `SIZE` on the plan, never on the coder, and the
architect re-estimates the phases left before the next validation. The card count is no
rule: five cards under 400 lines is a smell of thin cards.

**The deliverable.** Every phase is a deliverable on its own, deployable from its last
commit:

- Its `title`, `story` and `success` are the pull request's title and body, written
  before any code. A title that needs the next phase to make sense is not a phase: part,
  half, step, move one, transit, prepare and scaffold are the red flags.
- Its acceptance subset is closed: every test tagged to its cards is green at its last
  commit, and no test of a later phase exists yet.
- Nothing dangles: every production namespace it adds has a caller or is an entry point
  at its end; a namespace born to be deleted by a later phase is forbidden; coverage holds
  at its end, not only at the story's.
- The gate is green at its last commit, and the trusted verifier on the push.
- The reviewer's plan verdict carries one line: "deliverable on its own: yes, because the
  story holds with nothing from the next phase", or a finding.

A refactor is a deliverable when its story stands alone (the test tree moves home); it is
not when its title needs the next step (move one of two).

## Lifecycle

- **Plan:** `proposed`, then `validated` when the senior architect writes
  `validated_by`, then `in-progress` at the coder's first commit, then `done` when the
  review says `APPROVE` for the plan, or `CHANGES` with every finding under `debt` and
  the senior architect's merge, or `abandoned`. Two review rounds at most.
- **Phase:** a phase plan stays `proposed` until the plan under `after` is `done`; the
  senior architect validates it then, with the review's findings folded into its cards.
  Merging is optional at every `APPROVE`: every phase is a deliverable on its own.
- **Card:** `todo`, `in-progress`, then `pass`, `blocked` or `escalated`. The architect
  updates the plan's `tasks` from the reports; the coder's todo tool shows the live
  state.
- **Revision:** the architect bumps `revision` when a card changes after a note. The
  coder runs preflight again on a revised card, reading it from the main branch when its
  own branch has diverged (`git show main:docs/tasks/<task-id>.yaml`).

## The todo list

At session start the coder loads `tasks` verbatim into its todo tool, one item per
card, in order, and marks each card as it starts and ends. The coder never adds an item.
A step the plan does not list is a question, written as a note.
