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
| Protocol text (read-only) | `{{RIBBON_HOME}}/AGENTS.md` |
| Field guide | `{{RIBBON_HOME}}/docs/field-guide.md` |
| Plans, cards, acceptance files | `{{INSTANCE}}/docs/tasks/` |
| Reports, notes, handoff, evidence | `{{INSTANCE}}/docs/llm-context/` |
| ADRs and diagrams (final artifacts) | `{{PROJECT_REPO}}/docs/adrs/`, `{{PROJECT_REPO}}/docs/diagrams/` |

## The belt

Fill this table in — it is yours, in this local file. Replace every `TODO(belt)`:

| Role | Agent | Model | Writes | Never |
|---|---|---|---|---|
| Senior architect | TODO(belt): a person's name | human | the problem, the constraints, what success looks like, the acceptance criteria or test bodies; validates ADRs and plans | reads code line by line |
| Architect | TODO(belt): "Kuro-chan" or "Claude Opus" | TODO(belt): claude-opus-5-5 | ADRs, plans, cards, answers to notes | directly editing production code for its own card |
| Security engineer | a fresh agent selected by the architect | OpenAI GPT Sol 6.1+ or Moonshot Kimi K3.1+; Kimi at high effort | an ADR security report with findings and mitigations | ADRs, code, commits; accepting risk for the senior architect |
| Independent reviewer | TODO(belt): "Kodo-chan" or "GPT Sol" | TODO(belt): gpt-6.1-sol | findings and verdicts | code; a review of a plan it architected |
| General coder | TODO(belt): "Lyn-chan" or "GLM 5.3" | TODO(belt): glm-5.3 | the patch and its evidence, inside scope | a shape the contract does not define; a protected path |
| Entry-level coder | TODO(belt): "Lyn-chan flash" or "GLM 5.3 Flash" | TODO(belt): glm-5.3-flash | small patches inside the allowlist | a correctness decision |
| Trusted verifier | the gate: TODO(belt): the exact commands | tools | machine PASS or FAIL | trust a sentence |

The architect and the reviewer of one plan are different models, from different vendors
when possible; every plan names both.

## Rules for every agent

- Read the protocol at `{{RIBBON_HOME}}/AGENTS.md`; it governs this project unchanged,
  every role and step as written.
- Treat `{{INSTANCE}}/docs/` as this project's `docs/`: read plans and cards from
  `{{INSTANCE}}/docs/tasks/`, write reports, notes, handoff and evidence to
  `{{INSTANCE}}/docs/llm-context/`.
- Write ADRs and diagrams only under `{{PROJECT_REPO}}/docs/adrs/` and
  `{{PROJECT_REPO}}/docs/diagrams/`, committed on the story's contract branch.
- Do not create a `docs/tasks/` or `docs/llm-context/` tree in this repository;
  that is what standalone mode means.

## Herdr orchestration

`herdr-config.md` sits beside this file. An orchestrating architect writes
orchestration reports to `{{INSTANCE}}/docs/llm-context/<plan-id>-orchestration.md`,
not under this repository.

The instance was seeded as `{{PROJECT_NAME}}`; its recorded seed version and linked
repo path live in `{{INSTANCE}}/docs/README.md` and `{{INSTANCE}}/project-repo`.
