# Initializer Workflow

Use this workflow before product implementation starts. Its job is to create or
repair the harness and turn the user's requirement into an approval-ready plan.

## When To Use

- Harness files are missing.
- `architecture.md` is still a placeholder.
- `task.json` is empty or malformed.
- `task.json.approval.status` is not `approved`.
- The user asked to revise the plan.

## Auto-Initialize Harness

1. Locate the project root from the user request, `git rev-parse
   --show-toplevel`, or `pwd`.
2. If any harness file is missing, run:

   ```bash
   bash <skill-dir>/scripts/setup-harness.sh --dir <project-root>
   ```

3. The setup script skips existing files. Do not overwrite without explicit
   user request.
4. Do not write business code during initialization.

## Planning Files

Before approval, the agent may create or refine only:

- `CLAUDE.md`
- `AGENTS.md`
- `architecture.md`
- `task.json`
- `progress.md`
- `init.sh`
- `run-automation.sh`

`architecture.md` should describe the goal, current repo facts, proposed design,
verification strategy, risks, assumptions, and out-of-scope work.

`task.json` should contain concrete tasks with numeric `id`, `depends_on`,
`steps`, `acceptance`, `verification`, and `passes`. Do not add task-level
`status`; task completion is represented only by `passes`.

`steps` are the implementation sub-steps for completing the task. Put completion
criteria in `acceptance` and proof commands/manual checks in `verification`.

## init.sh Design

`init.sh` is not the per-task workflow. It is a project-specific prerequisite
check used by future fresh sessions.

Keep it conservative:

- check only tools, files, ports, simulators, databases, or health URLs this
  project actually needs
- do not install dependencies just because a manifest exists
- do not start generic dev servers unless the project explicitly requires it
- keep it idempotent and safe to run before every task

Examples of valid checks: `require_command xcodebuild`,
`require_path MyApp.xcworkspace`, `require_port 3000`, or
`check_url http://127.0.0.1:3000/health`.

## Approval Gate

After planning:

1. Show a short overview of the architecture and task list.
2. Mention dependency order and the default execution mode.
3. Ask the user to approve.
4. Stop.

Forbidden before approval:

- edit product/application/business code
- run `./init.sh`
- install dependencies or start services
- execute tasks from `task.json`
- mark any task `passes: true`
- run `./run-automation.sh`

When the user explicitly approves (e.g. `approve`, `approved`, `looks good`,
`go ahead`, `同意`, `可以`, `开始`, `继续执行`), set
`task.json.approval.status` to `approved`, fill approval metadata when
practical, append an approval entry to `progress.md`, then **read
`references/task-workflow.md` in full** and follow its steps for task
execution. Do not proceed from memory — read the file.

If `execution.bare_approval_starts_execution` is `true`, a bare approval reply
automatically starts the default mode from
`execution.default_mode_after_approval` (typically `continuous-batch`).
