## The trusted verifier and its gate

The gate is the exact list of commands that decides PASS or FAIL outside the coder's control.
The commands differ by project, language and framework, so the belt names them, in order. A gate
holds the kinds of check that the project has:

- code analysis;
- the linter;
- the formatter, in check mode;
- the unit tests;
- the acceptance tests, under the canonical names of the plan's acceptance file;
- the integration tests;
- the coverage measure, against the plan's line.

The person who installs the protocol fills in the commands. While the belt still holds
`TODO(belt)` for the gate, the architect proposes commands from the project's build files, and the
senior architect confirms them before the first plan. The boot of "Done, and when the loop stops"
is not a gate command: it runs by the entry point that a person runs.
