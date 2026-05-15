#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TASK_FILE="task.json"
ARCHITECTURE_FILE="architecture.md"
PROGRESS_FILE="progress.md"
AGENT=auto
TASKS_PER_RUN=50
MAX_RUNS=8
DELAY=3
TASKS_PER_RUN_EXPLICIT=0
MAX_RUNS_EXPLICIT=0
DELAY_EXPLICIT=0

usage() {
  cat <<'USAGE'
run-automation.sh — repeatedly launch supervised coding sessions

Usage:
  bash run-automation.sh [OPTIONS]

Options:
  --agent AGENT      claude|codex|auto (default: auto)
  --task-file FILE   Task file to inspect (default: task.json)
  --tasks-per-run N  Max tasks each session should try to finish (default: from task.json or 50)
  --max-runs N       Maximum number of agent sessions (default: from task.json or 8)
  --delay SEC        Seconds to wait between runs (default: from task.json or 3)
  -h, --help         Show this help message
USAGE
}

log() {
  local level="$1" message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${timestamp} [${level}] ${message}" >> "$MAIN_LOG"
  case "$level" in
    INFO)     echo -e "${BLUE}[INFO]${NC} ${message}" ;;
    SUCCESS)  echo -e "${GREEN}[OK]${NC} ${message}" ;;
    WARNING)  echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
    ERROR)    echo -e "${RED}[ERROR]${NC} ${message}" ;;
    PROGRESS) echo -e "${CYAN}[...]${NC} ${message}" ;;
  esac
}

count_total() {
  jq '.tasks | length' "$TASK_FILE"
}

count_remaining() {
  jq '[.tasks[] | select(.passes != true)] | length' "$TASK_FILE"
}

has_execution_policy() {
  jq -e 'has("execution")' "$TASK_FILE" >/dev/null 2>&1
}

has_approved_plan() {
  if jq -e 'has("approval")' "$TASK_FILE" >/dev/null 2>&1; then
    jq -e '.approval.status == "approved"' "$TASK_FILE" >/dev/null 2>&1
  else
    return 0
  fi
}

read_execution_number() {
  local jq_expr="$1"
  has_execution_policy || return 1
  local value
  value=$(jq -r "${jq_expr} // empty" "$TASK_FILE")
  case "$value" in ''|*[!0-9]*) return 1 ;; *) printf '%s\n' "$value" ;; esac
}

load_execution_defaults() {
  local value
  [ "$TASKS_PER_RUN_EXPLICIT" -eq 1 ] || { value=$(read_execution_number '.execution.default_tasks_per_run') && TASKS_PER_RUN="$value"; } || true
  [ "$MAX_RUNS_EXPLICIT" -eq 1 ] || { value=$(read_execution_number '.execution.default_max_runs_after_approval') && MAX_RUNS="$value"; } || true
  [ "$DELAY_EXPLICIT" -eq 1 ] || { value=$(read_execution_number '.execution.default_delay_seconds') && DELAY="$value"; } || true
}

detect_agent() {
  if command -v claude >/dev/null 2>&1; then echo "claude"
  elif command -v codex >/dev/null 2>&1; then echo "codex"
  else echo ""
  fi
}

# --- CLI parsing ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)        AGENT="$2"; shift 2 ;;
    --task-file)    TASK_FILE="$2"; shift 2 ;;
    --tasks-per-run) TASKS_PER_RUN="$2"; TASKS_PER_RUN_EXPLICIT=1; shift 2 ;;
    --max-runs)     MAX_RUNS="$2"; MAX_RUNS_EXPLICIT=1; shift 2 ;;
    --delay)        DELAY="$2"; DELAY_EXPLICIT=1; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- pre-flight checks ---

[ ! -f "$TASK_FILE" ] && { echo "Task file not found: $TASK_FILE" >&2; exit 1; }
! has_approved_plan && { echo "Plan not approved. Review $TASK_FILE with the user first." >&2; exit 1; }

load_execution_defaults

case "$TASKS_PER_RUN" in ''|*[!0-9]*|0) echo "--tasks-per-run must be a positive integer" >&2; exit 1 ;; esac
case "$MAX_RUNS" in ''|*[!0-9]*|0) echo "--max-runs must be a positive integer" >&2; exit 1 ;; esac
case "$DELAY" in ''|*[!0-9]*) echo "--delay must be a non-negative integer" >&2; exit 1 ;; esac

if [ "$AGENT" = "auto" ]; then
  AGENT=$(detect_agent)
  [ -z "$AGENT" ] && { echo "No supported agent CLI found. Install Claude Code or Codex." >&2; exit 1; }
fi

[ "$(count_total)" -eq 0 ] && { echo "Backlog is empty. Populate $TASK_FILE before starting." >&2; exit 1; }

LOG_DIR="./automation-logs"
mkdir -p "$LOG_DIR"
MAIN_LOG="$LOG_DIR/automation-$(date +%Y%m%d_%H%M%S).log"

# --- agent runners ---

run_claude() {
  local prompt_file
  prompt_file=$(mktemp)
  cat > "$prompt_file" <<PROMPT
Follow the workflow in CLAUDE.md for one supervised continuous-batch session.

- Read $ARCHITECTURE_FILE and $TASK_FILE before making changes
- This session is already supervised by ./run-automation.sh; do not launch it again
- Finish up to $TASKS_PER_RUN tasks in this session
- Run init.sh before coding and re-check regressions before each new task
- Keep one task per commit, but do not stop after the first completed task
- After each completed task, update the task file and progress log, commit, then continue
- Stop early if blocked, if regressions fail, or if the backlog is empty
PROMPT

  set +e
  claude -p \
    --dangerously-skip-permissions \
    --allowed-tools "Bash Edit Read Write Glob Grep Task WebSearch WebFetch mcp__playwright__*" \
    < "$prompt_file"
  local exit_code=$?
  set -e
  rm -f "$prompt_file"
  return "$exit_code"
}

run_codex() {
  codex exec -a never -s workspace-write \
    "Follow AGENTS.md for one supervised continuous-batch session. Read $ARCHITECTURE_FILE and $TASK_FILE, do not launch ./run-automation.sh again because this session is already supervised, finish up to $TASKS_PER_RUN verified tasks, keep one task per commit, update the task file and progress log after each task, stop early if blocked or if regressions fail or if the backlog is empty."
}

# --- main loop ---

initial_remaining=$(count_remaining)

echo ""
echo "========================================"
echo "  Work Loop — Automation"
echo "========================================"
echo ""

log "INFO" "Agent: $AGENT"
log "INFO" "Max runs: $MAX_RUNS"
log "INFO" "Task file: $TASK_FILE"
log "INFO" "Tasks per run: $TASKS_PER_RUN"
log "INFO" "Progress: $(( $(count_total) - initial_remaining ))/$(count_total) passing"
log "INFO" "Log: $MAIN_LOG"

for ((run = 1; run <= MAX_RUNS; run++)); do
  remaining_before=$(count_remaining)
  [ "$remaining_before" -eq 0 ] && { log "SUCCESS" "All tasks already pass."; exit 0; }

  log "PROGRESS" "Run $run of $MAX_RUNS — $remaining_before task(s) remaining"
  run_log="$LOG_DIR/run-${run}-$(date +%Y%m%d_%H%M%S).log"
  run_start=$(date +%s)

  set +e
  case "$AGENT" in
    claude) run_claude > >(tee "$run_log") 2>&1 ;;
    codex)  run_codex > >(tee "$run_log") 2>&1 ;;
    *)      echo "Unsupported agent: $AGENT" >&2; exit 1 ;;
  esac
  agent_exit=$?
  set -e

  remaining_after=$(count_remaining)
  run_end=$(date +%s)
  completed_this_run=$((remaining_before - remaining_after))

  if [ "$agent_exit" -eq 0 ]; then
    log "SUCCESS" "Run $run finished in $((run_end - run_start))s"
  else
    log "WARNING" "Run $run exited with code $agent_exit after $((run_end - run_start))s"
  fi

  [ "$completed_this_run" -gt 0 ] && log "SUCCESS" "Tasks completed: $completed_this_run"
  log "INFO" "Progress: $(( $(count_total) - remaining_after ))/$(count_total) passing"

  if [ "$remaining_after" -eq "$remaining_before" ]; then
    log "WARNING" "No progress in run $run. Stop and inspect the repo."
    exit 1
  fi

  [ "$remaining_after" -eq 0 ] && { log "SUCCESS" "All tasks completed."; exit 0; }
  [ "$run" -lt "$MAX_RUNS" ] && { log "INFO" "Waiting ${DELAY}s..."; sleep "$DELAY"; }
done

log "WARNING" "Reached max runs with $(count_remaining) task(s) remaining."
exit 0
