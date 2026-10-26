# <plan-id> done

The coder's answer to "Done, and when the loop stops" (root `AGENTS.md`), written at the
plan's last card, before the review. Each row names a command, its exit code and the file
under `docs/llm-context/evidence/<plan-id>-done/` that holds its output; a row the coder
cannot prove says so, and the plan is then not ready for review.

Coder: <agent>, <model id>. Head: <commit hash>. Date: <YYYY-MM-DD>.

| Holds | Evidence |
|---|---|
| the gate, locally and on the trusted verifier | <each command, exit code, output file; the verifier's run id> |
| the boot by the entry point a person runs, its smoke check, its stop | <the command, the output file's first lines, the exit code, the stop> |
| the acceptance file, name for name | <the count of tests under their canonical names, the command> |
| coverage at the plan's line | <the numbers, the output file> |
| no open SEMANTIC or SCOPE finding on production code | the reviewer's |

Debt the coder knows of, if any: <one line each, or none>.
