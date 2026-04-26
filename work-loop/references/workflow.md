# Workflow

Use this state machine for every Work Loop session.

## State 1: Auto-Init

1. Locate the project root from the user request, `git rev-parse
   --show-toplevel`, or `pwd`.
2. Check for `CLAUDE.md`, `AGENTS.md`, `architecture.md`, `task.json`,
   `progress.md`, `init.sh`, and `run-automation.sh`.
3. If any are missing, run:

   ```bash
   bash <skill-dir>/scripts/setup-harness.sh --dir <project-root>
   ```

4. The setup script must skip existing files. Do not overwrite without explicit
   user request.
5. Do not write business code during auto-init.

## State 2: Planning Gate

Planning mode is active when:

- `task.json` is missing, empty, or malformed
- `task.json.approval.status` is not `approved`
- `architecture.md` is still a placeholder
- the user asked to revise the plan

Allowed before approval:

- inspect repository files
- create or refine `CLAUDE.md`, `AGENTS.md`, `architecture.md`, `task.json`,
  `progress.md`, `init.sh`, and `run-automation.sh`
- derive a concrete task list from the user's requirement
- list the task overview for the user
- ask for approval

Forbidden before approval:

- edit application or business code
- run `./init.sh`
- install dependencies or start servers
- execute tasks from `task.json`
- mark any task `passes: true`
- run `./run-automation.sh`

After planning, show a short task overview grouped by dependency/order and ask
the user to approve. Stop until the user replies with approval text such as
`approve`, `go ahead`, `LGTM`, `同意`, `执行`, `开始`, or `继续执行`.

## State 3: Approval

When approval is explicit:

1. Set `task.json.approval.status` to `approved`.
2. Fill `approved_by` and `approved_at` when practical.
3. Append an approval entry to `progress.md`.
4. Choose the execution mode:
   - explicit user mode wins
   - otherwise use `task.json.execution.default_mode_after_approval`

If the approval reply is bare approval with no smaller scope, continue directly
into the default execution mode.

## State 4: Fresh Session Resume

At the start of every new conversation or automated run:

1. Run `pwd`.
2. Read `CLAUDE.md` or `AGENTS.md`.
3. Read `architecture.md`.
4. Read `task.json`.
5. Read `progress.md`.
6. Inspect recent git history with `git log --oneline -20` when git exists.

Do not rely on previous chat context. The files are the memory.

## State 5: Task Selection

Select the first task where:

- `passes` is not `true`
- every numeric ID in `depends_on` already points to a task with `passes: true`

If no incomplete task is unblocked, write a blocker entry to `progress.md` and
stop. Do not skip dependency order.

Regressions take priority. If a previously passing task fails verification,
change only that task's `passes` back to `false`, record the regression, and fix
it before new work.

## State 6: Per-Task Loop

For each selected task:

1. Run `./init.sh`.
2. Regression-check one or two already passing tasks when any exist.
3. Implement only the selected task.
4. Complete every `steps` item.
5. Satisfy every `acceptance` item.
6. Run every feasible `verification` command or manual check.
7. Only then set the selected task's `passes` to `true`.
8. Append a completed-task entry to `progress.md`.
9. Commit code, `task.json`, and `progress.md` together when git is available.

Do not start another task until the checkpoint is complete.

## Execution Modes

### Checkpoint

Complete one unblocked task and stop after its checkpoint. Use this when the
user asks for one task, one checkpoint, or a careful incremental step.

### Continue

Repeat the per-task loop until:

- all tasks pass
- the configured task budget is reached
- a dependency blocker appears
- verification fails
- required credentials/tools/services are missing
- the worktree cannot be left in a clean, understandable state

Do not stop after one task in continue mode.

### Automation

Run `./run-automation.sh` only after approval. The script launches fresh agent
sessions with bounded task budgets and stores logs under `automation-logs/`.

Stop automation if a run completes zero tasks; that means the harness or task
plan needs human repair.

## Clean Stop

Before ending a session, ensure:

- `task.json` accurately reflects verified work
- `progress.md` contains the latest completed task or blocker
- build/test status is recorded
- git status is clean, or remaining changes are clearly explained
