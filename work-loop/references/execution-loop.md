# Execution Loop

Use this reference only after explicit approval.

Before approval, return to `approval-gate.md`.

## Fresh session startup

At the start of every new interactive or automated session, read these files before taking action:

1. `CLAUDE.md` or `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

Do not rely on previous chat context. Use these files as the source of truth, then read only the source files relevant to the selected task.

## Execution modes

- `checkpoint`: complete one unblocked task, then stop after progress and commit.
- `continuous`: keep selecting the next unblocked task until the backlog is complete, a blocker appears, a regression appears, the configured task budget is reached, or context should be refreshed. Do not ask whether to continue after each successful task.
- `automation-loop`: use `run-automation.sh` to relaunch fresh sessions and keep disk logs. Use only after at least one manual approved task has completed successfully.

## Per-task loop

1. Read `task.json`, `progress.md`, and the relevant part of `architecture.md`.
2. Confirm `approval.status` is `approved`, or that the user just approved the plan.
3. Run `./init.sh` to install dependencies, prepare local state, and start a development server when available.
4. Run a regression check for 1-2 tasks already marked `passes: true`.
5. Select the first unblocked task using the rule in `task-schema.md`.
6. Review the task's `id`, `title`, `category`, `description`, `depends_on`, `steps`, `acceptance`, and `verification`.
7. Implement only the selected task.
8. Complete each `steps` item.
9. Check every `acceptance` item.
10. Run every feasible `verification` command or manual check.
11. If all checks pass, set the task's `passes` to `true`.
12. Add a session entry to `progress.md` using `progress-handoff.md`.
13. If commits are available, commit this one task as one coherent change.
14. Run the clean-state check.
15. Continue or stop based on the execution mode. In `continuous` mode, continue automatically to the next unblocked task after a successful task; do not ask the user whether to continue unless a stop condition appears.

## Task priority

When multiple tasks are unblocked:

1. Fix any regression in a previously passing task first.
2. Prefer foundations before dependent features: project setup, data models, services, APIs, then UI.
3. Among equally unblocked tasks, follow the order in `task.json`.

## Clean-state check

Before ending an execution session:

- run the relevant build/test command or record why it cannot run
- verify `task.json` only flips completed `passes` fields during normal execution
- verify `progress.md` has the current session or blocker entry
- commit one task's source changes, task status, and progress update together when commits are available
- check `git status`; leave a clean worktree or clearly document remaining changes

## Stop conditions

Stop instead of continuing when:

- all tasks are complete
- no incomplete task is unblocked
- a regression appears
- a step, acceptance item, or verification check fails
- required credentials, tools, accounts, or services are missing
- the task budget is reached
- context is getting too large; write `progress.md`, then ask the user to start a fresh session
