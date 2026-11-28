# Ribbon Protocol, standalone mode

This project runs [Ribbon Protocol](https://github.com/hai-lollie/ribbon-protocol) in
standalone (personal) mode: the protocol's working files live outside this repository
in a per-project instance under `{{RIBBON_PROJECTS}}`. Only the final artifacts live
in this repository.

This file is the project's `AGENTS.local.md`: personal to this machine, kept out of
version control (add it to `.gitignore`). `AGENTS.md` carries a one-line pointer to
this file and nothing more.

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
- Read the coding-rule themes your card names from `{{PROJECT_REPO}}/rules/` before
  the first edit; the reviewer checks them like any other contract term.
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
