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
- Counts: passed 0, failed_or_blocked 0, remaining 0, total 0
- Next task: planning required

## Log

### blocker - Task none: planning required

#### Counts
- passed: 0
- failed_or_blocked: 0
- remaining: 0
- total: 0

#### Blocker
- Task list is not populated and plan approval is pending.

#### Partial Work
- Created missing Work Loop harness files without overwriting existing files.

#### Needed
- Fill the architecture and task plan, list the task overview for the user, and wait for approval.

#### Resume
- Populate `architecture.md` and `task.json`; do not edit business code before approval.
EOF
}

init_content() {
  cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_root"

echo "Work Loop init: $project_root"

require_command() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || {
    echo "Missing required command: $name" >&2
    exit 1
  }
  echo "Found command: $name"
}

require_path() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
  echo "Found path: $path"
}

require_port() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 || {
      echo "Required service is not listening on port $port" >&2
      exit 1
    }
  elif command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$port" >/dev/null 2>&1 || {
      echo "Required service is not listening on port $port" >&2
      exit 1
    }
  else
    echo "Cannot check port $port because neither lsof nor nc is available." >&2
    exit 1
  fi
  echo "Service listening on port: $port"
}

check_url() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$url" >/dev/null || {
      echo "Required URL is not healthy: $url" >&2
      exit 1
    }
    echo "URL healthy: $url"
  else
    echo "Cannot check URL $url because curl is not available." >&2
    exit 1
  fi
}

# Customize this file for the project after planning is approved.
# Keep it idempotent and conservative:
# - check only commands, files, ports, simulators, databases, or local services
#   that this project actually needs
# - do not install dependencies just because a manifest exists
# - do not start generic dev servers unless this project explicitly requires it
#
# Examples:
#   require_command xcodebuild
#   require_path MyApp.xcworkspace
#   require_command node
#   require_port 3000
#   check_url http://127.0.0.1:3000/health

if [ -f package.json ]; then
  echo "Detected package.json. Add project-specific Node checks if this repo needs them."
fi
if compgen -G "*.xcodeproj" >/dev/null || compgen -G "*.xcworkspace" >/dev/null; then
  echo "Detected iOS/Xcode project. Add xcodebuild, simulator, workspace, or service checks if needed."
fi
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  echo "Detected Python project. Add project-specific Python environment checks if needed."
fi
if [ -f Cargo.toml ]; then
  echo "Detected Rust project. Add project-specific cargo/toolchain checks if needed."
fi
if [ -f go.mod ]; then
  echo "Detected Go project. Add project-specific Go/toolchain checks if needed."
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

has_jq_tasks() {
  command -v jq >/dev/null 2>&1 && jq -e '.tasks | type == "array"' "$task_file" >/dev/null 2>&1
}

count_total() {
  if has_jq_tasks; then
    jq '.tasks | length' "$task_file"
  else
    grep -c '"passes"' "$task_file" 2>/dev/null || echo "0"
  fi
}

count_remaining() {
  if has_jq_tasks; then
    jq '[.tasks[] | select(.passes != true)] | length' "$task_file"
  else
    grep -Ec '"passes"[[:space:]]*:[[:space:]]*false' "$task_file" 2>/dev/null || echo "0"
  fi
}

approval_status() {
  if has_jq_tasks; then
    jq -r '.approval.status // empty' "$task_file"
  else
    sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$task_file" | head -n 1
  fi
}

read_number_key() {
  local key="$1"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p" "$task_file" | head -n 1
}

read_execution_number() {
  local primary="$1"
  local legacy="$2"
  local value=""

  if has_jq_tasks; then
    value="$(jq -r --arg primary "$primary" --arg legacy "$legacy" '.execution[$primary] // .execution[$legacy] // empty' "$task_file")"
  else
    value="$(read_number_key "$primary")"
    if [ -z "$value" ] && [ -n "$legacy" ]; then
      value="$(read_number_key "$legacy")"
    fi
  fi

  case "$value" in
    ''|*[!0-9]*) return 1 ;;
    *) printf '%s\n' "$value" ;;
  esac
}

approval_status="$(approval_status)"
if [ "$approval_status" != "approved" ]; then
  echo "$task_file is not approved. Review architecture.md and task.json with the user first." >&2
  exit 1
fi

total="$(count_total)"
remaining="$(count_remaining)"

if [ "$total" -eq 0 ]; then
  echo "$task_file has no tasks. Populate concrete tasks before automation." >&2
  exit 1
fi

if [ -z "$tasks_per_run" ]; then
  tasks_per_run="$(read_execution_number "tasks_per_run" "default_tasks_per_run" || true)"
  tasks_per_run="${tasks_per_run:-3}"
fi
if [ -z "$max_runs" ]; then
  max_runs="$(read_execution_number "max_runs" "default_max_runs_after_approval" || true)"
  max_runs="${max_runs:-8}"
fi
if [ -z "$delay" ]; then
  delay="$(read_execution_number "delay_seconds" "default_delay_seconds" || true)"
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
  prompt="Use the repo Work Loop harness task execution workflow, not the initialization workflow. Read CLAUDE.md or AGENTS.md, architecture.md, task.json, and progress.md. Run ./init.sh before each task to check project-specific prerequisites. Work in continue mode for up to $tasks_per_run unblocked dependency-satisfied tasks. For each task: verify dependencies, implement only that task by completing its steps as implementation sub-steps, then run acceptance and verification checks. Complete the mandatory checkpoint before claiming success or moving on: update the exact task in task.json to passes true, append a task-complete entry in progress.md naming that task with verification evidence and counts for passed, failed_or_blocked, remaining, and total, re-read both files to confirm the updates, then commit one coherent task including implementation changes, task.json, and progress.md when possible. Do not commit before task.json and progress.md are updated. Do not launch run-automation.sh from inside this supervised run. Stop if blocked or if no unblocked tasks remain."

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
  before="$(count_remaining)"
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

  after="$(count_remaining)"
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
- \`init.sh\`: idempotent project-specific prerequisite check

## Workflow Split

There are two separate workflows:

1. **Harness initialization / planning**: create or repair harness files, tailor
   \`init.sh\`, populate \`architecture.md\` and \`task.json\`, list the task
   overview, and wait for approval. No product code changes happen here.
2. **Task execution**: after approval, select one dependency-ready task,
   implement it, verify it, update \`task.json\` and \`progress.md\`, then commit.

## Startup

At the start of every new conversation or automated run:

1. Read this file
2. Read \`architecture.md\`
3. Read \`task.json\`
4. Read \`progress.md\`
5. Do not rely on prior chat context

## Harness Initialization / Planning

Before \`task.json.approval.status\` is \`approved\`:

- You may inspect the repo and edit harness/planning files
- You must populate \`architecture.md\` and \`task.json\` from the user's request
- You may tailor \`init.sh\` as a conservative project-specific prerequisite check
- Tasks must use \`passes\` as the only completion state; do not add task-level \`status\`
- Tasks should include \`steps\` as concrete implementation sub-steps
- Put completion criteria in \`acceptance\` and proof commands/manual checks in \`verification\`
- You must list the task overview for the user
- You must not edit business code, run \`./init.sh\`, install dependencies, start servers, run automation, or mark tasks passing

When the user approves, record approval metadata in \`task.json\` and \`progress.md\`.

\`init.sh\` is not the task workflow. It should only check this project's
required commands, files, ports, simulators, services, or health URLs. Do not
install dependencies or start generic services just because a manifest exists.

## Task Execution Workflow

Use this workflow only after approval.

### Task Selection

Select the lowest numeric task where \`passes\` is not \`true\` and every ID in
\`depends_on\` already has \`passes: true\`. Never start a task with unfinished
dependencies.

### Per-Task Loop

For each task:

1. Run \`./init.sh\`
2. Confirm the required tools/services for this project are available
3. Regression-check previously passing work when any exists
4. Implement only the selected task
5. Complete every implementation sub-step in \`steps\`
6. Verify every acceptance item and verification item
7. Set only that task's \`passes\` to \`true\`
8. Append \`progress.md\`
9. Re-read \`task.json\` and \`progress.md\` to confirm both updates
10. Commit one coherent task when git is available

## Mandatory Completion Checkpoint

A task is not complete until both of these are true:

- The exact task in \`task.json\` has \`passes: true\`
- \`progress.md\` has a new entry naming that task and recording verification evidence

After updating both files, re-read them to confirm the checkpoint. Do not report
success, stop checkpoint mode, or continue to another task until this checkpoint
is complete. If either file cannot be updated, leave the task as \`passes: false\`,
write a blocker entry in \`progress.md\`, and stop.

Commit only after the checkpoint is complete. A task commit must include the
implementation changes, \`task.json\`, and \`progress.md\` together.

\`progress.md\` uses only two entry types: \`task-complete\` and \`blocker\`.
Every entry must include counts for passed, failed_or_blocked, remaining, and total.

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
