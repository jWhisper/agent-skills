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
