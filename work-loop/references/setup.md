# Setup Workflow

Use this reference when initializing a repository for Work Loop.

## Files to create

### `architecture.md`

Record the design baseline the user is approving:

- Goal and non-goals
- Current repository facts
- Main implementation approach
- Important interfaces, data shapes, or workflows
- Verification strategy

### `task.json`

Create a dependency-ordered task queue:

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
    "default_mode_after_approval": "continuous-batch",
    "default_tasks_per_run": 3,
    "default_max_runs_after_approval": 10
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
        "Verify a new conversation is created",
        "Check that chat area shows welcome state",
        "Verify conversation appears in sidebar"
      ],
      "acceptance": [
        "All listed steps pass in the running app",
        "No related previously-passing chat behavior regresses"
      ],
      "verification": [
        "Run the relevant lint/build/test command",
        "For UI changes, verify the flow in a browser and check for console errors"
      ],
      "passes": false
    }
  ]
}
```

Use `category` values such as `setup`, `functional`, `regression`, `refactor`, `test`, or `docs`. Use `depends_on` to list prerequisite task IDs, for example `"depends_on": [1, 2]`. Keep `approval.status` as `pending` until the user approves the plan.

### `progress.md`

Use this as the cross-session handoff:

```markdown
# Progress

## Current State

- Approval: pending
- Next task: first task with `"passes": false`
- Last verification: not run

## Log

- YYYY-MM-DD: Initialized Work Loop files.
```

### `init.sh`

Add an idempotent setup script for the target project. It should actively prepare the environment, including dependency installation and starting a local development server when the project has one. It should be safe to run at the start of every agent session.

For projects that require credentials, paid services, or external human authorization, `init.sh` should stop with a clear message instead of pretending setup succeeded.

### `AGENTS.md`

Add Codex-facing project instructions. Include where to read the plan, how to pick the next task, and which verification commands matter.

### `CLAUDE.md`

Add Claude Code-facing project instructions with the same project workflow as `AGENTS.md`, adjusted only for Claude-specific wording when needed.

## Setup rule

Do not overwrite existing project files unless the user explicitly asks for replacement. If a file already exists, append a note to `progress.md` or tell the user which file needs manual merge.
