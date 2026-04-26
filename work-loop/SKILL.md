---
name: work-loop
description: Use this skill when a coding task may span multiple turns or sessions and needs a self-looping harness that prevents forgetting, drift, hallucinated completion, or out-of-order work. The skill auto-initializes repo files such as CLAUDE.md, AGENTS.md, architecture.md, task.json, progress.md, init.sh, and run-automation.sh, waits for user approval, then executes dependency-aware tasks in checkpoint, continue, or automation mode.
---

# Work Loop

Work Loop is a coding harness for long-running agent work. It turns a vague
coding request into durable repo artifacts, then uses those artifacts to resume
cleanly across fresh conversations.

## Trigger Behavior

When this skill is used, do these steps in order:

1. Locate the project root: use the user-provided path, otherwise
   `git rev-parse --show-toplevel`, otherwise the current directory.
2. Auto-initialize the harness before writing business code. If any required
   file is missing, run `scripts/setup-harness.sh --dir <project-root>`.
3. Existing files are not overwritten. If a file already exists, read it and
   continue from it.
4. Read `CLAUDE.md` or `AGENTS.md`, `architecture.md`, `task.json`, and
   `progress.md`.
5. If the plan is missing, empty, or unapproved, stay in planning mode: write or
   refine `architecture.md` and `task.json`, then show the task overview to the
   user and stop for approval.
6. Only after the user says approval text such as `approve`, `go ahead`, `同意`,
   `执行`, `开始`, or `继续执行`, record approval and enter execution mode.

## Harness Files

- `CLAUDE.md`: repo-local instructions for Claude Code and compatible agents.
- `AGENTS.md`: same workflow for Codex and compatible agents.
- `architecture.md`: approved design, scope, assumptions, and verification
  strategy.
- `task.json`: the single source of truth for concrete tasks.
- `progress.md`: handoff log for fresh sessions.
- `init.sh`: idempotent startup script run at every new coding session and
  before every task.
- `run-automation.sh`: optional supervisor loop that launches fresh agent
  sessions until tasks complete or progress stops.

## Non-Negotiables

- Before the harness exists, do not write business code.
- Before approval, only inspect the repo and edit harness/planning files.
- `task.json.tasks[].id` must be unique numeric IDs such as `1`, `2`, `3`.
- Respect `depends_on`: do not start a task until every dependency has
  `passes: true`.
- Within `task.json`, normal coding may only change task status fields and
  approval metadata; task text is frozen after approval.
- Run `./init.sh` at the start of every new coding session and before each task.
- Mark `passes: true` only after all steps, acceptance, and verification pass.
- After each completed task, immediately update `task.json`, append
  `progress.md`, and commit one coherent task when git is available.
- If blocked, record the blocker in `progress.md` and stop honestly.

## Execution Modes

- `checkpoint`: complete exactly one unblocked task, checkpoint it, then stop.
- `continue`: keep selecting the next unblocked task until the backlog is done,
  a blocker appears, verification fails, or the task budget is reached.
- `automation`: run `./run-automation.sh`; the script relaunches fresh agent
  sessions and stops when no progress is made.

Use the mode requested by the user. If the user gives bare approval with no
mode, use `task.json.execution.default_mode_after_approval`.

## References

- `references/workflow.md`: full state machine and mode rules.
- `references/task-schema.md`: required task JSON shape and invariants.
- `references/handoff.md`: progress and blocker templates.
