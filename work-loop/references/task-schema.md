# Task Schema

Use this reference when creating or revising `task.json`.

## Minimal shape

```json
{
  "project": "Project name",
  "description": "Short project goal",
  "approval": {
    "status": "pending",
    "approved_by": "",
    "approved_at": ""
  },
  "execution": {
    "default_mode_after_approval": "continuous"
  },
  "tasks": [
    {
      "id": 1,
      "title": "New chat",
      "category": "functional",
      "description": "New chat button creates a fresh conversation",
      "depends_on": [],
      "steps": [
        "Navigate to main interface",
        "Click the 'New Chat' button",
        "Verify a new conversation is created"
      ],
      "acceptance": [
        "All listed steps pass in the running app"
      ],
      "verification": [
        "Run the relevant lint/build/test command"
      ],
      "passes": false
    }
  ]
}
```

## Field rules

- `id`: required, unique, stable numeric identifier. Prefer sequential IDs such as `1`, `2`, and `3`.
- `title`: short human-readable task name.
- `category`: use values such as `setup`, `functional`, `regression`, `refactor`, `test`, or `docs`.
- `description`: concrete scope for this task.
- `depends_on`: list prerequisite numeric task IDs, for example `[1, 2]`.
- `steps`: concrete actions or observable checks to perform.
- `acceptance`: completion criteria that must be true before marking the task passed.
- `verification`: commands or manual checks that provide evidence.
- `passes`: only set to `true` after all steps, acceptance, and verification pass.

Update `passes` one task at a time. Do not leave several completed tasks as `false` and update them in a batch later.

## Freeze rule

Before approval, revise task definitions freely. After approval, do not rewrite `id`, `title`, `description`, `depends_on`, `steps`, `acceptance`, or `verification` during normal execution. If the plan is wrong, pause and ask to revise it. Normal execution should only update `passes` and `progress.md`.

## Selection rule

Select the first task where:

- `passes` is `false`
- every `depends_on` task is already `passes: true`

If no incomplete task is unblocked, stop and record the dependency blocker.
