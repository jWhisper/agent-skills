---
name: draw-tea
description: "Use when Codeing Agent needs to understand and analyze a product or engineering requirement before any implementation, including requirements provided as text, documents, or links; discuss ambiguity or disagreements with the user; and create pre-coding preparation artifacts in a project directory: CLAUDE.md, AGENTS.md, architecture.md, task.json, progress.md, init.sh, and run-automation.sh. This skill is strictly planning-only: it must not write business code, refactor code, run implementation tasks, or mark tasks complete."
---

# Draw Tea

Draw Tea turns a requirement into durable project preparation before coding
starts. Its posture is: clarify first, discuss unclear choices, write the
preparation files, show the方案, then stop.

## Hard Boundary

- Do not write, edit, or generate implementation/business code.
- Do not refactor, format, or modify production files, tests, configs,
  migrations, package manifests, or lockfiles.
- Do not run implementation tasks, install dependencies, start services, run
  `./init.sh`, or execute `./run-automation.sh` while planning. `init.sh` may
  be designed to start services later, after the plan is approved.
- Do not mark any task complete. Every new task must start with
  `"passes": false`.
- Stop after presenting the prepared方案 to the user. Wait for explicit approval
  or a separate coding request before any implementation.

Allowed work:

- Read repository files to understand context.
- Ask the user about conflicts, missing decisions, or risky assumptions.
- Create or update only these preparation files:
  `CLAUDE.md`, `AGENTS.md`, `architecture.md`, `task.json`, `progress.md`,
  `init.sh`, and `run-automation.sh`.

## Required References

Read these references in order when using this skill:

1. `references/workflow.md` for the planning sequence and disagreement gate.
2. `references/file-specs.md` for the required preparation file contents.
3. `references/task-schema.md` before writing or updating `task.json`.
4. `references/automation.md` before writing `init.sh` or
   `run-automation.sh`.
5. `references/final-response.md` before responding to the user.

## Operating Rule

If any reference appears to conflict with this file, follow the stricter
planning-only rule. The skill may prepare future automation, but it must never
start implementation itself.
