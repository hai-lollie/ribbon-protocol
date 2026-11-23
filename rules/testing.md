# Testing — universal test-craft

Source: Gerard Meszaros, *xUnit Test Patterns*, and house refinements.
Language-specific idioms live in `<language>.md`; this file holds what holds
in every language. Test code is production code: same refactor discipline,
same review bar.

## The two hard rules

1. **Never test the test.** The subject of a test is the system under test,
   never the test machinery itself. A test that asserts a stub returns its
   canned answer, that the framework's assertion works, or that the fixture
   assembled itself proves nothing. Operational check: delete the exercise —
   the call to the code under test — and the test must go red. If it stays
   green, it tested the test. Heuristic, not proof: a correct test can also
   stay green when the exercise is removed (for example, a test that an
   ignored event sends no notification). Treat a green deletion as a flag
   for review, never as a verdict by itself.
2. **Never test language constructors.** Never test the language or its
   standard library: constructors, core operators, getters, collection
   literals. `assertEquals(2, 1 + 1)` is not a test of your code.
   Operational check: a test that would still pass if your production code
   did not exist is not a test of your production code.

## Structure

- **Four-phase test: Setup, Exercise, Verify, Teardown.** Each phase visible
  in order; teardown is often implicit. Given–When–Then is the same shape.
  Flag missing phases, not unconventional naming.
- **One behavior per test.** Several assertions are fine only when they
  verify the same behavior (fields of one response, steps of one state
  change). A test you would rename if you split it must be split. Smell:
  *Assertion Roulette*.
- **Small tests, small suites.** A test reads top to bottom without
  scrolling; a test file covers one domain seam. When two test files need
  the same small kit, duplicate it per file — never a shared helper dumping
  ground that couples unrelated tests.

## Naming

- Intention-revealing, spec-sentence shape: `flush-beats-straight`,
  `returns-401-when-token-expired`, `widget-rejects-negative`.
- Pattern: `<unit>_<scenario>_<expected-outcome>`, or BDD's
  `<context> <action> <outcome>`.
- Bad: `test_1`, `it-works`, `verify-stuff`.

## Fixtures

- **Inline setup** for test-specific values.
- **Implicit setup** (per-test hooks) for genuinely shared fixtures only.
- **Named creation method / test data builder** for complex fixtures — a
  named call beats a 12-line literal.
- Smell: *Mystery Guest* — a test that depends on data it did not create.

## Verification and doubles

- **State verification is the default**: assert on return value or final
  state.
- **Behavior verification** (mock interactions) only where the interaction
  *is* the contract. Mock-heavy tests lock implementation and break on
  refactors with no behavior change: *Overspecified Software*.
- **Use the lightest double that does the job**: dummy, stub, spy, mock,
  fake. Prefer passing the test version of a dependency over mocking it.
- **Parameterized tests**: a table-driven loop over near-duplicate cases
  beats copy-pasted tests — put the row in the failure message so a failure
  localizes.

## Smells to refuse in review

- *Conditional Test Logic* — `if`/`when` around assertions; split the test.
- *Obscure Test* — too much setup, hidden state.
- *Fragile Test* — breaks on unrelated changes (usually overspecified or a
  mystery guest).
- *Erratic Test* — flaky; order, time, or shared-state coupling.
- *Slow Test* — slower than its tier allows.

## Refactor checklist (post-GREEN, pre-commit)

1. Phases readable in order?
2. Name describes behavior, not mechanics?
3. One behavior — would you rename it if you split it? Split.
4. Every fixture value visible or behind a named creation method?
5. No conditional logic controlling assertions.
6. No assertion roulette — same-behavior asserts, or per-assert messages.
7. Right double — mocks only where interaction is the contract.
8. No mystery guest.
9. Idiomatic for the framework (`describe`/`it`, `testing`, pytest
   classes, …).
10. Not testing the language or the library (hard rule 2).
11. Deleting the exercise turns the test red — where the exercise is the
    behavior under test (hard rule 1's heuristic; a green deletion is a
    flag for review, not a verdict).
