## Your seat's files

Each seat's own rules are files under `{{PROTOCOL_DIR}}/`. Read your seat's files before your first
action. The architect names them in every briefing, and every card's `context.read_first` starts
with the coder's, so the preflight commit proves that they were read before the first edit.

| If you are | Read |
|---|---|
| the senior architect | `{{PROTOCOL_DIR}}/actors/senior-architect.md`, `{{PROTOCOL_DIR}}/flows/adr.md` and `{{PROTOCOL_DIR}}/flows/implementation.md` |
| the architect | `{{PROTOCOL_DIR}}/actors/architect.md`, `{{PROTOCOL_DIR}}/actors/trusted-verifier.md`, `{{PROTOCOL_DIR}}/guidance/branches.md`, `{{PROTOCOL_DIR}}/flows/adr.md`, `{{PROTOCOL_DIR}}/flows/implementation.md` and `{{PROTOCOL_DIR}}/flows/trusted-verifier.md`; also `{{PROTOCOL_DIR}}/handlers/herdr.md` when `test "${HERDR_ENV:-}" = 1` succeeds |
| the security engineer | `{{PROTOCOL_DIR}}/actors/security-engineer.md` and `{{PROTOCOL_DIR}}/flows/adr.md` |
| the independent reviewer | `{{PROTOCOL_DIR}}/actors/independent-reviewer.md`, `{{PROTOCOL_DIR}}/flows/implementation.md` and `{{PROTOCOL_DIR}}/flows/trusted-verifier.md` |
| a general coder | `{{PROTOCOL_DIR}}/actors/general-coder.md` and `{{PROTOCOL_DIR}}/flows/implementation.md` |
| an entry-level coder | `{{PROTOCOL_DIR}}/actors/entry-level-coder.md` and `{{PROTOCOL_DIR}}/flows/implementation.md` |

An update replaces these files and the rest of this block, as "The belt" says.
