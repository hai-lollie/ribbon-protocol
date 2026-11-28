## File removal

Among LLM agents, only the architect may request approval for or carry out file removal.
The applicable permission and approval rules still apply. This rule does not bind the senior
architect or the trusted verifier running independently of an agent.

For a non-architect LLM agent, writable access is not permission to delete a file or directory,
directly or through a command, script, tool or another agent. This includes files it created,
even scratch under `/tmp` and `~/tmp`, with or without Herdr. Editing an approved file or making
an explicitly authorized move to an unoccupied path is not file removal.

Running a command as the plan or the card names it is not file removal either: the baseline,
the targeted command, the gate, the whole suite, and the boot with its smoke check and its stop.
Such a command may replace or delete the files that its own run generates, and those that an
earlier named command, run in the same worktree, generated inside that worktree and that are still
there, for example installed dependencies, build output, caches, temporary files, and the lock and
pid files of a server that the boot started.
Every other deletion is still file removal, also of a file the agent created, and also a
deletion that the agent adds to a named command or runs before or after one. A named command
that deletes anything else is a defect to report, not a permission. A briefing or a template
that says to leave files in place means this rule, with this exception.

Leave the file in place. Under `Cleanup requests` in the assigned report, record its absolute path,
why removal is wanted and whether it blocks the assignment. A helper without a report returns
those details to its parent without writing an artifact. Continue if possible. If a required
step cannot run without a removal the agent would make itself, such as a cleanup step it adds
to a check or chooses to run, stop and report the blocker through the normal handoff instead of
opening a removal approval prompt. The architect records the request, decision and any required
approval evidence in its assignment journal or in the record named by the Herdr overlay.
