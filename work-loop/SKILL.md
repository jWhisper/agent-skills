---
name: work-loop
description: Use this skill for long-running coding work that needs planning, human approval, task-by-task execution, verification, progress handoff, and compatibility with both Codex and Claude Code.
---

# Work Loop

Work Loop is a lightweight harness for keeping long coding tasks recoverable. Use it when a request is larger than one focused edit, may span sessions, or needs Codex and Claude Code to share the same project workflow.

## Core Flow

1. Ground in the repository before planning. Read the README, existing agent instructions, package files, test commands, and relevant source paths.
2. If Work Loop files are missing, proactively create them in the current repository. Use `scripts/setup-harness.sh` when available; otherwise create the files described in `references/setup.md` directly.
3. Do not implement project code until `task.json.approval.status` is `approved` or the user clearly approves the plan in the current conversation.
4. After approval, follow `task.json.execution.default_mode_after_approval`. By default, keep working through the backlog in continuous mode instead of stopping after one task.
5. Before changing code for a task, initialize the environment. Run `./init.sh` whenever it exists. The script is expected to install dependencies, prepare local state, and start the development server if the project has one.
6. Run a regression check on 1-2 already passing tasks before starting new work.
7. Pick the first task with `"passes": false` whose `depends_on` tasks are all already passing; implement only that task.
8. Run the task's `steps`, `acceptance`, and `verification` checks.
9. Mark the task as passed only after every required check is satisfied.
10. Add a concise entry to `progress.md` with changes, acceptance results, verification output, and the next task.
11. Commit one completed task at a time when commits are available in the repo workflow.

Task `id` is required, unique, and stable. Prefer readable string IDs such as `project-setup` or `quiz-flow`; use them in `depends_on`, progress notes, and commit messages.

## Execution Modes

- `checkpoint`: complete one unblocked task, update status and progress, commit if possible, then stop.
- `continuous`: keep repeating the same task loop until the backlog is complete, a blocker appears, a regression appears, or the configured task budget is reached.
- `automation-loop`: use `scripts/run-automation.sh` to relaunch fresh sessions and keep disk logs. Use only after at least one manual approved task has completed successfully.

## Approval Gate

Before approval, only planning and harness setup are allowed:

- inspect the repository
- create or update `architecture.md`, `task.json`, `progress.md`, `AGENTS.md`, and `CLAUDE.md`
- create `init.sh` and `run-automation.sh` as files, but do not run them
- ask the user to review the plan and reply with `approve`, `go ahead`, `LGTM`, `批准`, or `同意执行`

Before approval, do not:

- run `./init.sh`
- install dependencies
- start development servers
- edit business/application code
- execute tasks from `task.json`
- change `approval.status` to `approved`
- mark any task `passes: true`
- run `scripts/run-automation.sh`

After explicit approval, immediately set `task.json.approval.status` to `approved` with `approved_by` and `approved_at` when practical, then enter the execution loop.

After approval, task definitions are frozen during normal execution. Do not rewrite `id`, `title`, `description`, `depends_on`, `steps`, `acceptance`, or `verification` unless the user asks to revise the plan. The normal mutable fields are `passes` and progress notes.

## Permission Model

After the user approves the plan, dependency installation and local server startup are part of the normal execution flow through `./init.sh`. Do not ask the user to run setup manually unless credentials, external accounts, paid services, unavailable tools, blocked network access, or elevated system permissions prevent the agent from doing it.

For unattended outer-loop automation, the operator may launch the agent CLI in its non-interactive mode after approval. Interactive sessions should still obey the host tool's permission prompts.

`scripts/run-automation.sh` is optional. Do not run it by default. Use it only when the user explicitly asks for outer-loop automation or when `task.json.execution.default_mode_after_approval` is set to `automation-loop` and the user has approved unattended execution.

## Completion Gate

A task is not complete because code was written. It is complete only when:

- every `steps` item has been exercised or checked
- every `acceptance` item is satisfied
- every feasible `verification` command or manual check has passed
- related previously-passing behavior still works
- `progress.md` records the evidence
- `task.json` is updated from `"passes": false` to `"passes": true`

Before ending an execution session, confirm that:

- modified code builds or the failure is recorded as a blocker
- `task.json` accurately reflects completed work
- `progress.md` has a session or blocker entry
- one task's changes are committed when commits are available
- the worktree is clean, or any remaining changes are clearly documented

## Stop Conditions

Stop and write the blocker in `progress.md` when:

- The plan is not approved.
- Required credentials, services, or product decisions are missing.
- `./init.sh` cannot install dependencies, prepare the environment, or start required local services.
- Verification fails and the fix is outside the current task.
- The task list no longer matches the repository reality.
- Continuing would require destructive changes the user did not approve.

## References

- Read `references/principles.md` when deciding whether to split work, pause, or repair the harness.
- Read `references/setup.md` when initializing a project for the first time.
- Read `references/loop.md` when executing approved tasks.
