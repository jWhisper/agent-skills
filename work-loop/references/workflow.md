# Workflow

Use this file as the router for Work Loop sessions. Keep initialization and
task execution separate so the agent does not mix planning/setup with product
implementation.

## Phase Routing

1. **Harness initialization / planning**
   - Use `references/initializer-workflow.md`.
   - Active when harness files are missing, `architecture.md` is still a
     placeholder, `task.json.tasks` is empty, or approval is not recorded.
   - Allowed output is harness/planning files only.

2. **Task execution**
   - Use `references/task-workflow.md`.
   - Active only after `task.json.approval.status` is `approved` and at least
     one concrete task exists.
   - Product code changes happen only here.

3. **Task schema details**
   - Use `references/task-schema.md` when creating or repairing tasks.

## Session Start

At the start of every session:

1. Locate the project root from the user request, `git rev-parse
--show-toplevel`, or `pwd`.
2. Check for `CLAUDE.md`, `AGENTS.md`, `architecture.md`, `task.json`,
   `progress.md`, `init.sh`, and `run-automation.sh`.
3. If any are missing, run:

   ```bash
   bash <skill-dir>/scripts/setup-harness.sh --dir <project-root>
   ```

4. Read `CLAUDE.md` or `AGENTS.md`, `architecture.md`, `task.json`, and
   `progress.md`.
5. Route to initializer or task workflow using the phase rules above.

Do not rely on prior chat context. The files are the memory.

## Boundary Rules

- Before approval, do not edit business code, run `./init.sh`, install
  dependencies, start servers, run automation, or mark tasks passing.
- After approval, do not rewrite task text during normal execution; update only
  approval metadata, `passes`, and handoff/progress entries.
- `init.sh` belongs to initialization but is run by the task workflow. It must
  be a conservative project-specific prerequisite check, not a generic installer
  or server launcher.
- Every completed task must update the selected task's `passes` and append a
  matching `task-complete` entry before commit.
- `progress.md` uses only `task-complete` and `blocker` entries. Each entry must
  include counts for passed, failed_or_blocked, remaining, and total tasks.
