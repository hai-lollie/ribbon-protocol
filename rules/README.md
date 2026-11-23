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

A theme is plain markdown with imperative rules. Adding or changing one is a
project decision: propose it like any design change and record it in the
decision log. Keep themes small; a theme that needs a table of contents is
two themes.
