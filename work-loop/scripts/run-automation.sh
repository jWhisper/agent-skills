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
