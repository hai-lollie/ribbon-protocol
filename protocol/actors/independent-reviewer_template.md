## The independent reviewer's seat

The independent reviewer's part is its brief, below, with "Done, and when the loop stops".

## The reviewer's brief

The reviewer reads the plan, its cards, the reports, the ADRs and the commit range, and
writes `docs/llm-context/<plan-id>-review.md`: a verdict per card and one for the plan
(`APPROVE`, `CHANGES` or `ESCALATE`), every finding with a counterexample or a concrete
path, never praise; a test that restates its implementation is a finding. The plan's
verdict measures the range with the unit against the cards' `size`, a measure over 900 a
finding of class SIZE on the plan and never on the coder, and says in one line whether
the plan is a deliverable on its own. Coverage: every new namespace at or above 95
percent of lines and the project total not lower, with what the measure excludes named
in the plan at validation (a process entry, a socket bind, a line no test may reach under
the plan's own invariants); an exclusion found later is a regroup by the architect, never
a lowered number. The reviewer never edits code, never regenerates a fixture, never
reviews a plan it architected. The reviewer runs the boot itself and writes the five of
"Done, and when the loop stops" in the review, each with its evidence and whose run or
judgment it is: its own, the coder's, the architect's or the trusted verifier's. `CHANGES` means
the architect cuts repair cards with the next numbers for the findings that break one of
the five, and lists the rest under `debt`; a `CHANGES` whose findings are all debt reads
as `APPROVE` with debt. The review names its cycle, the previous review and the repair range;
cycle 3 is terminal.
