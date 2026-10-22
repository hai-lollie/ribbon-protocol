# NNNN. The proposal in one small line, in the user's words

Status: proposed
Implemented by: none yet
Diagrams: docs/diagrams/NNNN-<name>.mmd

## Abstract

The decision in three to five sentences: the problem, what we will implement, what it
gives us, what it costs.

## Introduction

Why we are here: the contract, the constraint, the review or the failure that raised the
question, with enough of the history that a reader new to the project follows.

## Glossary

At most six rows, only the project's own words; a term a reader can look up stays out.

| Word | Meaning |
|---|---|
| <a word of this project> | <its meaning in one line> |

## Problem at hand

The problem in detail. A table of examples: the input, what happens today, what must
happen. A sequence diagram when the problem is a flow. The articles or the standards
that frame it, linked under References.

## Proposed solution

We will implement <the pattern or the practice, linked under References>. <The pattern>
will allow us to <what it makes possible here>. This gives us <the benefits> at the cost
of <the consequences>.

Then: the rules of the solution as a table; the flow as a sequence diagram, its relative
path on the line above a mermaid block that is a copy of the file; the invariants a test
must cover. What stays undecided goes under Open questions.

docs/diagrams/NNNN-<name>.mmd

```mermaid
sequenceDiagram
  participant A as <a participant>
  participant B as <another>
  A->>B: <the call>
  Note over B: <the schema, the HTTP line, the snippet the reader needs>
  alt <a condition>
    B-->>A: <one answer>
  else
    B-->>A: <the other>
  end
```

## Alternatives

- **<An alternative>.** Why it was considered, in two lines. Why it was ruled out, in two
  lines. About 75 words in all.

## Reconsider when

- <a condition that reopens this decision, one per bullet, checkable>

## Open questions

What the architect needs answered to finish the design, numbered from 1, at least one.
A question keeps its number. A check mark in front means answered or closed; a question
without one is pending. The architect writes no plan and no card while a question is
pending. When the architect finds no question at all, this section is the single line:
No open questions found. 👀

1. <the question, pending: no check mark, no answer under it yet>
2. ✅ <the question, answered>

   A: <the answer, in one or two lines>. [YYYY-MM-DD]

3. ✅ <del><the question, closed: it no longer matters></del>

## References

- <Title>, <author or standard>: <link>
- <a changelog entry or a contract section, by id>

## Date and edits

| Date | Edit | Asked by |
|---|---|---|
| YYYY-MM-DD | the first draft | <who> |

Edits: 0.
