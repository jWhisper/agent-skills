# Harness Script Specs

`init.sh` and `run-automation.sh` are preparation artifacts for future sessions.
Creating them is allowed; executing them is not allowed while using Draw Tea.

## init.sh

Create an executable, idempotent environment initialization script for future
fresh coding sessions. It should prepare the local environment needed before
the agent starts implementing the approved tasks.

Purpose:

- Confirm the project root.
- Give every new agent session the same initialized baseline before coding.
- Check required local commands, files, ports, simulators, databases, or health
  URLs that are actually relevant to the project.
- Start required local background services when the plan needs them, such as a
  backend API, mock server, database container, or frontend dev server.
- Wait for readiness with a health URL, port check, process check, or equivalent
  project-specific signal.
- Print clear next steps if initialization cannot complete.

New-session behavior:

- Coding agents must run `./init.sh` at the start of every fresh session.
- Coding agents should not rerun `./init.sh` before every task by default. A
  long session may continue across multiple tasks after one successful
  initialization.
- Rerun `./init.sh` only if the environment changed, a service stopped, the plan
  explicitly requires refresh, or the user asks for it.
- The script may prepare runtime services and local prerequisites, but it must
  not perform product implementation work.
- The script should fail fast with a clear message when the local environment
  cannot be initialized.
- The script should be project-specific: include only checks that matter for
  this repository and this plan.

Good initialization actions:

- required commands such as `node`, `npm`, `go`, `python3`, `jq`, or `docker`
- required files such as `package.json`, `go.mod`, `.env.example`, or workspace
  files
- starting a backend service if it is not already running
- starting a frontend dev server if browser verification depends on it
- starting a local database or mock dependency when the plan requires it
- checking required ports or health URLs after starting services
- platform-specific tools such as `xcodebuild`, Android SDK tools, or database
  clients when the project actually needs them

Avoid:

- modifying databases, cloud resources, generated files, or source code
- starting unrelated long-lived services just because a manifest exists
- reinstalling dependencies on every run when a faster existence check is enough
- hiding failures behind warnings when the failed initialization would block
  verification

Recommended minimal shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "Initializing project session in $PROJECT_ROOT"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

# Add project-specific initialization here during planning.
# Example:
# require_command npm
# test -f package.json || { echo "Missing package.json" >&2; exit 1; }
#
# Start a required service only if it is not already running.
# Example:
# if ! lsof -ti:3000 >/dev/null 2>&1; then
#   nohup npm run dev > .draw-tea-dev.log 2>&1 &
# fi

echo "Session environment initialized."
```

## run-automation.sh

Create an executable supervisor script for future approved automation-loop
execution. It is only a launcher; it must not implement tasks itself.

When possible, create `run-automation.sh` by copying the bundled template:

```bash
cp <draw-tea-skill-dir>/assets/run-automation.sh ./run-automation.sh
chmod +x ./run-automation.sh
```

This template is copied from `work-loop/scripts/run-automation.sh` and should be
preferred over writing a new automation loop from scratch.

Required behavior:

- Refuse to run if `task.json` is missing.
- Refuse to run if `.approval.status` is not `approved`.
- Read execution defaults from `task.json.execution` when possible.
- Detect `claude` or `codex` if the user did not choose an agent.
- Repeatedly launch bounded agent sessions up to the configured max runs.
- Stop when no task progress is made, when all tasks pass, or when an agent
  session reports a blocker.
- Write logs under `automation-logs/`.

Keep this file conservative. If `jq` is unavailable, fail with a clear message
instead of trying to parse JSON with brittle shell string manipulation.
