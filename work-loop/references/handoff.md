# Handoff

Use this reference when writing `progress.md`.

`progress.md` must let a fresh session continue without guessing.

## Header

```markdown
# Progress

Fresh session startup: read `CLAUDE.md` or `AGENTS.md`, then `architecture.md`, `task.json`, and this file before continuing. Do not rely on prior chat context.

## Current State

- Approval: pending
- Next task: first task with "passes": false
- Last verification: not run

## Log

- YYYY-MM-DD: Initialized Work Loop files.
```

## Completed Task

Write this immediately after each task passes, before starting the next task. Do not batch multiple completed tasks into one progress entry.

```markdown
## Session N - Task: task-id

### What changed
- Files or areas changed.

### Steps
- [x] Step that was completed.

### Acceptance
- [x] Acceptance result and evidence.

### Verification
- Command, manual check, screenshot, or reason a check was not applicable.

### Issues
- None, or the issue and how it was resolved.

### Next
- Next unblocked task, remaining blocker, or completion state.
```

## Blocker

```markdown
## Session N - BLOCKED: task-id

### Blocker
- Exact blocker and where it occurred.

### What was completed
- Any safe partial work that remains.

### What is needed
- Specific human action, credential, decision, or environment repair.

### Resume instructions
- What the next session should do after the blocker is resolved.
```

## Evidence Rules

- Prefer concrete commands and results.
- Mention screenshots or manual checks when UI behavior matters.
- If a check cannot run, record the reason and closest substitute check.
- Do not mark a task passing if evidence is missing.
