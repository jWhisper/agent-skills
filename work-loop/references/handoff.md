# Handoff

`progress.md` is the memory for fresh sessions. Keep it small and append-only.

Use only two entry types:

- `task-complete`
- `blocker`

Every entry must include task counts so the next session can understand overall
state without recalculating first:

- `passed`: number of tasks with `passes: true`
- `failed_or_blocked`: number of tasks known to be failing, regressed, or
  blocked
- `remaining`: number of tasks not yet passing
- `total`: total task count

## Header

```markdown
# Progress

Fresh session startup:
1. Read `CLAUDE.md` or `AGENTS.md`
2. Read `architecture.md`
3. Read `task.json`
4. Read this file

## Current State

- Approval: pending
- Mode: not started
- Counts: passed 0, failed_or_blocked 0, remaining 0, total 0
- Next task: planning required
```

## task-complete Entry

Append after a task's implementation, acceptance, and verification pass.

The task is not complete unless this entry exists in `progress.md` and the same
task has `passes: true` in `task.json`.

```markdown
## task-complete - Task 3: Task title

### Counts
- passed: 3
- failed_or_blocked: 0
- remaining: 7
- total: 10

### Completed
- Implementation sub-steps completed.
- Files or behavior changed.

### Verification
- Acceptance evidence.
- Verification command/manual check evidence.

### Next
- Next unblocked task, or completion state.
```

## blocker Entry

Append when work cannot continue, including failed verification, missing tools,
blocked dependencies, credentials, services, or regressions.

```markdown
## blocker - Task 4: Task title

### Counts
- passed: 3
- failed_or_blocked: 1
- remaining: 7
- total: 10

### Blocker
- Exact blocker and where it occurred.

### Partial Work
- Safe partial work, if any.

### Needed
- Human action, credential, decision, tool, or environment repair.

### Resume
- What the next session should do after the blocker is resolved.
```

## Evidence Rules

- Prefer concrete command output summaries and file references.
- For UI work, mention browser path, interaction, screenshots when available,
  and console status.
- If a check cannot run, record why and what substitute evidence was used.
- Missing evidence means the task stays `passes: false` and uses a `blocker`
  entry, not `task-complete`.
