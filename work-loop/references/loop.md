# Coding Loop

Use this reference after the plan has been approved.

## Per-task loop

1. Read `task.json`, `progress.md`, and the relevant part of `architecture.md`.
2. Confirm `approval.status` is `approved`, or that the user just approved the plan in the current conversation. If not, stop and ask for approval.
3. Run `./init.sh` to install dependencies, prepare local state, and start the development server when the project has one.
4. Run a regression check for 1-2 tasks already marked `passes: true`.
5. Select the first task where `passes` is false and every task ID in `depends_on` is already `passes: true`.
6. If no incomplete task is unblocked, stop and record which dependencies are blocking progress.
7. Review the task's `id`, `title`, `category`, `description`, `depends_on`, `steps`, `acceptance`, and `verification`.
8. Implement only the selected task.
9. Complete each `steps` item.
10. Check every `acceptance` item.
11. Run every feasible `verification` command or manual check.
12. If all checks pass, set the task's `passes` to true.
13. Write a `progress.md` entry with:
   - task ID, title, category, and description
   - dependency status
   - files or areas changed
   - completed steps
   - acceptance results
   - verification output or screenshots
   - next task or completion state
14. If commits are available, commit all changes for this one task as one coherent change.
15. In continuous-batch mode, repeat from the regression check until the task budget is exhausted, a blocker appears, or the backlog is complete.

## Failure handling

If the task cannot complete, do not mark it as passed. Record:

- what was attempted
- the exact failure or missing input
- which step, acceptance item, or verification check failed
- which files were changed
- the safest next step

Then stop instead of drifting into unrelated work.

Common blockers include missing API keys, external accounts, paid services, failing dependency installation, unavailable local ports, or a development server that will not start.
