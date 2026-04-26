# Handoff

`progress.md` is the memory for fresh sessions. Write it for an agent that has
not seen the prior chat.

## Header

```markdown
# Progress

Fresh session startup:
1. Read `CLAUDE.md` or `AGENTS.md`
2. Read `architecture.md`
3. Read `task.json`
4. Read this file
5. Run `./init.sh` only after the plan is approved and execution has begun

## Current State

- Approval: pending
- Mode: not started
- Passing tasks: 0/N
- Next task: first unblocked task with `passes: false`
- Last verification: not run
```

## Harness Initialized

```markdown
## Session N - Harness Initialized

### What changed
- Created missing harness files without overwriting existing files.

### Current status
- No business code has been changed.
- Planning files are ready to be populated or reviewed.

### Next
- Complete `architecture.md` and `task.json`, show the task overview, and wait
  for user approval.
```

## Plan Approval

```markdown
## Session N - Plan Approved

### Approval
- Approved by: user
- Approved at: YYYY-MM-DDTHH:MM:SSZ
- Execution mode: checkpoint | continue | automation

### Next
- Start the selected execution mode.
```

## Completed Task

Append this immediately after each task passes. Do not batch several tasks into
one entry.

```markdown
## Session N - Task 3: Task title

### What changed
- Files or behavior changed.

### Dependency check
- Dependencies satisfied: 1, 2

### Steps
- [x] Step and observed result.

### Acceptance
- [x] Acceptance criterion and evidence.

### Verification
- `command`: result
- Manual/browser check: result

### Issues
- None, or the issue and how it was resolved.

### Next
- Next unblocked task, remaining blocker, or completion state.
```

## Regression

```markdown
## Session N - Regression Found: Task 2

### Regression
- What failed and how it was detected.

### Action
- Changed task 2 `passes` back to `false`.
- Fix this regression before new work.
```

## Blocker

```markdown
## Session N - BLOCKED: Task 4

### Blocker
- Exact blocker and where it occurred.

### What was completed
- Safe partial work, if any.

### What is needed
- Human action, credential, decision, tool, or environment repair.

### Resume instructions
- What the next session should do after the blocker is resolved.
```

## Evidence Rules

- Prefer concrete command output summaries and file references.
- For UI work, mention browser path, interaction, screenshots when available,
  and console status.
- If a check cannot run, record why and what substitute evidence was used.
- Missing evidence means the task stays `passes: false`.
