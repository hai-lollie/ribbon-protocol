## The branches

Every story has a short prefix, and every branch of the story starts with it (`quiz/` in the
examples below). The main branch takes merges only, and each merge is a state the senior
architect validated, so the history of `main` reads as a list of decisions.

- **The contract branch, `<prefix>/adr-plan-cards`.** The architect writes the story's
  contract there: its ADRs and diagrams, its plans, acceptance files and cards, its
  decision-log entries, and the architect's own records (a journal, an orchestration
  report). The senior architect reviews the branch, by a compare view or a pull request,
  and answers there.
- **The merge.** When the senior architect accepts the ADRs and validates a plan, the
  architect merges the contract branch into `main` with `git merge --no-ff`. A coder
  starts only after that merge.
- **A plan's branch, `<prefix>/<plan slug>`** (for example `quiz/scoring-p1`), named in the
  plan's `branch` field, starts from `main` after the merge. Only the architect changes it:
  the coder and the reviewer work in their own worktrees, on their own branches from it, and
  the architect merges them in after its path check. The reviewer reads the plan branch's
  range.
- **An agent's branch**, `<plan branch>-card-NN` for a coder's assignment, named after its
  first card, or `<plan branch>-review-N` for a review (for example `quiz/scoring-p1-card-01`),
  lives only from its assignment to the architect's merge.
- **A revision during execution** (a repair card, an answer to a note, a timed-out
  decision) is a commit on the contract branch, merged into `main` before the coder is
  told. The coder never edits the architect's paths, so these merges never conflict with
  the plan's branch.
- **Work outside a story** (a protocol port, a tooling change) takes its own short branch,
  `<topic>/<slug>`, under the same rule: reviewed there, merged into `main` when accepted.
- **Parallel and unrelated work stays apart:** two stories never share a branch, and a
  plan's branch never carries the architect's records.

### Who changes a branch, and where

Only the architect changes the local branches: `main`, the contract branches and the plan
branches. Every coder and reviewer works in its own git worktree outside the main checkout,
on its own branch, never on a shared one. At handoff the agent stops, and the architect
removes its worktree, compares every changed path with the assignment (`git diff
--name-only`), merges the agent's branch into the plan's branch (a fast-forward when the plan's
branch has not moved, otherwise `--no-ff`) and deletes it. The next assignment's branch starts
from the plan's branch after that merge. Nothing reaches a plan branch before the path check,
so a prompt-only write boundary gets a gate, not only an audit.

Nobody switches the main checkout's branch: it is where the senior architect reads branches.
The architect commits there only on the branch it has, and edits any other branch in a
short-lived worktree. A worktree lives only while its work is in progress: when the work goes to
the senior architect for review, the architect removes it, and the branch stays a local branch
in the repository. A change she asks for gets a new worktree from that branch. A worktree under
a temporary filesystem holds nothing that is not committed before a restart.
