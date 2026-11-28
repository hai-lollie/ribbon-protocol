# Ribbon Protocol, standalone mode

This project runs [Ribbon Protocol](https://github.com/hai-lollie/ribbon-protocol) in
standalone (personal) mode: the protocol's working files live outside this repository
in a per-project instance under `{{RIBBON_PROJECTS}}`. Only the final artifacts live
in this repository.

This file is the project's `AGENTS.local.md`: personal to this machine, kept out of
version control (add it to `.gitignore`). Ribbon adds one line to `AGENTS.md`: a pointer
to this file.

## Where everything lives

| What | Where |
|---|---|
| Each seat's files (read-only) | `{{INSTANCE}}/.ribbon/protocol/` |
| Field guide | `{{RIBBON_HOME}}/docs/field-guide.md` |
| Plans, cards, acceptance files | `{{INSTANCE}}/docs/tasks/` |
| Reports, notes, handoff, evidence | `{{INSTANCE}}/docs/llm-context/` |
| ADRs and diagrams (final artifacts) | `{{PROJECT_REPO}}/docs/adrs/`, `{{PROJECT_REPO}}/docs/diagrams/` |
| Coding rules, one theme per file | `{{PROJECT_REPO}}/rules/`, committed with the project |

## Rules for every agent

- This block and your seat's files are the protocol; they govern this project unchanged,
  every role and step as written.
- Treat `{{INSTANCE}}/docs/` as this project's `docs/`: read plans and cards from
  `{{INSTANCE}}/docs/tasks/`, write reports, notes, handoff and evidence to
  `{{INSTANCE}}/docs/llm-context/`.
- The instance is not a Git repository. Where a rule reads a card from Git
  (`git show main:docs/tasks/<task-id>.yaml`), read it from `{{INSTANCE}}/docs/tasks/`:
  the architect revises a card there and tells the coder, and no merge carries it. Where a
  rule commits the preflight block, the coder writes the block in its report in the instance
  and, before the first edit, makes an empty commit `<task-id>: preflight READY` (or
  `BLOCKED`) in this repository, so Git still proves the order. Where a rule commits evidence
  with the work, or moves closed work into `docs/llm-context/history/` with `git mv`, the
  evidence stays in the instance, uncommitted, and closed work moves there with `mv`.
- The coding-rule themes that a card names live in `{{PROJECT_REPO}}/rules/`.
- Write ADRs and diagrams only under `{{PROJECT_REPO}}/docs/adrs/` and
  `{{PROJECT_REPO}}/docs/diagrams/`, committed on the story's contract branch.
- Do not create a `docs/tasks/` or `docs/llm-context/` tree in this repository;
  that is what standalone mode means.

The instance was seeded as `{{PROJECT_NAME}}`; its recorded seed version and linked
repo path live in `{{INSTANCE}}/docs/README.md` and `{{INSTANCE}}/project-repo`.

<!-- ribbon:include belt.md -->

<!-- ribbon:include guidance/memory.md -->

<!-- ribbon:include guidance/file-removal.md -->

<!-- ribbon:include guidance/security.md -->

<!-- ribbon:include homes.md -->

<!-- ribbon:include seats.md -->
