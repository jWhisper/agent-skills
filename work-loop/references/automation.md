# Automation

Use this reference only for explicit unattended or repeated-agent runs.

Automation is optional. Do not run `run-automation.sh` by default.

## When automation is allowed

All must be true:

- `task.json.approval.status` is `approved`.
- At least one approved task has been completed manually.
- The user explicitly asks for outer-loop automation, or `execution.default_mode_after_approval` is `automation-loop` and the user approved unattended execution.
- `run-automation.sh --help` works in the target project.

## What automation does

`run-automation.sh` repeatedly launches Codex or Claude Code with a bounded prompt. Each run should:

- run `./init.sh`
- regression-check already passing tasks
- complete a small number of unblocked tasks
- update `task.json`
- update `progress.md`
- commit completed task changes when possible

If one run completes zero tasks, stop and inspect logs before launching more runs.

## Common commands

```bash
./run-automation.sh --agent codex --tasks-per-run 3 --max-runs 10
./run-automation.sh --agent claude --tasks-per-run 3 --max-runs 10
```

Interactive sessions should still obey the host tool's permission prompts. Non-interactive CLI permission choices are operator decisions, not defaults hidden in the skill.
