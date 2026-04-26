#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: run-automation.sh [--agent codex|claude|auto] [--task-file task.json] [--max-runs N] [--tasks-per-run N] [--delay SEC]

Optional outer loop for approved Work Loop projects.

This script is not used by default. Run it only after reviewing and approving
architecture.md and task.json.
USAGE
}

agent="auto"
task_file="task.json"
max_runs=""
tasks_per_run=""
delay="3"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      agent="${2:-}"
      shift 2
      ;;
    --task-file)
      task_file="${2:-}"
      shift 2
      ;;
    --max-runs)
      max_runs="${2:-}"
      shift 2
      ;;
    --tasks-per-run)
      tasks_per_run="${2:-}"
      shift 2
      ;;
    --delay)
      delay="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$agent" in
  auto|codex|claude) ;;
  *)
    echo "Invalid --agent: $agent" >&2
    exit 2
    ;;
esac

if [ ! -f "$task_file" ]; then
  echo "Task file not found: $task_file" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to inspect $task_file." >&2
  exit 1
fi

json_get() {
  local expr="$1"
  node -e "const t=require('./$task_file'); const v=($expr); if (v !== undefined && v !== null) console.log(v)"
}

json_count_remaining() {
  node -e "const t=require('./$task_file'); console.log((t.tasks||[]).filter(x => x.passes !== true).length)"
}

json_count_total() {
  node -e "const t=require('./$task_file'); console.log((t.tasks||[]).length)"
}

approval_status="$(json_get "t.approval && t.approval.status")"
if [ "$approval_status" != "approved" ]; then
  echo "$task_file is not approved. Set approval.status to approved after human review." >&2
  exit 1
fi

if [ -z "$max_runs" ]; then
  max_runs="$(json_get "t.execution && t.execution.default_max_runs_after_approval")"
  max_runs="${max_runs:-10}"
fi

if [ -z "$tasks_per_run" ]; then
  tasks_per_run="$(json_get "t.execution && t.execution.default_tasks_per_run")"
  tasks_per_run="${tasks_per_run:-3}"
fi

case "$max_runs" in ''|*[!0-9]*|0) echo "--max-runs must be a positive integer" >&2; exit 2 ;; esac
case "$tasks_per_run" in ''|*[!0-9]*|0) echo "--tasks-per-run must be a positive integer" >&2; exit 2 ;; esac
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
  prompt="Use the Work Loop project instructions. Run ./init.sh, regression-check already passing tasks, then complete up to $tasks_per_run unblocked tasks from $task_file. For each task, satisfy steps, acceptance, and verification before setting passes true. Update progress.md and commit each completed task when possible. Stop honestly if blocked."

  case "$agent" in
    codex)
      codex exec -a never -s workspace-write "$prompt"
      ;;
    claude)
      claude -p --dangerously-skip-permissions "$prompt"
      ;;
  esac
}

total="$(json_count_total)"
initial_remaining="$(json_count_remaining)"

echo "Work Loop automation"
echo "Agent: $agent"
echo "Task file: $task_file"
echo "Tasks per run: $tasks_per_run"
echo "Max runs: $max_runs"
echo "Initial progress: $((total - initial_remaining))/$total passing"
echo "Log: $main_log"

for run in $(seq 1 "$max_runs"); do
  remaining_before="$(json_count_remaining)"
  if [ "$remaining_before" -eq 0 ]; then
    echo "All tasks complete." | tee -a "$main_log"
    exit 0
  fi

  echo "Run $run/$max_runs: $remaining_before tasks remaining" | tee -a "$main_log"
  run_log="automation-logs/run-${run}-$(date +%Y%m%d_%H%M%S).log"

  set +e
  run_agent > >(tee "$run_log") 2>&1
  exit_code=$?
  set -e

  remaining_after="$(json_count_remaining)"
  completed_this_run=$((remaining_before - remaining_after))

  echo "Run $run exit code: $exit_code" | tee -a "$main_log"
  echo "Completed this run: $completed_this_run" | tee -a "$main_log"
  echo "Remaining: $remaining_after" | tee -a "$main_log"

  if [ "$completed_this_run" -le 0 ]; then
    echo "Stopping: no progress in this run. Review $run_log." | tee -a "$main_log"
    exit 1
  fi

  if [ "$remaining_after" -eq 0 ]; then
    echo "All tasks complete." | tee -a "$main_log"
    exit 0
  fi

  if [ "$run" -lt "$max_runs" ]; then
    sleep "$delay"
  fi
done

echo "Stopped after max runs. Remaining tasks: $(json_count_remaining)" | tee -a "$main_log"
