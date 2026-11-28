# The protocol pieces

Each rule of the Ribbon Protocol lives in one file here. `scripts/ribbon-render-protocol` renders a
structure file and the pieces that it includes into one text:

- `whole-structure.md` renders the root `AGENTS.md`, the whole protocol in one file;
- `handlers/herdr_template.md` renders `herdr-config.md`, the optional Herdr overlay.

Edit a piece, never a rendering. Then render again, from the repository root, through a
fresh temporary file, so that a failed rendering leaves the old one in place:

    tmp="$(mktemp)" && scripts/ribbon-render-protocol whole-structure.md > "$tmp" && cp "$tmp" AGENTS.md
    tmp="$(mktemp)" && scripts/ribbon-render-protocol handlers/herdr_template.md > "$tmp" \
      && cp "$tmp" herdr-config.md

`scripts/test-ribbon-protocol.sh` fails when a rendering differs from its pieces.

| Piece | Holds |
|---|---|
| `belt.md` | the principle, the seven roles of the belt and the routing rules |
| `homes.md` | the homes: who writes where |
| `guidance/memory.md` | who may write memory |
| `guidance/file-removal.md` | who may remove files |
| `guidance/security.md` | approved providers only |
| `guidance/branches.md` | the branches, and who changes them |
| `flows/adr.md` | the loop's design steps and the security design review |
| `flows/implementation.md` | when the loop stops, its build steps, the decision budget, a plan and its cards, the coder's seven steps |
| `flows/trusted-verifier.md` | the trusted verifier and its gate |
| `actors/<seat>_template.md` | each seat's part, and the reviewer's brief |
| `handlers/herdr_template.md` | the Herdr overlay |
