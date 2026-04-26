# Approval Gate

Use this reference before any implementation work starts.

## Allowed before approval

- Inspect the repository.
- Create or revise `architecture.md`.
- Create or revise `task.json`.
- Create or revise `progress.md`.
- Create or revise `AGENTS.md` and `CLAUDE.md`.
- Create `init.sh` and `run-automation.sh` as files.
- Ask the user to review the plan and reply with `approve`, `go ahead`, `LGTM`, `批准`, or `同意执行`.

## Forbidden before approval

- Do not run `./init.sh`.
- Do not install dependencies.
- Do not start development servers.
- Do not edit business or application code.
- Do not execute tasks from `task.json`.
- Do not change `approval.status` to `approved`.
- Do not mark tasks `passes: true`.
- Do not run `run-automation.sh`.

## Approval transition

After explicit approval:

1. Set `task.json.approval.status` to `approved`.
2. Fill `approved_by` and `approved_at` when practical.
3. Run the execution loop from `execution-loop.md`.

If the user asks for a plan revision after approval, pause execution and update `architecture.md` and `task.json` before continuing.
