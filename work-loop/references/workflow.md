# Workflow

Use this reference for approval, initialization, execution, and automation.

## Fresh Session

At the start of every new interactive or automated session, read:

1. `CLAUDE.md` or `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

Do not rely on previous chat context. After that, read only the source files relevant to the selected task.

## Before Approval

Allowed:

- inspect the repository
- create or revise `architecture.md`, `task.json`, `progress.md`, `AGENTS.md`, and `CLAUDE.md`
- create `init.sh` and `run-automation.sh` as files
- ask the user to review the plan and reply with `approve`, `go ahead`, `LGTM`, `批准`, or `同意执行`

Forbidden:

- run `./init.sh`
- install dependencies
- start development servers
- edit business or application code
- execute tasks from `task.json`
- change `approval.status` to `approved`
- mark tasks `passes: true`
- run `run-automation.sh`

After explicit approval, set `task.json.approval.status` to `approved`, fill `approved_by` and `approved_at` when practical, then begin execution.

## Initialization

When Work Loop files are missing, create:

- `architecture.md`: goal, non-goals, repo facts, approach, interfaces, verification strategy
- `task.json`: task queue following `task-schema.md`
- `progress.md`: current state plus templates from `handoff.md`
- `init.sh`: idempotent environment setup, but do not run before approval
- `AGENTS.md` and `CLAUDE.md`: project instructions with the same approval and execution rules
- `run-automation.sh`: optional outer-loop script, but do not run before approval

Do not overwrite existing files unless the user asks for replacement.

## Execution Modes

- `checkpoint`: complete one unblocked task, update progress, commit when available, then stop.
- `continuous`: continue to the next unblocked task after each successful task. Do not ask whether to continue unless a stop condition appears.
- `automation-loop`: use `run-automation.sh` to relaunch fresh sessions. Use only after at least one approved task has completed manually and the user approves unattended execution.

## Per-Task Loop

1. Confirm approval.
2. Run `./init.sh`.
3. Regression-check 1-2 tasks already marked `passes: true`.
4. Select the first unblocked task using `task-schema.md`.
5. Implement only that task.
6. Complete every `steps` item.
7. Satisfy every `acceptance` item.
8. Run every feasible `verification` check.
9. Set `passes` to `true` only when all checks pass.
10. Add a session entry to `progress.md` using `handoff.md`.
11. Commit this task as one coherent change when commits are available.
12. Run the clean-state check.

## Stop Conditions

Stop instead of continuing when:

- all tasks are complete
- no incomplete task is unblocked
- a regression appears
- a step, acceptance item, or verification check fails
- required credentials, tools, accounts, or services are missing
- context is getting too large; write `progress.md`, then ask the user to start a fresh session

## Clean-State Check

Before ending:

- run build/test or record why it cannot run
- verify `task.json` accurately reflects completed work
- verify `progress.md` has the current session or blocker entry
- commit one task's source changes, task status, and progress update together when possible
- check `git status`; leave a clean worktree or clearly document remaining changes
