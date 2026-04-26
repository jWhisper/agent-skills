# Work Loop Principles

Use this reference when a long task starts to feel vague, too large, or hard to resume.

## What the loop protects

- **Scope drift**: each implementation pass should map to one explicit task.
- **Memory loss**: `progress.md` must contain enough handoff detail for a new session to continue.
- **False completion**: a task is not complete until its steps, acceptance criteria, and verification checks are satisfied.
- **Environment drift**: `init.sh` should actively recreate the runnable local environment at the start of every session.
- **Blame confusion**: keep completed task changes reviewable; prefer one coherent change set per task.

## Operating rules

- Prefer repository facts over prior conversation memory.
- Every task must have a unique stable numeric `id`; use that ID for dependencies, progress notes, and commit messages.
- Keep tasks dependency-ordered and small. When order matters, encode it with `depends_on` instead of relying only on list position.
- Use `checkpoint`, `continuous`, or `automation-loop` explicitly when the user's prompt changes how much work to do.
- Treat `task.json` as the shared source of current work state.
- Treat `architecture.md` as the shared source of design intent.
- Initialize missing Work Loop files proactively instead of making the user hand-create them.
- Before approval, create and revise planning artifacts only; do not run environment setup or implement application code.
- Run `./init.sh` before coding; if it cannot prepare the environment, stop and record the blocker.
- Change task definitions before approval; after approval, do not rewrite `title`, `description`, `steps`, `acceptance`, or `verification` unless the user asks to re-plan. Normal execution should only flip `passes` and add notes in `progress.md`.
- If the task list is wrong, pause normal implementation and repair the plan first.
- Never start a task while any `depends_on` task is not passing.
- If verification cannot run, record the exact reason and the best substitute check.
- End each execution session with a clean-state check: build/test result, accurate task status, progress entry, one-task commit when available, and no unexplained worktree changes.

## Permission stance

Work Loop treats dependency installation and local development server startup as normal approved-task work only after the user approves the plan. The agent should run `./init.sh` itself after approval. Stop for human help only when the environment requires secrets, external account setup, paid services, unavailable tools, blocked network access, or elevated system permissions.

For explicit unattended automation, use the agent CLI's non-interactive mode chosen by the operator. Do not silently switch an interactive session into unattended mode.

Run one approved task manually before starting unattended automation. If an automation run completes zero tasks, inspect logs and repair the harness before launching more runs.

## Good task size

A good task can usually be implemented, checked step by step, explained, and reviewed on its own. Split a task when it mixes unrelated concerns such as schema design, API behavior, UI, tests, and deployment wiring.
