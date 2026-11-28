# Ribbon Protocol 🎀

<sub>リボン・プロトコル</sub>

Guardrails for a multi-LLM engineering belt: plan with intelligence, implement with
constraints, verify with evidence. This repository is a project template, a reference
guide, and the schemas a belt of mixed-capability models needs to work together without
anybody grading their own work.

The rule worth remembering: **the architect defines what must be true, the coder chooses
how to make it true within agreed boundaries, and the harness independently verifies
whether it became true.**

Kawaii does not mean casual about correctness. Pink bows on the outside, strong
invariants on the inside.

## The flow at a glance

![Ribbon Protocol flow: you frame the problem, the architect drafts the ADR and diagrams, the security engineer challenges the design, you approve, the architect plans into cards, coders build card by card with evidence, the trusted verifier checks at the gate, an independent reviewer checks the commits against the plan, and you merge.](ribbon-protocol-flow.png)

The [overview image](ribbon-protocol-flow.png) shows the nine flow steps and the recommended
tool line: Claude, GPT, Kimi and GLM models, orchestrated by herdr in opencode. Vendor labels
are recommendations, not claims of current availability. Resolve exact approved model
identifiers and effort at launch; the architect and implementation reviewer must
be different models. The security engineer is a fresh session, separate from both design
authorship and the later implementation-review assignment.

## The belt in one screen

| Role | Does | Output |
|---|---|---|
| Senior architect, a person | brings the problem, the constraints, what success looks like, when to stop; validates ADRs and plans | decisions |
| Architect | resolves semantics and risk; writes one ADR per design problem; cuts a plan into cards with contracts and dependency order | ADRs, plans, cards |
| Security engineer | questions the draft ADR's security, attack surface and design gaps; returns labelled findings to the architect, each a question with where to look | a security report, not ADR approval |
| Independent reviewer | reads the commit range against the plan and the cards; writes findings with counterexamples | a review with verdicts |
| General coder | implements one plan, card by card, inside each card's scope; leaves evidence after every card | patches, reports |
| Entry-level coder | small mechanical patches inside an allowlist | small patches, reports |
| Trusted verifier | runs the gate outside the coder's control | machine PASS or FAIL |

The architect and the reviewer are different models, from different vendors when
possible, and may swap roles between plans. The loop is Architect, Security review, Contract, Execute,
Verify, and it stops by the five of "Done, and when the loop stops": a plan is done when
the gate, the boot, the acceptance file, coverage and the absence of open semantic
findings hold on its head; the rest is debt, and three review cycles are the most. The
whole core protocol is `AGENTS.md`; read it first. The optional `herdr-config.md` overlay adds
visible coder, security-engineer and reviewer orchestration, research-only helpers, exclusive file
ownership and local-only AFK work when the architect runs inside Herdr.

## Security before ADR approval

The architect finishes the draft technical ADR and diagrams, then launches a fresh security engineer
for each run, at most three, before committing the design for senior-architect review. Each run
makes an equal-chance coin flip between eligible **OpenAI GPT Sol 6.1+** and **Moonshot Kimi K3.1+**
models. Sol uses xhigh, or high when xhigh is unavailable; Kimi requires high effort. If only one
family is available and approved, use it and record why; if neither qualifies, stop and ask. An
alias does not establish a model version.

The engineer checks trust boundaries, authentication and authorization, unnecessary exposure,
secrets and token/key lifecycle, secure entropy, abuse and DoS/DDoS controls, software-design
gaps, and the anti-patterns of the project's language, framework and `rules/`. Every finding is
a question to the architect that says where to look for the answer, with one label, `critical`,
`security incident`, `best-practice violation`, `desirable` or `nitpick`, and the fields that
`AGENTS.md` asks for that label, such as an attack path, the smallest deployable mitigation and a
verification condition. It stays
practical, cites a best practice once and asks no circular question. It writes
`docs/llm-context/<adr-id>-security-r<N>.md`, then reports back and stops. It neither edits the
ADR nor commits it. This is design review, not permission to run attacks or load tests.

The architect answers every question itself, without asking the senior architect what it means or
where to look: it follows the pointers, searches, and tries a proposed change with its own
experiment card under `/tmp` or `~/tmp`. It records a disposition for every finding and has the
final say on what to solve: each response solves every `critical` and `security incident` finding
that it can and at least 51 percent of the findings other than nitpicks and escalated ones. It
decides whether to revise the current ADR or, when the extent of the changes justifies a separate
design decision, create a focused ADR linked from the original, with a link back. That ADR passes
the same security checkpoint, within the same three runs. The architect commits the reconciled
ADRs, diagrams, reports and responses on the contract branch, then asks the senior architect to
review the design together. A `critical` or `security incident` finding that the architect cannot
solve is escalated: it requires her decision. Security-relevant design changes get the next run
before another approval request; the third run is the last.

Use a **new Herdr tab** for every run whenever Herdr is installed. The report-writing subagent
fallback applies **only when Herdr is absent from the system**. Installed Herdr outside a managed
session means stop and ask, not an invisible fallback. Both routes restrict writes to the report
and evidence. The full checkpoint is in [AGENTS.md](AGENTS.md#security-design-review), and the
report template is [`_security.md`](docs/llm-context/_security.md). It does not replace human
approval or consume the plan's three implementation-review cycles.

## Works best with an agent handler

The protocol assumes each role gets its own session, its own context, its own
model: the architect plans, the coder codes, the reviewer reviews, and no agent
grades its own work. That stays true only when something outside the models keeps
the sessions apart. An agent handler does that: one terminal program the architect
drives to spawn, watch and stop agents, each in its own pane with its own context —
no shared window, no pre-loaded conversation leaking from one mind into another.

![herdr drives one pane per agent: architect, security engineer, coder and reviewer each keep their own context and model, so no conversation leaks between them; away from the machine, Tailscale reaches the handler and Moshi follows from a phone (third parties, not affiliated).](agent-handler.svg)

Any handler that isolates sessions works (herdr, orca, and similar). We recommend
**herdr** for its simplicity, and this repository ships its overlay ready: copy
`herdr-config.md` beside a project's `AGENTS.md` and the orchestration rules come
with it.

Away from the machine, two third-party tools improve the flow. They are not
affiliated with this project. **Tailscale** reaches the handler from anywhere, and
**Moshi** follows the agents from a phone: spawn, watch, and answer a question
while away.

## What is in this repository

```
ribbon-protocol/
├── README.md                                  this file
├── LICENSE                                    Apache License 2.0
├── ribbon-protocol-flow.png                    overview image embedded above
├── agent-handler.svg                           handler and agents: one pane, one mind
├── AGENTS.md                                  the protocol in one file, generated from protocol/: the belt, memory, file removal,
│                                              security, the homes, the two flows, the gate, the branches and each seat's part. Copied into every project
├── protocol/                                  the protocol pieces, one file per rule, and README.md: what each holds and how to render it
├── herdr-config.md                            the optional Herdr orchestration overlay, generated from protocol/, copied beside AGENTS.md
├── AGENTS.standalone.md                       the source of the AGENTS.local.md block written by the standalone installer
├── rules/                                     coding conventions, one theme per file, seeded into projects
├── scripts/                                   the standalone installer and its tests
│   ├── ribbon-new-project                     unpacks or updates a per-project standalone instance
│   ├── ribbon-render-protocol                 renders a structure file of protocol/ and the pieces that it includes
│   ├── ribbon-seed-project                    the full install into a project repository
│   ├── standalone-post-checkout               the post-checkout hook template the installer copies into git projects
│   ├── test-ribbon-bash-versions.sh           both installers under real bash 3.2 and 4.4 (opt-in, needs podman)
│   ├── test-ribbon-new-project.sh             the standalone installer's test suite
│   ├── test-ribbon-protocol.sh                the renderer's and the pieces' test suite
│   ├── test-ribbon-seed-project.sh            the full installer's test suite
│   └── test-ribbon-worktree-links.sh          the worktree-link hook's test suite
├── VERSION                                    "ribbon N"
├── Ribbon-Protocol-Multi-LLM-FieldGuide.pdf   the reference guide, October 2026, working edition 1.0
└── docs/                                      copied into every project
    ├── README.md                              the homes: who writes where, who reads what
    ├── field-guide.md                         the PDF as text, for a model without PDF tooling
    ├── adrs/                                  README.md and _template.md: one ADR per design problem
    ├── diagrams/                              README.md: <adr-id>-<name>.mmd, mermaid first
    ├── tasks/                                 README.md, _template.plan.yaml, _template.task.yaml
    └── llm-context/                           README.md, _security.md, _report.md, _note.md, _handoff.md, _done.md, _review.md,
                                               _orchestration.md
```

## Two ways to wear the belt 🎀

**Full install — the whole team wears it.** Seed the repository (the next section):
`docs/` is committed with the project, so every collaborator and agent reads the same
plans, cards, ADRs and evidence, and the decision history is the project's history.

**Standalone — Ribbon for me.** Keep the working files out of the repository: clone this
project to `~/ribbon-protocol`, unpack a per-project instance to `~/ribbon-projects/<name>/`,
and commit only the final artifacts — `docs/adrs/`, `docs/diagrams/` and the `rules/`
conventions — to the project. See "Standalone: Ribbon for me" below.

**Requirements.** Both installers need bash 4.4 or newer, GNU `realpath`, git and
python3. Start them from any shell, zsh included: their first line runs them under bash.
On macOS, `/bin/bash` is 3.2 and `realpath` is BSD's; git and python3 come with Xcode's
Command Line Tools. Install the other two once:

```sh
brew install bash coreutils
```

Homebrew's `bin` must come before `/bin` on `PATH`, which `brew shellenv` arranges. The
installers find Homebrew's `grealpath` on their own.

## Seed a project (full install) 👥

**From the root of your project**, with this repository cloned at `~/ribbon-protocol`, run:

```sh
~/ribbon-protocol/scripts/ribbon-seed-project .
```

The script adds missing `docs/` (homes, schemas, templates, field guide) and `rules/`
(coding conventions) files. Existing paths are kept, including symlinks with missing
targets. Both installers refuse directory symlinks in project `docs/` or `rules/`
instead of following them into another tree. They also refuse unsafe write parents
and planned writes that would change or populate a linked project doc or rule,
including when the link's target is not there yet. An existing
`docs/README.md` is **not edited or appended to**. When the installer creates
`docs/README.md`, it includes the seed version in that new file.
The separate `docs/.ribbon-full-install` record identifies the full install whether
or not the project already had a README. That record must not be ignored by Git.

The script also appends the protocol to the project's `AGENTS.md` (creating one when
none exists), copies `herdr-config.md` beside it, and in a Git repository commits
the installer-written files as one
`Seed the Ribbon Protocol, ribbon N` commit. It refuses to re-seed; a seeded project
merges later template changes by hand (see "Versioning"), and one that predates
`rules/` gets a rules-only amendment instead of a refusal. Point `--ribbon-home` at
the template when it does not live at `~/ribbon-protocol`.

Neither installer creates or edits `CLAUDE.md` or `CLAUDE.local.md`. After a successful
install or update, the installer warns when both files in a pair exist but the Claude
file has no direct AGENTS import or symlink. See the wiring examples below to link them
yourself. If a planned copy would populate a dangling instruction link, the installer
stops before writing project or instance files.

Then fill the belt (next section). Tell your architect to read `AGENTS.md`, the
Ribbon `docs/README.md` if the installer supplied one, and `docs/field-guide.md`.
When `docs/README.md` is project-owned, the protocol's "The homes" section in
`AGENTS.md` still lists Ribbon's paths. An architect inside Herdr also reads
`herdr-config.md` before execution.

## Uninstall a full installation

The uninstall starts with a read-only preview:

```sh
~/ribbon-protocol/scripts/ribbon-seed-project --uninstall .
~/ribbon-protocol/scripts/ribbon-seed-project --uninstall --remove-ribbon .
```

The second command shows the plan and asks `[y/N]`. For a non-interactive
removal, add `--yes`; `--yes` alone does not turn a preview into a removal.
No uninstall command stages or commits changes. If a permission error occurs,
the command stops and reports the affected path and any paths already processed.
It never elevates privileges or recursively deletes directories.

New full seeds write an ownership receipt at `docs/.ribbon-full-install-receipt`.
Uninstall checks the receipt and the current contents before removing individually
recorded, unchanged full-install files or removing an unchanged Ribbon block
from an existing `AGENTS.md`. It preserves ADRs, diagrams, rules, live plans and
reports, and project-owned files. Changed paths are left in place and listed at
the end for manual review. A legacy or incomplete install without a valid
ownership receipt is not removed automatically. This command does not uninstall
or create a separate standalone instance.

The receipt is project data, not a signature. Run removal only in a project
whose contents you trust, and review the preview before confirming.

## Standalone: Ribbon for me 👩

For a project where you want the guardrails but cannot (or do not want to) check the
working files into the repository. Clone this project to `~/ribbon-protocol`.

One rule before you start: **create the directories yourself, then run the scripts.**
The installer never creates the `--projects` directory, and both scripts refuse a path
that does not exist, is not writable with your permissions, or is missing its
`AGENTS.md` — a mistyped path fails with a clear message instead of silently installing
into a fresh, wrong directory.

```sh
# create where your instances will live — the script never creates it for you
mkdir -p ~/ribbon-projects

# unpack an instance for a project
~/ribbon-protocol/scripts/ribbon-new-project --projects ~/ribbon-projects my-project ~/dev/my-project

# when a new "ribbon N" appears: refresh template files and the seed version
# without rewriting any agent instructions, live plans, cards or reports.
# The repo path is read from the instance.
~/ribbon-protocol/scripts/ribbon-new-project --update my-project --projects ~/ribbon-projects

# rebuild an instance from scratch (discards its working files)
~/ribbon-protocol/scripts/ribbon-new-project --force --projects ~/ribbon-projects my-project ~/dev/my-project
```

Both scripts print their full usage with `-h`.

It unpacks `~/ribbon-projects/my-project/` holding `docs/tasks/` and `docs/llm-context/`
seeded from this template, records the seed version, and links the instance to the
project repo. Into the project it writes four small things: `AGENTS.local.md` — a
marked block telling every agent where each file lives and that ADRs and diagrams are
written into the project repository; a one-line pointer in `AGENTS.md` so agents find
that block; `herdr-config.md` beside `AGENTS.md`; and `rules/` — coding conventions
seeded from this project (`testing.md` is universal; add per-language themes as
decisions), committed with the project like code. `AGENTS.local.md` is personal to
your machine: add it to the project's `.gitignore`.

Every `git worktree` you add gets symlinks to this machine's untracked Ribbon files
(`AGENTS.local.md`, `herdr-config.md`, `CLAUDE.md`, `CLAUDE.local.md`) through a managed
`post-checkout` hook the installer places in the project's `.git/hooks`; `--update` refreshes
a hook it owns, while a hook without its mark or a custom `core.hooksPath` is left alone.
The linked files belong in the project's `.gitignore`.

This project uses `AGENTS.md`. If you use Claude Code, connect its instruction
files yourself once per project — either as symlinks in this direction:

    ln -s AGENTS.md CLAUDE.md
    ln -s AGENTS.local.md CLAUDE.local.md

or as imports: add `@AGENTS.md` to `CLAUDE.md` and, if you use a local file,
`@AGENTS.local.md` to `CLAUDE.local.md`. Put each import on its own line. If you use
the Herdr overlay with Claude Code, also add `@herdr-config.md` in the Claude
instructions. The installers do not make these changes for you.

`--projects` has no default: pass wherever your instances should live. `--force`
rebuilds an existing instance; when a new `ribbon N` appears, `--update` refreshes an
instance's template and schema files and seed version. Both modes append a missing
standalone block or pointer but leave existing instructions byte-for-byte intact,
including the filled-in belt. If you relocate an instance or template checkout,
update the paths in `AGENTS.local.md` by hand. Before writing, an update refuses
linked instance directories or refresh targets, and planned writes that would
also change project docs, rules, or instruction files through links. Before
`--force` deletes the old instance, it rejects broken overlay destinations and
symlinks in project docs, rules, instructions, or the overlay that depend on the
instance. `--update` never touches live plans, cards or reports. These operations affect the separate
managed instance; they never replace or delete existing project `docs/` or
`rules/` entries. Instances are personal and unversioned.

## Fill the belt 🎗️

Full install: open your project's `AGENTS.md`, find the table under **The belt** inside
the marked protocol block, and replace every `TODO(belt)`. Standalone: the table lives
in your project's `AGENTS.local.md`, between the `ribbon:belt` marks inside the marked
standalone block — replace every `TODO(belt)` there, leave the shared `AGENTS.md`
alone, and `--update` keeps your rows exactly as written.

- **Senior architect:** a person's name. This role is never an LLM.
- **Architect, Independent reviewer, General coder, Entry-level coder:** the agent's
  nickname, or the vendor and model id when the agent has no nickname. Few people give
  cute names to their partners in crime, and the protocol does not need them.
- **Trusted verifier:** the exact command or commands your gate runs, in order.
- **Security engineer:** retain the Sol 6.1+/Kimi K3.1+ eligibility and effort rules; the architect
  selects a fresh agent for each run, at most three per design, and records the actual
  provider/model/effort.
- Keep the rule that the architect and the reviewer are different models.

Two example belts:

| Role | Belt with nicknames | Belt with vendors |
|---|---|---|
| Senior architect | Lollie | Ana |
| Architect | Kuro-chan, `claude-opus-5-5` | Claude Opus 5.5 |
| Security engineer | fresh Sol 6.1+ or Kimi K3.1+ agent; coin flip when both qualify | OpenAI GPT Sol 6.1+ at xhigh/high, or Moonshot Kimi K3.1+ at high |
| Independent reviewer | Kodo-chan, `gpt-6.1-sol` | GPT 6.1 Sol |
| General coder | Lyn-chan, `glm-5.3`; Kimi-chan, `kimi-for-coding` at high effort | GLM 5.3 |
| Entry-level coder | Lyn-chan flash, `glm-5.3-flash`; Kimi-chan K2.8, `kimi-for-coding` at low effort | GLM 5.3 Flash, Claude Haiku |
| Trusted verifier | `clj-kondo`, `lein nsorg`, `lein splint`, `lein test` | `make check` |

Model names are candidate assignments, not quality rankings. Route by measured task
class and risk; see "Which LLM should do what?" in the field guide.

## Coding rules

The protocol stays language-neutral; craft conventions live in `rules/`, one theme
per file, committed with the project. This project ships `rules/testing.md` —
universal test-craft: never test the test, never test language constructors, one
behavior per test, and a pre-commit refactor checklist. A project adds its own themes
(`rules/clojure.md`, …) as decisions, recorded in the decision log — `rules/README.md`
has the step-by-step. A card names its
themes in `context.read_first`; the coder reads them before the first edit, and the
reviewer checks them like any other contract term. The trusted verifier stays
mechanical — these rules are enforced by review.

Bring your own conventions: on install or update, a terminal run offers a
multi-select of the rule files in `~/.claude/rules` and copies the chosen ones into
the project's `rules/`, so every collaborator and agent works with them. Existing
project themes are never overwritten. A non-interactive run skips with a note;
`--import-rules xunit-patterns.md --import-rules clojure-preferences.md` (one file per
occurrence) does it without a prompt.

The bundled `rules/testing.md` is a theme like any other: customize it in the
project or retire it by removing the file and its card references. `--update`
neither rewrites kept themes nor restores individual deleted ones. If the whole
`rules/` directory or its `README.md` is missing, `--update` treats the project as
one that predates the bundled rules and adds missing files without changing
existing ones. Bring later template revisions into project rules by hand.

## Versioning

`VERSION` holds `ribbon N`. A full installation records its seed version in
`docs/.ribbon-full-install` and recognizes older installations by their Ribbon
stamp in `docs/README.md`. A standalone installation records its version in the
standalone instance's `docs/README.md`, not the project's. When a new
`ribbon N` appears, a standalone instance refreshes with `scripts/ribbon-new-project
--update <name> --projects DIR` — template and schema files and seed version, never
existing agent instructions, live plans, cards or reports. A full-installed project
merges by hand: diff your `docs/` against the template's and copy what changed,
update the Ribbon instructions in `AGENTS.md` without disturbing the project's own
instructions, and copy `herdr-config.md` beside it. Preserve the project's own
Claude instructions.

## The reference guide

`Ribbon-Protocol-Multi-LLM-FieldGuide.pdf` at the root is the historical reference edition.
`docs/field-guide.md` is its text, page for page, so a model can read it without PDF tooling.
Neither includes later protocol amendments such as the security-engineer checkpoint; current
`AGENTS.md`, schemas and templates govern, with `herdr-config.md` governing Herdr orchestration.
The guide is a reusable engineering framework, not a claim that any model will follow every
instruction. Verify current model capabilities, pricing and provider terms when you
implement routing. Organisational security policy always overrides personal workflows.

## Questions, bugs, ideas ❓

File an issue on [GitHub](https://github.com/hai-lollie/ribbon-protocol/issues) and
flag it with one label:

- **`bug`** — something misbehaves: a script fails, a template is wrong, or the docs
  contradict the code.
- **`documentation`** — something is unclear, missing or wrong in the docs.
- **`enhancement`** — an idea that would make the protocol better.

Pull requests are not accepted at this time; issues that make sense for the project
will be picked up and worked on. A short issue with one concrete example beats a long
one with abstractions.

## License

Copyright 2026 Lollie (hai-lollie)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
work except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
