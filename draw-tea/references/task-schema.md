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
      "title": "简短任务标题",
      "category": "setup",
      "description": "这个任务的具体范围和目的",
      "depends_on": [],
      "steps": ["完成这个任务的第一个具体实施步骤"],
      "acceptance": ["用户或产品视角下必须成立的可观察结果"],
      "verification": ["用于证明任务完成的命令、浏览器检查或人工检查"],
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
- Fill `project`, `spec`, task `title`, `description`, `steps`, `acceptance`,
  and `verification` in Chinese unless the user explicitly asks for another
  language or the project terms must remain in their original language.

## Execution Modes

Use `execution.default_mode_after_approval` to describe what happens after the
user approves the plan with bare approval text such as `approve`, `go ahead`,
`可以`, or `继续`.

- `checkpoint`: finish exactly one unblocked task, update `task.json` and
  `progress.md`, make one git commit containing that task's changes plus both
  tracking files, then stop. Use this when the user wants a careful single-step
  checkpoint or when the risk of broad changes is high.
- `continuous-batch`: keep selecting and finishing unblocked tasks in dependency
  order until the task budget is reached, the backlog is empty, verification
  fails, or a blocker appears. After each task, update `task.json` and
  `progress.md`, make one git commit for that task, then continue. This is the
  default because a bare approval usually means "start carrying out the
  approved plan" rather than "stop after the first task."
- `automation-loop`: launch `./run-automation.sh` after approval so a supervisor
  can start repeated fresh agent sessions. Use this only when the user asks for
  unattended looping, long-running automation, or repeated sessions.

Do not use `automation-loop` during Draw Tea planning itself. Draw Tea may write
the script, but it must not execute it.

## Task Rules

- `id`: required numeric ID, unique and stable. Use `1`, `2`, `3`.
- `title`: short Chinese task name.
- `category`: examples are `setup`, `functional`, `regression`, `test`, `docs`,
  `refactor`, or `polish`.
- `description`: in Chinese, explain what this task changes and why.
- `depends_on`: array of numeric prerequisite task IDs.
- `steps`: Chinese implementation sub-steps required to complete the task.
- `acceptance`: Chinese user-visible criteria that must be true before
  completion.
- `verification`: Chinese commands, browser checks, screenshots, or manual
  checks. Keep command literals in their original spelling.
- `passes`: `false` until verified; `true` only after the full task passes.
- Do not add a task-level `status` field.

## Acceptance vs Verification

Use `acceptance` for what must be true from the user's or product's point of
view. Use `verification` for how the coding agent proves it is true.

Examples:

```json
{
  "acceptance": [
    "用户提交表单后，即使校验失败，已输入的数据也不会丢失",
    "提交成功状态会展示生成的报告 ID"
  ],
  "verification": [
    "运行 npm test -- form",
    "使用浏览器分别提交无效和有效的表单数据",
    "确认成功路径的响应中包含报告 ID"
  ]
}
```

Good `acceptance` items are observable outcomes, behavior rules, UX states, data
contract expectations, or compatibility guarantees. Good `verification` items
are tests, commands, browser checks, API calls, screenshots, logs, or manual
inspection steps that prove the acceptance items were satisfied.

## Invariants

- All new tasks start with `"passes": false`.
- Each completed task must produce exactly one git commit after `task.json` and
  `progress.md` are updated.
- The task commit must include the implementation changes, `task.json`, and
  `progress.md` together.
- Task IDs never change after approval.
- Do not remove tasks after approval.
- Do not rewrite titles, descriptions, dependencies, steps, acceptance, or
  verification after approval unless the user explicitly reopens planning.
- If the backlog is wrong, stop and repair the plan before coding starts.
