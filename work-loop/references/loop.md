# Coding Loop

Use this reference after the plan has been approved.

Do not use this workflow before explicit approval. Before approval, only initialize or revise planning artifacts; do not run `./init.sh`, install dependencies, start servers, edit application code, or mark tasks as passing.

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
13. Write a `progress.md` entry using the session template below.
14. If commits are available, commit all changes for this one task as one coherent change.
15. In continuous mode, repeat from the regression check until the task budget is exhausted, a blocker appears, or the backlog is complete.

## Execution modes

- `checkpoint`: complete one unblocked task, then stop after progress and commit.
- `continuous`: continue selecting the next unblocked task after each successful commit.
- `automation-loop`: stop the interactive loop and let `run-automation.sh` relaunch fresh sessions. Use only after one manual approved task has completed successfully.

## Task selection priority

Select work in this order:

1. Fix any regression in a previously passing task.
2. Choose a task whose `depends_on` tasks are all passing.
3. Prefer foundations before dependent features: project setup, data models, services, APIs, then UI.
4. Among equally unblocked tasks, follow the order in `task.json`.

## Session entry template

Append this shape to `progress.md` after a completed task:

```markdown
## Session N - Task: task-id

### What changed
- Files or areas changed.

### Steps
- [x] Step that was completed.

### Acceptance
- [x] Acceptance result and evidence.

### Verification
- Command, manual check, screenshot, or reason a check was not applicable.

### Issues
- None, or the issue and how it was resolved.

### Next
- Next unblocked task, remaining blocker, or completion state.
```

## Clean-state check

Before ending an execution session:

- run the relevant build/test command or record why it cannot run
- verify `task.json` only flips completed `passes` fields during normal execution
- verify `progress.md` has the current session entry
- commit one task's source changes, task status, and progress update together when commits are available
- check `git status`; leave a clean worktree or clearly document remaining changes

## Failure handling

If the task cannot complete, do not mark it as passed. Record:

- what was attempted
- the exact failure or missing input
- which step, acceptance item, or verification check failed
- which files were changed
- the safest next step

Then stop instead of drifting into unrelated work.

Common blockers include missing API keys, external accounts, paid services, failing dependency installation, unavailable local ports, or a development server that will not start.

Use this blocker template:

```markdown
## Session N - BLOCKED: task-id

### Blocker
- Exact blocker and where it occurred.

### What was completed
- Any safe partial work that remains.

### What is needed
- Specific human action, credential, decision, or environment repair.

### Resume instructions
- What the next session should do after the blocker is resolved.
```
