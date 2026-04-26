# Task Schema

`task.json` is the source of truth for what remains. Use JSON because it is
harder to casually rewrite than prose.

## Required Shape

```json
{
  "project": "Project name",
  "spec": "One paragraph describing the requested outcome",
  "approval": {
    "status": "needs-user-approval",
    "approved_by": null,
    "approved_at": null
  },
  "execution": {
    "bare_approval_starts_execution": true,
    "default_mode_after_approval": "continuous-batch",
    "default_tasks_per_run": 50,
    "default_max_runs_after_approval": 8,
    "default_delay_seconds": 3
  },
  "tasks": [
    {
      "id": 1,
      "title": "Short task title",
      "category": "setup",
      "description": "Concrete scope for this task",
      "depends_on": [],
      "steps": ["Implement the first concrete sub-step of this task"],
      "acceptance": ["Observable condition that must be true"],
      "verification": ["Command or manual check that proves completion"],
      "passes": false
    }
  ]
}
```

## Field Rules

- `id`: required numeric ID, unique and stable. Use `1`, `2`, `3`.
- `title`: short task name.
- `category`: examples are `setup`, `functional`, `regression`, `test`, `docs`,
  `refactor`, or `polish`.
- `description`: what this task changes and why.
- `depends_on`: array of numeric prerequisite task IDs.
- `steps`: implementation sub-steps required to complete the task.
- `acceptance`: criteria that must be true before completion.
- `verification`: commands, browser checks, screenshots, or manual checks.
- `passes`: `false` until verified; `true` only after the full task passes.
- Do not add `status` to individual tasks. Use `passes` as the only task
  completion signal.

## Execution Fields

- `bare_approval_starts_execution`: if `true`, a bare approval reply
  automatically starts the default execution mode.
- `default_mode_after_approval`: `checkpoint`, `continuous-batch`, or
  `automation-loop`.
- `default_tasks_per_run`: max tasks to complete in one continuous-batch run.
- `default_max_runs_after_approval`: max outer-loop sessions for
  automation-loop mode.
- `default_delay_seconds`: pause between automation runs.

## Invariants

- All new tasks start with `"passes": false`.
- New tasks do not include a task-level `status` field.
- Every implementation task should include `steps` with concrete sub-steps for
  completing the task.
- Task IDs never change after approval.
- Do not remove tasks after approval.
- Do not rewrite titles, descriptions, dependencies, steps, acceptance, or
  verification after approval unless the user explicitly reopens planning.
- If the backlog is wrong, stop and repair the plan before coding more.

## Dependency Selection

Choose the first incomplete task whose dependencies are all passing:

1. Ignore tasks with `"passes": true`.
2. For each remaining task, inspect `depends_on`.
3. A task is blocked if any dependency is missing or not passing.
4. Select the lowest numeric ID among unblocked tasks.
5. If none are unblocked, record the blocker in `progress.md`.
