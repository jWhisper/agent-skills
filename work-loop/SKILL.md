---
name: work-loop
description: Use this skill for long-running coding work that needs planning, human approval, task-by-task execution, verification, progress handoff, and compatibility with both Codex and Claude Code.
---

# Work Loop

Work Loop is a lightweight harness for keeping long coding tasks recoverable. Use it when a request is larger than one focused edit, may span sessions, or needs Codex and Claude Code to share the same project workflow.

## Core Flow

1. Ground in the repository before planning. Read the README, existing agent instructions, package files, test commands, and relevant source paths.
2. If Work Loop files are missing, create them. Use `scripts/setup-harness.sh` when available; otherwise follow `references/workflow.md`.
3. Before approval, follow the approval gate in `references/workflow.md`.
4. Create or revise `task.json` using `references/task-schema.md`.
5. After approval, execute tasks using `references/workflow.md`.
6. Write handoff notes and blockers using `references/handoff.md`.

Task `id` is required, unique, and stable. Use numeric IDs such as `1`, `2`, and `3` so order and dependencies are easy to scan. Use those IDs in `depends_on`, progress notes, and commit messages.

## Non-Negotiables

- Before approval: do not run `./init.sh`, install dependencies, start servers, edit application code, run tasks, mark tasks passing, or run automation.
- After approval: run `./init.sh`, work only on unblocked tasks, satisfy `steps` + `acceptance` + `verification`, then mark `passes: true`.
- In `continuous` mode, continue to the next unblocked task without asking only after the current task checkpoint is complete.
- After every completed task, immediately update `task.json`, update `progress.md`, record verification evidence, commit one task when possible, and run the clean-state check before starting another task.
- After approval, task definitions are frozen unless the user asks to revise the plan.
- End each execution session with `task.json`, `progress.md`, verification evidence, and git state consistent.

## References

- `references/workflow.md`: approval, initialization, execution, automation, and stop conditions.
- `references/task-schema.md`: `task.json` fields, numeric IDs, dependencies, and freeze rule.
- `references/handoff.md`: `progress.md` fresh-session, session, and blocker templates.
