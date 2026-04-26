# Task Workflow

Use this workflow only after the plan is approved and concrete tasks exist.
This is the per-task execution loop; it is separate from harness initialization.

Each session starts with a fresh context window. Treat `CLAUDE.md`/`AGENTS.md`,
`architecture.md`, `task.json`, and `progress.md` as memory.

## Step 1: Get Bearings

Run or inspect:

```bash
pwd
git log --oneline -20
git status --short
```

Read, in order:

1. `CLAUDE.md` or `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

Count remaining tasks by finding tasks whose `passes` is not `true`. Do not use
a task-level `status`; `passes` is the only task completion signal.

## Step 2: Check Project Prerequisites

Run `./init.sh` before each task.

`init.sh` is not a generic installer and not the task workflow. It should verify
only project-specific prerequisites such as commands, files, ports, simulators,
databases, local services, or health URLs. If it fails, record the blocker and
stop before editing product code.

## Step 3: Regression Check

Before new work, regression-check one or two important tasks already marked
`passes: true` when any exist.

For UI work, use browser automation or the app's normal manual verification
surface. For services, use tests, health checks, API calls, or the repo's normal
verification command.

If a regression is found:

- change only the affected task's `passes` back to `false`
- append a `blocker` entry to `progress.md`
- fix the regression before starting new feature work

## Step 4: Select The Next Task

Read task.json and select the next task where `passes: false` and all
`depends_on` are `true`.

Selection criteria (in priority order):

1. Dependencies first — if Task B depends on Task A, do A first
2. Foundation before features — infrastructure, data models, and core APIs before UI
3. Lowest ID first among equals — when no dependency exists, follow task ID order
4. Regressions before new work — if a previously-passing task broke, fix it first

Announce which task you are working on. In Continuous Batch mode, repeat this
selection step after each successful commit.

## Step 5: Implement Only That Task

Read the selected task's `description`, `steps`, `acceptance`, and
`verification` carefully.

Guidelines:

- follow existing code patterns and architecture boundaries
- keep changes focused on the selected task
- do not opportunistically complete later tasks
- do not rewrite task titles, descriptions, dependencies, steps, acceptance, or
  verification during normal execution
- if the task is wrong or underspecified, stop and reopen planning instead of
  silently changing the backlog
- treat `steps` as implementation sub-steps, not as the verification checklist

## Step 6: Verify Thoroughly

After completing the implementation sub-steps, verify every `acceptance` and
`verification` item for the selected task.

For UI changes:

- navigate to the relevant page/screen
- perform the interactions described by the task
- check visual state and console/runtime errors where tooling allows

For backend or logic changes:

- run the relevant test, lint, build, or typecheck command
- verify API behavior or core logic with the project's normal tools

If a check cannot run, record the exact reason and the closest substitute
evidence. Do not mark the task passing when evidence is missing.

## Step 7: Update task.json

Only after all verification passes, set the selected task's `passes` to `true`.

Rules:

- change ONLY the `"passes": false` to `"passes": true` for the selected task — nothing else
- do not rewrite, reorder, or reformat any part of task.json
- do not add, remove, or modify any task field other than `passes`
- do not add task-level `status`
- use the smallest possible edit (e.g. sed or Edit tool replacing only `false` with `true` on that line)

## Step 8: Update progress.md

Immediately append a completed-task entry naming the same task ID/title.

```markdown
## Session N — Task: [task title]

### What was done

- [Specific changes: files created/modified, features implemented]

### Testing

- [How it was tested: browser screenshots, test results, build output]

### Issues encountered

- [Any problems found and how they were resolved]
- [Or "None"]

### Notes for next session

- [What to work on next]
- [Any known issues or tech debt]

### Current status

- X/Y tasks passing
```

Write it for a fresh agent that has not seen this chat.

## Step 9: Confirm The Checkpoint

Re-read `task.json` and `progress.md`.

The selected task is not complete until:

- `task.json` has the exact selected task updated to `"passes": true`
- `progress.md` has a new entry for that same task ID/title
- the progress entry includes verification evidence or a clear reason a check
  was not applicable

Do not report success, start another task, or exit until this checkpoint is
complete. If either file cannot be updated, leave the task as `passes: false`,
write a `blocker` entry, and stop.

## Step 10: Commit

Commit only after Step 9 confirms both file updates.

The task commit must include:

- implementation changes for the selected task
- `task.json`
- `progress.md`

Keep one task per commit when git is available. Do not commit code-only task
work, and do not commit before task status and progress are updated.

## Step 11: Decide Whether To Continue

- `checkpoint`: stop after one completed checkpoint and report the result.
  Never use as the result of a bare approval reply.
- `continuous-batch`: loop back to Step 2 for the next unblocked task until all
  tasks pass, the task budget is reached, verification fails, or a blocker
  appears. Do NOT stop after the first task.
- `automation-loop`: use `./run-automation.sh`; do not recursively launch
  automation from inside an already supervised automation run.

A bare approval reply should use
`task.json.execution.default_mode_after_approval` unless the user gives a
narrower instruction.

## Handling Blockers

If the task cannot be completed:

- do not mark it `passes: true`
- do not commit broken or misleading completion state
- append a `blocker` entry to `progress.md`

```markdown
## Session N — BLOCKED: [task title]

### Blocker

- [Exact description of what is blocking progress]

### What was completed

- [Any partial work that was done]

### What is needed

1. [Specific action required from a human]
2. [Another specific action]

### Resume instructions

- After the blocker is resolved, the next session should [specific steps]
```

- leave the repo buildable/runnable when possible
- state the exact human action, credential, tool, service, or decision needed

## Clean Stop

Before ending:

- `task.json` accurately reflects verified work
- `progress.md` contains the latest `task-complete` or `blocker` entry
- build/test status is recorded
- git status is clean, or remaining changes are clearly explained
