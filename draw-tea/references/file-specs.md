# Preparation File Specs

Create these files in the project root unless the user explicitly asks for a
different directory.

## CLAUDE.md and AGENTS.md

Both files must tell coding agents how to continue after planning. Keep the
content equivalent, adjusted only for the tool name if helpful.

Required points:

- Read `architecture.md`, `task.json`, and `progress.md` before coding.
- Run `./init.sh` once at the start of every new coding session before coding.
  Do not require rerunning it before every task unless the plan explicitly says
  the environment must be refreshed.
- Work on one unblocked task at a time, respecting `depends_on`.
- A task is complete only after its steps are done and verification evidence
  exists.
- After each completed task, immediately update both files:
  - In `task.json`, change only the selected task's `"passes": false` to
    `"passes": true`.
  - In `progress.md`, append a dated entry with task id, task title, changes,
    verification evidence, and remaining task counts.
- After `task.json` and `progress.md` are updated for a completed task, make
  exactly one git commit for that task. The commit must include the
  implementation changes, `task.json`, and `progress.md` together.
- Do not start the next task or report the task complete until the commit
  succeeds. If git is unavailable or the commit fails, record the blocker in
  `progress.md` and stop honestly.
- If blocked, append a blocker entry to `progress.md` and do not pretend the
  task is complete.
- Do not reorder or rewrite approved tasks unless the user asks to re-plan.
- Use `./run-automation.sh` only after the plan is approved and only when the
  user asks for automation-loop execution.

## architecture.md

Use this structure:

```markdown
# Architecture

## Requirement
## Goals
## Non-Goals
## Current Context
## Assumptions
## Open Questions
## Decisions
## Proposed Design
## Affected Areas
## Data and Interface Changes
## Risks
## Verification Strategy
## Task Breakdown
```

Keep `architecture.md` implementation-ready but not implementation itself. It
may name files, modules, endpoints, data models, and test areas, but it must not
include new production code.

## progress.md

Start with a preparation entry:

```markdown
# Progress

## YYYY-MM-DD HH:mm - Preparation

- Requirement summary:
- Files created or updated:
- Key decisions:
- Open questions:
- Next step:
```

Future coding agents will append task completion or blocker entries here after
each task.
