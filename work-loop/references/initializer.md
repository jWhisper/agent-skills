# Initializer

Use this reference when a repository does not yet have Work Loop files.

## Required files

### `architecture.md`

Record the design baseline the user is approving:

- Goal and non-goals
- Current repository facts
- Main implementation approach
- Important interfaces, data shapes, or workflows
- Verification strategy

### `task.json`

Create a dependency-ordered task queue. See `task-schema.md` for the exact schema and rules.

### `progress.md`

Create a handoff log. Include current approval state, next task, last verification, and the templates from `progress-handoff.md`.

### `init.sh`

Create an idempotent environment setup script. It should actively prepare dependencies and start a local development server when the project has one, but it must not be run before approval.

### `AGENTS.md` and `CLAUDE.md`

Create project instructions with the same workflow for Codex and Claude Code:

- Read `architecture.md`, `task.json`, and `progress.md` first.
- Respect the approval gate.
- Run `./init.sh` only after approval.
- Choose only unblocked tasks.
- Complete steps, acceptance, and verification before marking a task passing.
- Update `progress.md` before stopping.

### `run-automation.sh`

Create or copy the optional outer-loop script, but do not run it before approval.

## Existing files

Do not overwrite existing project files unless the user explicitly asks for replacement. If a file already exists, either preserve it or tell the user which file needs a manual merge.
