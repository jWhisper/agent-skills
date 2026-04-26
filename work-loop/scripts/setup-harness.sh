#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-harness.sh [--force] [--dir DIR] [--name NAME] [--platform claude|codex|all] [DIR]

Create the Work Loop harness files in a target project.
Existing files are skipped unless --force is provided.
USAGE
}

force="no"
target_dir=""
project_name=""
platform="all"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="yes"
      shift
      ;;
    --dir)
      target_dir="${2:-}"
      shift 2
      ;;
    --name)
      project_name="${2:-}"
      shift 2
      ;;
    --platform)
      platform="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$target_dir" ]; then
        echo "Only one target directory is supported." >&2
        exit 2
      fi
      target_dir="$1"
      shift
      ;;
  esac
done

case "$platform" in
  claude|codex|all) ;;
  *)
    echo "Invalid --platform: $platform" >&2
    exit 2
    ;;
esac

target_dir="${target_dir:-.}"
mkdir -p "$target_dir"
target_dir="$(cd "$target_dir" && pwd)"
project_name="${project_name:-$(basename "$target_dir")}"

json_string() {
  local value="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$value"
  elif command -v node >/dev/null 2>&1; then
    node -e 'console.log(JSON.stringify(process.argv[1]))' "$value"
  else
    printf '"%s"' "$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  fi
}

write_file() {
  local path="$1"
  local content="$2"

  if [ -e "$path" ] && [ "$force" != "yes" ]; then
    echo "Skipped existing $path"
    return 1
  fi

  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$content" > "$path"
  echo "Wrote $path"
  return 0
}

architecture_content() {
  cat <<EOF
# $project_name Architecture

## Goal

Replace this placeholder with the user-visible goal and product scope.

## Requirements

- Capture concrete requirements from the user request or spec.

## Current Repository Facts

- Repository shape:
- Existing stack:
- Important commands:

## Proposed Design

- Modules and responsibilities:
- Data model:
- External integrations:
- Error handling:

## Verification Strategy

- Automated checks:
- Manual/browser checks:
- Regression checks:

## Risks And Assumptions

- Assumption:
- Open question:

## Out Of Scope

- List what should not be implemented in this plan.
EOF
}

task_content() {
  local json_project
  json_project="$(json_string "$project_name")"
  cat <<EOF
{
  "project": $json_project,
  "goal": "Replace this with the concrete user request before asking for approval.",
  "approval": {
    "status": "pending",
    "approved_by": null,
    "approved_at": null
  },
  "execution": {
    "default_mode_after_approval": "continue",
    "tasks_per_run": 50,
    "max_runs": 8,
    "delay_seconds": 3
  },
  "tasks": []
}
EOF
}

progress_content() {
  cat <<'EOF'
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
- Passing tasks: 0/0
- Next task: planning required
- Last verification: not run

## Log

### Session 0 - Harness Initialized

#### What changed
- Created missing Work Loop harness files without overwriting existing files.

#### Current status
- No business code has been changed.
- `architecture.md` and `task.json` must be populated from the user request.

#### Next
- Fill the architecture and task plan, list the task overview for the user, and wait for approval.
EOF
}

init_content() {
  cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_root"

echo "Work Loop init: $project_root"

run_node_init() {
  local install_cmd="$1"
  local dev_cmd="$2"

  echo "Installing dependencies: $install_cmd"
  $install_cmd

  if node -e "const s=require('./package.json').scripts||{}; process.exit(s.dev ? 0 : 1)" >/dev/null 2>&1; then
    if [ -f .work-loop-dev.pid ] && kill -0 "$(cat .work-loop-dev.pid)" 2>/dev/null; then
      echo "Dev server already running with PID $(cat .work-loop-dev.pid)"
    else
      echo "Starting dev server: $dev_cmd"
      nohup $dev_cmd > .work-loop-dev.log 2>&1 &
      echo $! > .work-loop-dev.pid
      sleep 3
      echo "Dev server PID $(cat .work-loop-dev.pid); log: .work-loop-dev.log"
    fi
  else
    echo "No package.json dev script found."
  fi
}

if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then
    command -v pnpm >/dev/null 2>&1 || { echo "pnpm is required."; exit 1; }
    run_node_init "pnpm install" "pnpm run dev"
  elif [ -f yarn.lock ]; then
    command -v yarn >/dev/null 2>&1 || { echo "yarn is required."; exit 1; }
    run_node_init "yarn install" "yarn dev"
  else
    command -v npm >/dev/null 2>&1 || { echo "npm is required."; exit 1; }
    run_node_init "npm install" "npm run dev"
  fi
elif [ -f pyproject.toml ]; then
  echo "Python project detected. Add the project-specific setup and server command to init.sh."
elif [ -f requirements.txt ]; then
  echo "Python requirements detected. Add virtualenv setup to init.sh if needed."
elif [ -f Cargo.toml ]; then
  command -v cargo >/dev/null 2>&1 || { echo "cargo is required."; exit 1; }
  cargo fetch
elif [ -f go.mod ]; then
  command -v go >/dev/null 2>&1 || { echo "go is required."; exit 1; }
  go mod download
else
  echo "No known dependency manifest detected. Customize init.sh for this project."
fi

echo "Work Loop init complete."
EOF
}

automation_content() {
  cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: run-automation.sh [--agent codex|claude|auto] [--task-file task.json] [--max-runs N] [--tasks-per-run N] [--delay SEC]

Run approved Work Loop tasks through repeated fresh agent sessions.
USAGE
}

agent="auto"
task_file="task.json"
max_runs=""
tasks_per_run=""
delay=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) agent="${2:-}"; shift 2 ;;
    --task-file) task_file="${2:-}"; shift 2 ;;
    --max-runs) max_runs="${2:-}"; shift 2 ;;
    --tasks-per-run) tasks_per_run="${2:-}"; shift 2 ;;
    --delay) delay="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$agent" in
  auto|codex|claude) ;;
  *) echo "Invalid --agent: $agent" >&2; exit 2 ;;
esac

if [ ! -f "$task_file" ]; then
  echo "Task file not found: $task_file" >&2
  exit 1
fi

json_eval() {
  local expr="$1"
  if command -v node >/dev/null 2>&1; then
    TASK_FILE="$task_file" EXPR="$expr" node <<'NODE'
const fs = require('fs');
const taskFile = process.env.TASK_FILE;
const expr = process.env.EXPR;
const t = JSON.parse(fs.readFileSync(taskFile, 'utf8'));
const value = Function('t', `return (${expr});`)(t);
if (value !== undefined && value !== null) console.log(value);
NODE
  elif command -v python3 >/dev/null 2>&1; then
    TASK_FILE="$task_file" EXPR="$expr" python3 <<'PY'
import json, os
t = json.load(open(os.environ["TASK_FILE"]))
expr = os.environ["EXPR"]
if expr in ("approval", "t.approval && t.approval.status"):
    v = t.get("approval", {}).get("status")
elif expr in ("remaining", "(t.tasks||[]).filter(x => x.passes !== true).length"):
    v = len([x for x in t.get("tasks", []) if x.get("passes") is not True])
elif expr in ("total", "(t.tasks||[]).length"):
    v = len(t.get("tasks", []))
elif expr in ("tasks_per_run", "t.execution && t.execution.tasks_per_run"):
    v = t.get("execution", {}).get("tasks_per_run")
elif expr in ("max_runs", "t.execution && t.execution.max_runs"):
    v = t.get("execution", {}).get("max_runs")
elif expr in ("delay", "t.execution && t.execution.delay_seconds"):
    v = t.get("execution", {}).get("delay_seconds")
else:
    raise SystemExit(1)
if v is not None:
    print(v)
PY
  else
    echo "node or python3 is required to inspect $task_file" >&2
    exit 1
  fi
}

approval_status="$(json_eval "t.approval && t.approval.status" 2>/dev/null || json_eval approval)"
if [ "$approval_status" != "approved" ]; then
  echo "$task_file is not approved. Review architecture.md and task.json with the user first." >&2
  exit 1
fi

total="$(json_eval "(t.tasks||[]).length" 2>/dev/null || json_eval total)"
remaining="$(json_eval "(t.tasks||[]).filter(x => x.passes !== true).length" 2>/dev/null || json_eval remaining)"

if [ "$total" -eq 0 ]; then
  echo "$task_file has no tasks. Populate concrete tasks before automation." >&2
  exit 1
fi

if [ -z "$tasks_per_run" ]; then
  tasks_per_run="$(json_eval "t.execution && t.execution.tasks_per_run" 2>/dev/null || json_eval tasks_per_run || true)"
  tasks_per_run="${tasks_per_run:-3}"
fi
if [ -z "$max_runs" ]; then
  max_runs="$(json_eval "t.execution && t.execution.max_runs" 2>/dev/null || json_eval max_runs || true)"
  max_runs="${max_runs:-8}"
fi
if [ -z "$delay" ]; then
  delay="$(json_eval "t.execution && t.execution.delay_seconds" 2>/dev/null || json_eval delay || true)"
  delay="${delay:-3}"
fi

case "$tasks_per_run" in ''|*[!0-9]*|0) echo "--tasks-per-run must be a positive integer" >&2; exit 2 ;; esac
case "$max_runs" in ''|*[!0-9]*|0) echo "--max-runs must be a positive integer" >&2; exit 2 ;; esac
case "$delay" in ''|*[!0-9]*) echo "--delay must be a non-negative integer" >&2; exit 2 ;; esac

detect_agent() {
  if command -v codex >/dev/null 2>&1; then
    echo "codex"
  elif command -v claude >/dev/null 2>&1; then
    echo "claude"
  else
    echo ""
  fi
}

if [ "$agent" = "auto" ]; then
  agent="$(detect_agent)"
  if [ -z "$agent" ]; then
    echo "No supported agent CLI found. Install Codex or Claude Code, or pass --agent." >&2
    exit 1
  fi
fi

mkdir -p automation-logs
main_log="automation-logs/work-loop-$(date +%Y%m%d_%H%M%S).log"

run_agent() {
  local prompt
  prompt="Use the repo Work Loop harness. Read CLAUDE.md or AGENTS.md, architecture.md, task.json, and progress.md. Run ./init.sh before each task. Work in continue mode for up to $tasks_per_run unblocked dependency-satisfied tasks. For each task: verify dependencies, implement only that task, run acceptance and verification checks, set passes true only after evidence, append progress.md, and commit one coherent task when possible. Do not launch run-automation.sh from inside this supervised run. Stop if blocked or if no unblocked tasks remain."

  case "$agent" in
    codex) codex exec -a never -s workspace-write "$prompt" ;;
    claude) claude -p --dangerously-skip-permissions "$prompt" ;;
  esac
}

echo "Work Loop automation"
echo "Agent: $agent"
echo "Task file: $task_file"
echo "Tasks per run: $tasks_per_run"
echo "Max runs: $max_runs"
echo "Initial progress: $((total - remaining))/$total passing"
echo "Log: $main_log"

for run in $(seq 1 "$max_runs"); do
  before="$(json_eval "(t.tasks||[]).filter(x => x.passes !== true).length" 2>/dev/null || json_eval remaining)"
  if [ "$before" -eq 0 ]; then
    echo "All tasks complete." | tee -a "$main_log"
    exit 0
  fi

  echo "Run $run/$max_runs: $before task(s) remaining" | tee -a "$main_log"
  run_log="automation-logs/run-${run}-$(date +%Y%m%d_%H%M%S).log"

  set +e
  run_agent > >(tee "$run_log") 2>&1
  exit_code=$?
  set -e

  after="$(json_eval "(t.tasks||[]).filter(x => x.passes !== true).length" 2>/dev/null || json_eval remaining)"
  completed=$((before - after))

  echo "Run $run exit code: $exit_code" | tee -a "$main_log"
  echo "Completed this run: $completed" | tee -a "$main_log"
  echo "Remaining: $after" | tee -a "$main_log"

  if [ "$completed" -le 0 ]; then
    echo "Stopping: no progress in this run. Review $run_log." | tee -a "$main_log"
    exit 1
  fi

  if [ "$after" -eq 0 ]; then
    echo "All tasks complete." | tee -a "$main_log"
    exit 0
  fi

  if [ "$run" -lt "$max_runs" ]; then
    sleep "$delay"
  fi
done

echo "Stopped after max runs." | tee -a "$main_log"
exit 0
EOF
}

instruction_content() {
  local agent_name="$1"
  cat <<EOF
# $project_name Work Loop Instructions

This repository uses a self-looping coding harness. The source of truth is:

- \`architecture.md\`: design and scope
- \`task.json\`: dependency-aware task list
- \`progress.md\`: cross-session handoff
- \`init.sh\`: idempotent startup script

## Startup

At the start of every new conversation or automated run:

1. Read this file
2. Read \`architecture.md\`
3. Read \`task.json\`
4. Read \`progress.md\`
5. Do not rely on prior chat context

## Approval Gate

Before \`task.json.approval.status\` is \`approved\`:

- You may inspect the repo and edit harness/planning files
- You must populate \`architecture.md\` and \`task.json\` from the user's request
- You must list the task overview for the user
- You must not edit business code, run \`./init.sh\`, install dependencies, start servers, run automation, or mark tasks passing

When the user approves, record approval metadata in \`task.json\` and \`progress.md\`.

## Task Selection

Select the lowest numeric task where \`passes\` is not \`true\` and every ID in
\`depends_on\` already has \`passes: true\`. Never start a task with unfinished
dependencies.

## Per-Task Loop

For each task:

1. Run \`./init.sh\`
2. Regression-check previously passing work when any exists
3. Implement only the selected task
4. Verify every step, acceptance item, and verification item
5. Set only that task's \`passes\` to \`true\`
6. Append \`progress.md\`
7. Commit one coherent task when git is available

## Modes

- \`checkpoint\`: finish one task and stop
- \`continue\`: keep looping through unblocked tasks until done, blocked, failed, or over budget
- \`automation\`: launch \`./run-automation.sh\` after approval

If a bare approval reply gives no mode, use
\`task.json.execution.default_mode_after_approval\`.

## Stop Conditions

Stop and write a blocker entry if verification fails, dependencies are blocked,
credentials/tools are missing, or the repo cannot be left in a clean state.

Generated for $agent_name. Keep these instructions aligned with the harness files.
EOF
}

echo "Setting up Work Loop harness in $target_dir"

write_file "$target_dir/architecture.md" "$(architecture_content)" || true
write_file "$target_dir/task.json" "$(task_content)" || true
write_file "$target_dir/progress.md" "$(progress_content)" || true
if write_file "$target_dir/init.sh" "$(init_content)"; then
  chmod +x "$target_dir/init.sh"
fi
if write_file "$target_dir/run-automation.sh" "$(automation_content)"; then
  chmod +x "$target_dir/run-automation.sh"
fi

case "$platform" in
  claude)
    write_file "$target_dir/CLAUDE.md" "$(instruction_content "Claude Code")" || true
    ;;
  codex)
    write_file "$target_dir/AGENTS.md" "$(instruction_content "Codex")" || true
    ;;
  all)
    write_file "$target_dir/CLAUDE.md" "$(instruction_content "Claude Code")" || true
    write_file "$target_dir/AGENTS.md" "$(instruction_content "Codex")" || true
    ;;
esac

echo "Work Loop harness setup complete."
echo "Next: populate architecture.md and task.json from the user request, then ask for approval."
