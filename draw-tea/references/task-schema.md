# Task Schema

Use valid JSON following the work-loop style.

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

- `project`: short project name.
- `spec`: one paragraph describing the requested outcome.
- `approval.status`: keep as `needs-user-approval` until the user explicitly
  approves the plan.
- `execution.bare_approval_starts_execution`: usually `true`.
- `execution.default_mode_after_approval`: usually `continuous-batch`; use
  `checkpoint` or `automation-loop` only when the user requested that style.
- `execution.default_tasks_per_run`: default `50` unless a smaller budget is
  safer.
- `execution.default_max_runs_after_approval`: default `8`.
- `execution.default_delay_seconds`: default `3`.

## Execution Modes

Use `execution.default_mode_after_approval` to describe what happens after the
user approves the plan with bare approval text such as `approve`, `go ahead`,
`可以`, or `继续`.

- `checkpoint`: finish exactly one unblocked task, update `task.json` and
  `progress.md`, commit if appropriate, then stop. Use this when the user wants
  a careful single-step checkpoint or when the risk of broad changes is high.
- `continuous-batch`: keep selecting and finishing unblocked tasks in dependency
  order until the task budget is reached, the backlog is empty, verification
  fails, or a blocker appears. This is the default because a bare approval
  usually means "start carrying out the approved plan" rather than "stop after
  the first task."
- `automation-loop`: launch `./run-automation.sh` after approval so a supervisor
  can start repeated fresh agent sessions. Use this only when the user asks for
  unattended looping, long-running automation, or repeated sessions.

Do not use `automation-loop` during Draw Tea planning itself. Draw Tea may write
the script, but it must not execute it.

## Task Rules

- `id`: required numeric ID, unique and stable. Use `1`, `2`, `3`.
- `title`: short task name.
- `category`: examples are `setup`, `functional`, `regression`, `test`, `docs`,
  `refactor`, or `polish`.
- `description`: what this task changes and why.
- `depends_on`: array of numeric prerequisite task IDs.
- `steps`: implementation sub-steps required to complete the task.
- `acceptance`: user-visible criteria that must be true before completion.
- `verification`: commands, browser checks, screenshots, or manual checks.
- `passes`: `false` until verified; `true` only after the full task passes.
- Do not add a task-level `status` field.

## Acceptance vs Verification

Use `acceptance` for what must be true from the user's or product's point of
view. Use `verification` for how the coding agent proves it is true.

Examples:

```json
{
  "acceptance": [
    "Users can submit the form without losing entered data when validation fails",
    "The success state shows the generated report id"
  ],
  "verification": [
    "Run npm test -- form",
    "Use the browser to submit invalid and valid form payloads",
    "Confirm the response contains a report id in the success path"
  ]
}
```

Good `acceptance` items are observable outcomes, behavior rules, UX states, data
contract expectations, or compatibility guarantees. Good `verification` items
are tests, commands, browser checks, API calls, screenshots, logs, or manual
inspection steps that prove the acceptance items were satisfied.

## Invariants

- All new tasks start with `"passes": false`.
- Task IDs never change after approval.
- Do not remove tasks after approval.
- Do not rewrite titles, descriptions, dependencies, steps, acceptance, or
  verification after approval unless the user explicitly reopens planning.
- If the backlog is wrong, stop and repair the plan before coding starts.
