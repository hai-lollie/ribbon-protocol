# Herdr orchestration overlay

This file is the Ribbon Protocol's optional Herdr overlay. The root `AGENTS.md` remains the
protocol for plans, cards, evidence, reviews and the five proofs of done. This overlay governs
execution when the LLM architect runs inside a Herdr-managed pane. It never weakens the security
policy, the senior architect's authority or the independent review.

A project copies this file beside its root `AGENTS.md`. A Claude-based project's `CLAUDE.md`
includes it with `@herdr-config.md`. An OpenCode architect reads it whenever the detection below
succeeds.

## Detection and scope

Before any Herdr inspection or control command, the architect runs:

```sh
test "${HERDR_ENV:-}" = 1
```

If the command fails, the architect is not inside Herdr. This overlay does not apply: the
architect does not inspect or control a focused Herdr session and follows the core protocol's
ordinary execution path.

If it succeeds, every rule below applies. The architect uses the installed `herdr` binary as the
authority for command syntax, reads its relevant `--help` output and never starts the bare Herdr
TUI for discovery. Commands use explicit identifiers returned by Herdr, the current workspace and
the project working directory. Background work preserves the senior architect's focus.

## Validation before execution

Before senior-architect ADR review, the architect runs the core protocol's security design
checkpoint. The security engineer runs in its own visible Herdr tab, reviews the uncommitted draft,
writes only its report and permitted evidence, returns to the architect and stops. The architect
then incorporates the findings in the current ADR or justified linked ADRs, records every
disposition and commits the reconciled design before asking for senior-architect approval.
This assignment needs no validated implementation plan; it authorizes no coder or production edit.

The architect finishes the plan, its acceptance file and every card before implementation execution. The plan
names the architect and independent reviewer, and each card names its role, behavior, acceptance,
writable scope and stop lines. The architect asks the senior architect to validate the complete
contract.

No coder starts until the senior architect has written `validated_by` and the architect has merged
the story's contract branch into `main` (the core protocol's "The branches"). The orchestration
report lives on that contract branch with the architect's other records. A question answered during
planning is not plan validation. A later change follows the core protocol's revision rules. A
card revision made solely to apply a timed-out senior-architect question is authorized by the
timeout rule below and does not wait for a second validation; its coder runs preflight again.

## Model selection and routing

The senior architect may assign exact agents, models and efforts during plan review. When she does
not, the architect uses these defaults:

| Assignment | Default agent and model family | Effort |
|---|---|---|
| General coder | Lyn-chan, GLM 5.3 or the newest available GLM general coding model | high |
| Entry-level coder | Lyn-chan Flash, GLM 5.3 Flash or the newest available GLM `-flash` model | high |
| Security engineer | equal-chance selection between eligible OpenAI GPT Sol 6.1+ and Moonshot Kimi K3.1+ | Sol: xhigh, or high if unavailable; Kimi: high |
| Independent reviewer | GPT Sol 6.1 or the newest available Sol model | xhigh, or high when xhigh is unavailable |
| Entry-level fallback | Claude Haiku 5.5 or the newest available Haiku model | maximum supported effort |

The security engineer follows the core protocol's version floors and coin-flip rule, not a cheaper
coder fallback. An alias such as `kimi-for-coding` does not establish that Kimi K3.1+ is available.

The architect resolves a family default against the harness's current model inventory at execution
time. It records the exact provider, model and effort in the orchestration report before the first
prompt. It never invents a model identifier, trusts a footer as proof or silently substitutes a
different family. If no eligible model is available, the assignment stops and the senior architect
is asked. The reviewer still satisfies the core protocol's independence rule.

A security assignment can precede a plan. Instead of a not-yet-existing plan orchestration report,
its named security evidence folder records the selection, permissions, briefing and model
verification; its report links that evidence. When a plan's
orchestration report exists, the architect links the design's security reports there.

The card's `role` controls routing. A general coder receives multi-file work on known interfaces.
An entry-level coder receives work with low ambiguity and a small blast radius. Ambiguous
correctness and risky architecture remain with the architect, before implementation.

When four or more coder agents are already live, every additional entry-level assignment uses the
Haiku fallback instead of adding another concurrent GLM Flash coder. The count includes live coder
agents, not research subagents, the architect or the reviewer. General-coder assignments keep
their selected model; this fallback changes the entry-level model, not the card's role.

## Research subagents and exclusive authorship

The architect and Herdr agents may use any available subagent for read-only research: codebase
exploration, documentation or web research, read-only API or MCP queries, option comparisons and
evidence gathering. A research subagent returns findings, references and recommendations to its
parent. It produces no persistent artifact and never:

- creates or edits a file, including code, tests, plans, reports and documentation;
- commits, pushes, deploys or changes remote state;
- changes permissions, LLM configuration, skills or MCPs;
- makes a correctness, domain-policy, security or scope decision for its parent;
- exceeds the reading and access boundaries of the assignment.

The parent evaluates important claims before using them. A research answer is not automatically a
fact. The architect names its sources when it turns research into `context.verified`, an answer or
a decision-log entry.

In Herdr mode, every persistent write belongs to the architect herself or to a visible Herdr agent
controlled by the architect. The architect writes architect-owned artifacts. A Herdr coder writes
only its assigned implementation, tests, evidence, reports and commits. A Herdr reviewer writes its
review and never changes production code. Hidden coding subagents, including hidden entry-level
coders, are forbidden. A Herdr agent may delegate research, never authorship.

The security engineer is a report author, not a research subagent. In Herdr mode it follows the
same visible-authorship rule and may write only its assigned security report and evidence. The
core protocol's report-writing subagent fallback applies only when Herdr is absent from the system,
not when it is installed but the current session is outside Herdr. Ordinary research subagents
remain read-only everywhere.

Only the architect may write Todoist or another external task system. Each Herdr coder instead
loads its assigned cards verbatim into its harness task list, in plan order, and keeps that list
current. It never adds work that the plan does not assign. Research subagents do not write any
task system.

Only existing, connected MCP servers may be used. Remote API and MCP calls are read-only unless
the senior architect explicitly approves the specific mutation and is not AFK.

## Permissions and writable roots

Before each spawn, the architect uses existing harness or sandbox controls to enforce the minimum
access required by the card, wherever the harness offers one. A prompt is not a sandbox, so a
prompt-only boundary needs compensating controls. Many coding harnesses cannot enforce writable
roots: an agent file may narrow an edit tool by path while the shell tool still writes anywhere.
When the available harness cannot enforce the boundary, the architect still spawns the agent,
under the senior architect's standing approval for every project (2026-11-07), with these
compensating controls:

1. the briefing names the writable paths, the scratch roots and the forbidden changes below;
2. before accepting a card, the architect compares every path the card's commits changed
   (`git diff --name-only <previous card's commit>..<this card's commit>`) and the coder's
   uncommitted and untracked paths with the card's `scope.writable`, its report and its evidence
   folder; a path outside them stops the card, and the architect reverts nothing on the coder's
   behalf;
3. the orchestration report records the mechanism as `prompt-only`, the reason the harness
   cannot enforce it, and each card's diff check with its command and result.

A harness control that does exist, such as an edit-tool path rule, is still applied; the
compensating controls cover what it leaves open.

For a security engineer, the report and evidence allowlist replaces the card's writable scope.
Before launch the architect records the permission boundary and a tracked/untracked content baseline,
including already-dirty files, in the named security evidence folder. No draft, production, test,
Git metadata or configuration write is authorized. After the engineer stops, the architect compares
the repository against that baseline: every change must be inside the report/evidence allowlist,
and reviewed draft hashes must be unchanged. It records the comparison and verifies the actual model
before accepting the report. An unexpected change stops the checkpoint; the architect does not
silently revert it. The architect pauses its own edits to the reviewed inputs during the assignment.
The review runs sequentially in that checkout; any other active writer uses an isolated worktree.

A coder may write only:

1. repository paths approved in its card, including its own report and evidence paths;
2. `/tmp`;
3. `~/tmp`.

The architect ensures that the card or its completion contract names every repository artifact the
coder must write. The sandbox also permits the Git metadata operations needed for approved local
worktree use, staging and commits, without permitting Git configuration changes or remote writes.
Everything else is read-only or inaccessible. In particular, no agent may:

- update system libraries or install system packages;
- change files outside the project repository, `/tmp` and `~/tmp`;
- change LLM configuration, agent configuration or skills;
- create or configure skills or MCP servers;
- edit another card's files, the plan, acceptance file or another agent's evidence;
- push, deploy, release or perform another remote mutation without specific senior-architect
  approval.

Disposable validation spikes are written only by the architect herself or a Herdr agent, and only
under `/tmp` or `~/tmp`. A spike is not production evidence until the card's required verification
and independent acceptance prove the behavior in the project.

## Exclusive file ownership and parallel cards

Every coder and reviewer works in its own worktree on its own branch, sequential work included,
and only the architect changes the local branches (`AGENTS.md`, "Who changes a branch, and
where"). The rules below decide only whether two such assignments may run at the same time.

The architect may run independent cards in parallel only when their repository writes are
provably disjoint and each coder has an isolated worktree, index and card branch. A file has
exactly one active coder owner. One coder may own several files from one card, but no two live
coders may own the same file. Short-lived card branches feed the plan's single integration branch;
they do not create additional deliverables.

Without isolated worktrees, implementation is sequential even when file sets are disjoint. Shared
working trees, indexes and HEADs would let one agent's changes contaminate another agent's
baseline, gate, staging or commit.

The architect compares every active card's `scope.writable` and every `moves` source and
destination. Nested paths overlap. Shared tests, fixtures, generated files, lockfiles, reports and
evidence paths count as overlaps. If any intersection exists, if a generated output is unnamed or
if disjointness cannot be proved, the cards run one at a time. A dependency also prevents parallel
execution until the required card is `pass`.

The architect records each assignment's ownership set, worktree and card branch in the
orchestration report before spawning. Each coder stages and commits only its own approved paths.
The architect checks the resulting diff and report, then integrates card branches into the plan
branch one at a time and runs the required checks after each integration. A conflict or a needed
out-of-scope change stops integration; parallel agents never resolve it by editing each other's
files.

The architect names one visible coder as integration owner. Only that coder may write the shared
`<plan-id>-handoff.md` and `<plan-id>-done.md`, and those paths belong to its ownership set. Its
last-card assignment includes the boot and the five proofs. Every other coder writes only its own
card report and evidence and receives no shared-handoff or plan-completion requirement. Better
sequential and correct than parallel and entangled.

## Spawn and briefing

Each coder, security engineer and reviewer that writes a report under this overlay runs as a full
interactive agent in a new tab in the current Herdr workspace, never as a hidden writing subagent. The
architect uses the installed Herdr and harness procedure for agent, model and effort selection. It
verifies the first assistant message's recorded agent, provider, model and effort before allowing
work; a mismatch stops the assignment. A reviewer receives read-only production access and write
access only to its review and permitted evidence. A security engineer has read-only access to the
named design inputs and references, and write access only to its security report and permitted evidence.

The tab label is:

```text
<Agent>@<plan-id>/card-<number>
```

For example:

```text
Lyn-chan@hundred-pokemon/card-4
```

A reviewer uses its review cycle instead of a card number:

```text
Kodo-chan@hundred-pokemon/review-1
```

A security engineer uses the ADR id and security-report revision:

```text
Kodo-chan@0001/security-r1
```

The architect gives the pane the same label when the harness supports pane names. The Herdr
runtime name is separate and follows Herdr's naming rules. Tabs are created without taking focus,
in the assignment's worktree, sequential work included, or in the project working directory for
the architect's own work. The architect closes a tab it created when its work is complete and the
tab is no longer needed; it never closes another agent's tab.

The first briefing contains:

- the plan's story, success, constraints, decisions and stop lines;
- the card's path and revision, followed by the complete card contract, not only a summary;
- the acceptance file's path and the names, inputs and expected outputs of its assigned tests;
- the baseline, targeted checks, gate, whole-suite requirement and evidence destinations;
- the exclusive ownership set, worktree and card branch when parallel, protected paths, forbidden
  changes and writable scratch roots;
- the cumulative repair count and remaining budget, monitoring route and question procedure;
- the preflight, report and commit requirements, plus handoff and plan completion only for the
  named integration owner;
- the instruction to maintain the assigned harness task list.

The architect records the briefing's delivery identifier and the assigned acceptance-test names in
the orchestration report. A reviewer briefing instead names the plan, cards, commit range, review
cycle and review destination, and explicitly forbids production edits.

A security briefing instead contains the ADR paths, diagrams, constraints, snapshot hashes, report
revision and destination, evidence allowlist, core security checklist, selected provider/model/effort
and selection record. It includes permission and model-verification requirements, the monitoring
and question procedure, and an explicit ban on design/code edits, commits, live attacks and remote
mutations. Completion means an on-disk report, a return message to the architect and no further work;
it does not mean approval of the ADR. The architect verifies the first message before substantive work.

The coder performs the core protocol's read-only preflight and commits `READY` before its first
edit. `BLOCKED` stops that card without an invented answer.

## Monitor every live agent

After the briefing, the architect starts and maintains a monitor for every live Herdr coder,
security engineer and reviewer. It uses Herdr's agent wait, state, explanation and transcript
commands with explicit agent names or pane ids. It watches for:

- `blocked`, approval dialogs and questions;
- `unknown`, a stalled prompt, a timeout, an exited process or an unexpected halt;
- file locks, scope conflicts and another agent's changes;
- repeated failures and exhaustion of the repair budget;
- `idle` or `done` without the required report, evidence or commit.

A settled state is not proof of completion. The architect reads the transcript and the on-disk
evidence before accepting a card. After a failed wait or stalled response, it inspects state
before sending input; it never blindly repeats a prompt or presses a key.

For a security engineer, completion also requires the report's reviewed snapshot, findings or
explicit `NO_FINDINGS`, review limits, verified model record and report-only scope comparison.
The architect then owns incorporation and the response; the engineer never commits the draft.

The architect may answer a technical question when it can establish the answer from the contract,
verified repository facts, documentation, internet references or a disposable spike. It records
the answer and its evidence. It does not turn a guess into a fact.

The architect asks the senior architect through the harness's question tool when the answer is
uncertain or concerns product policy, security, permissions, scope, remote state or another
decision reserved for her. Permission and approval dialogs are never answered merely to keep an
agent moving.

## Senior-architect questions: 45-minute timeout

Every question to the senior architect includes the facts, the options, the consequences and a
recommended default. The architect submits it through a nonblocking harness question mechanism,
starts a wall-clock timer and records the question message or session id, the submission time, the
deadline exactly 45 minutes later and the timer evidence in the orchestration report. It continues
independent, unaffected work and monitoring while waiting.

If the harness offers only a blocking question tool or cannot track the deadline, the architect
first stops every live assignment safely. It must not leave agents unmonitored or claim an
untracked timeout. Without a working timeout mechanism, the affected card waits for the senior
architect instead of executing an autonomous default.

If the senior architect does not answer by the deadline, the architect chooses the recommended
default. For a security, permission, scope, destructive or remote-action question, the safe
recommended default is no action; timeout never grants approval.

The architect immediately:

1. records the question, evidence, chosen default and reason in the project's decision log;
2. writes a prominent `SENIOR ARCHITECT: TIMED-OUT DECISION` entry in the orchestration report;
3. updates the affected card through the normal revision procedure and tells its coder;
4. includes the decision in the next handoff and in the return summary after AFK.

A timed-out decision remains visible until the senior architect acknowledges or reverses it. The
orchestration report is not marked `done` or moved into `history/` while such a disposition is
pending, even when the implementation plan has closed; the decision log and live handoff link to
it. A question for which no safe implementation default exists defaults to stopping the affected
card.

## Strict repair budget and intervention

`repair_budget: 2` means at most two focused repairs for a card across its entire execution.
Respawning the agent, assigning a different coder or revising the card does not reset the count.

After the second failed repair, the coder stops and reports. The architect takes control of the
diagnosis and turns missing context, a verified reference or a code snippet into an exact,
complete solution for the blocking problem. The architect supplies that solution as contract text
through the card revision and briefing procedure; it does not directly edit the coder's production
files. This is the core role boundary's allowance for architect-supplied contract text, not an
architect-authored card commit.

The coder receives the complete change, the cumulative count of two repairs and a remaining repair
budget of zero. It may mechanically apply the supplied change and run verification once, without
redesigning, adapting or choosing another repair. If the application fails, needs a decision or is
incomplete, the coder makes no further edit: the card becomes `BLOCKED` or `ESCALATED` and the
senior architect decides its disposition. Respawning or changing coders carries the same count and
zero budget. Every attempt and intervention is recorded in the orchestration report.

## AFK and local-only work

When the senior architect says she is AFK, away for a while, going to sleep or catching up later,
the architect enters AFK mode. Local implementation, local commits, local gates and local reviews
may continue. The architect and every agent under its control must not push, deploy, release or
otherwise mutate remote state.

The architect records the AFK start and current head of the integration branch and every active
card branch in the orchestration report. It also records each worktree's `git status --short`,
including uncommitted and untracked work, and any contract commits outside the integration branch.
A plan whose trusted verifier requires a remote run cannot claim the five proofs of done while AFK;
that proof remains pending.

On the senior architect's next chat message, the architect gives her a review summary for every
branch that contains work, using the integration range as the primary review:

```sh
git log --oneline <afk-start>..<local-head>
git diff --stat <afk-start>..<local-head>
git diff <afk-start>..<local-head>
```

The architect saves the commit list, diff statistics and complete diff output on disk and links
them in the report. The summary also lists unintegrated card branches, every worktree status,
every timed-out decision and every pending remote check. Uncommitted or untracked work is shown
separately rather than omitted from a range. The summary does not push merely because she has
returned; remote mutation still needs the required approval.

## Good enough and the review ceiling

The core protocol's three-review-cycle ceiling applies. Acceptance criteria, executable behavior,
the required gates and the configured linters and validators define good enough. Style preferences
and speculative improvements do not justify another implementation cycle when the five proofs of
done hold. Remaining non-blocking findings become debt and may open a genuinely new plan.
Unresolved blocking work needs the senior architect's disposition; no successor may relabel the
same findings or acceptance scope as a fourth review cycle.
