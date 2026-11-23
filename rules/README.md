# Coding rules — one theme per file

This directory holds the project's coding conventions, split by theme. The
protocol stays language-neutral; the rules here are craft: how tests are
written, how a language is used idiomatically, how evidence is produced.

## The contract

- The **plan** decides which themes apply to a story's cards.
- A **card** names its themes in `context.read_first`; the coder reads those
  files before the first edit.
- The **reviewer** checks adherence like any other contract term.
- The **trusted verifier** stays mechanical; these rules are enforced by
  review, not by the gate.

## Themes

| File | Scope |
|---|---|
| `testing.md` | universal test-craft, any language |
| `<language>.md` | per-language idioms (for example `clojure.md`), added by the project |

## Adding a theme

A theme is plain markdown with imperative rules, one file per theme. To
install one:

1. **Drop the file into `rules/`** — for example `rules/clojure.md` — or
   import it from your machine with the installer's picker or
   `--import-rules`. The file alone only makes the theme available.
2. **Name it in the cards that must follow it** — the architect adds the
   theme to a card's `context.read_first`, next to the files the card
   already names. New cards name it from the start; cards already in
   flight get a revised card from the architect.
3. **Record the decision** — adding or changing a theme is a project
   decision; enter it in the decision log like any design change.

Then the contract does the rest: the coder reads the named themes before
the first edit, and the reviewer checks adherence like any other contract
term. Nothing auto-reads `rules/` — a theme nobody names reaches no agent,
which is what keeps contexts small.

To retire a theme, `rm` its file and remove its name from the cards that
referenced it; `--update` never resurrects a deleted theme. Keep themes
small; a theme that needs a table of contents is two themes.
