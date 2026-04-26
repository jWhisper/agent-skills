#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_NAME=""
PROJECT_SPEC=""
PLATFORM="all"
TARGET_DIR="."
ARCHITECTURE_FILE="architecture.md"
TASK_FILE="task.json"
PROGRESS_FILE="progress.md"
FORCE=0
TASKS_PER_RUN=50

usage() {
    cat <<'EOF'
setup-harness.sh — scaffold the work-loop project harness

Usage:
  bash setup-harness.sh [OPTIONS]

Options:
  --name NAME             Project name (default: target directory name)
  --spec SPEC             One-paragraph project summary
  --platform PLATFORM     claude|codex|all (default: all)
  --dir DIR               Target project directory (default: current directory)
  --architecture-file FILE Architecture file name (default: architecture.md)
  --task-file FILE        Task file name (default: task.json)
  --progress-file FILE    Progress log name (default: progress.md)
  --tasks-per-run N       Suggested batch size for automation prompts (default: 50)
  --force                 Overwrite existing harness files
  -h, --help              Show this help message
EOF
}

fail() { echo -e "${RED}Error:${NC} $*" >&2; exit 1; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $*"; }

require_value() {
    local option="$1" value="${2:-}"
    [ -n "$value" ] || fail "Missing value for ${option}"
}

json_escape() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$1"
    else
        printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    fi
}

write_file() {
    local path="$1" content="$2"
    if [ -e "$path" ] && [ "$FORCE" -ne 1 ]; then
        warn "$path already exists"
        return
    fi
    printf '%s\n' "$content" > "$path"
    success "Wrote $path"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)            require_value "$1" "${2:-}"; PROJECT_NAME="$2"; shift 2 ;;
        --spec)            require_value "$1" "${2:-}"; PROJECT_SPEC="$2"; shift 2 ;;
        --platform)        require_value "$1" "${2:-}"; PLATFORM="$2"; shift 2 ;;
        --dir)             require_value "$1" "${2:-}"; TARGET_DIR="$2"; shift 2 ;;
        --architecture-file) require_value "$1" "${2:-}"; ARCHITECTURE_FILE="$2"; shift 2 ;;
        --task-file)       require_value "$1" "${2:-}"; TASK_FILE="$2"; shift 2 ;;
        --progress-file)   require_value "$1" "${2:-}"; PROGRESS_FILE="$2"; shift 2 ;;
        --tasks-per-run)   require_value "$1" "${2:-}"; TASKS_PER_RUN="$2"; shift 2 ;;
        --force)           FORCE=1; shift ;;
        -h|--help)         usage; exit 0 ;;
        *)                 fail "Unknown option: $1" ;;
    esac
done

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

DEFAULT_NAME=$(basename "$(pwd)")
if [ -z "$PROJECT_NAME" ]; then
    if [ -t 0 ]; then
        read -r -p "Project name [$DEFAULT_NAME]: " PROJECT_NAME
        PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"
    else
        PROJECT_NAME="$DEFAULT_NAME"
    fi
fi

if [ -z "$PROJECT_SPEC" ] && [ -t 0 ]; then
    read -r -p "Project summary (optional): " PROJECT_SPEC
fi

case "$PLATFORM" in claude|codex|all) ;; *) fail "Unsupported --platform: $PLATFORM" ;; esac
case "$TASKS_PER_RUN" in ''|*[!0-9]*) fail "--tasks-per-run must be a positive integer" ;; 0) fail "--tasks-per-run must be greater than 0" ;; esac

TASK_JSON_PROJECT=$(json_escape "$PROJECT_NAME")
TASK_JSON_SPEC=$(json_escape "$PROJECT_SPEC")

# --- file content generators ---

task_file_content() {
    cat <<EOF
{
  "project": $TASK_JSON_PROJECT,
  "spec": $TASK_JSON_SPEC,
  "approval": {
    "status": "needs-user-approval",
    "approved_by": null,
    "approved_at": null
  },
  "execution": {
    "bare_approval_starts_execution": true,
    "default_mode_after_approval": "continuous-batch",
    "default_tasks_per_run": $TASKS_PER_RUN,
    "default_max_runs_after_approval": 8,
    "default_delay_seconds": 3
  },
  "tasks": []
}
EOF
}

architecture_file_content() {
    cat <<EOF
# $PROJECT_NAME Architecture

## Product Summary

- Replace this stub with the user-facing problem statement and the product goal.

## Requirements Snapshot

- Capture the key functional requirements from the prompt or spec.

## Proposed Stack

- List the chosen technologies and why they fit this project.

## System Design

- Describe the main modules, boundaries, data flow, and external integrations.

## Delivery Plan

- Explain the implementation phases that informed the task breakdown.

## Risks And Open Questions

- Record assumptions, tradeoffs, and anything the user should confirm.

## Out Of Scope

- State what this version will not include.
EOF
}

progress_file_content() {
    echo "# Progress"
}

init_file_content() {
    cat <<EOF
#!/bin/bash
set -euo pipefail

PROJECT_ROOT=\$(cd "\$(dirname "\$0")" && pwd)
cd "\$PROJECT_ROOT"

echo "Initializing $PROJECT_NAME..."

# 1) Install dependencies for your stack. Keep this idempotent.
# Examples:
#   npm install
#   pip install -r requirements.txt

# 2) Start long-lived services only if they are not already running.
# Example:
#   if ! lsof -ti:3000 >/dev/null 2>&1; then
#     npm run dev > .work-loop.dev.log 2>&1 &
#   fi

# 3) Wait for readiness and print the URLs that future sessions should use.
# Example:
#   echo "App ready at http://127.0.0.1:3000"

echo "Customize init.sh for your stack, then rerun before coding."
EOF
}

instruction_file_content() {
    local instruction_name="$1"
    cat <<EOF
# $PROJECT_NAME — Agent Workflow

This repository uses a long-running harness. The backlog is the source of truth
after the plan is approved.

## Source Of Truth Files

- \`$ARCHITECTURE_FILE\` — approved system design and scope boundaries
- \`$TASK_FILE\` — ordered backlog with immutable task definitions
- \`$PROGRESS_FILE\` — cross-session handoff log
- \`init.sh\` — idempotent environment bootstrap

## Planning Gate

Before any product implementation:

1. Read the user prompt or requirements document
2. Write or update \`$ARCHITECTURE_FILE\`
3. Write or update \`$TASK_FILE\` with dependency-ordered tasks
4. Keep \`approval.status\` as \`needs-user-approval\` until the user explicitly approves
5. Summarize the plan and ask the user whether it is reasonable
6. Stop after asking for approval; do not implement product code yet

If the user asks for revisions, update the planning files and ask again.
Only after the user explicitly approves the plan should you set
\`approval.status\` to \`approved\`, record that approval in \`$PROGRESS_FILE\`,
and enter a coding mode.

If the user's approval reply is bare approval text with no narrower execution
instruction, such as \`approve\`, \`approved\`, \`looks good\`, \`go ahead\`,
\`可以\`, \`同意\`, \`开始\`, or \`继续\`, treat that as:

1. Approval to record in \`$TASK_FILE\`
2. Authorization to start the default post-approval execution policy from
   \`execution.default_mode_after_approval\`
3. Permission to spend up to \`execution.default_tasks_per_run\` tasks in that
   first session, or up to \`execution.default_max_runs_after_approval\`
   supervised sessions if the default mode is \`automation-loop\`

## Three Execution Modes

### Mode A — Checkpoint

Use this **only** when the user's prompt explicitly asks for a single task.
**Never** use checkpoint as the result of a bare approval reply.

- Complete exactly one verified task
- Make exactly one task commit
- Stop and report cleanly

### Mode B — Continuous Batch (default after bare approval)

Enter this mode when a bare approval triggers \`continuous-batch\`, or when the
prompt explicitly asks to continue, keep going, run continuously, process the
queue, work until blocked, or similar wording such as \`continuous\`, \`batch\`,
\`keep going\`, \`continue until blocked\`, \`连续执行\`, \`继续跑\`, or
\`一直做到卡住为止\`.

In this mode:

- Still keep one task per commit
- After each completed task, **immediately** re-enter the loop for the next
  incomplete task — do NOT stop after the first task
- Stop only when you hit a blocker, fail regression checks, exhaust the
  task budget from \`execution.default_tasks_per_run\`, or empty the backlog

### Mode C — Automation Loop

Use this when the current prompt explicitly asks for unattended looping, or
when \`execution.default_mode_after_approval\` is \`automation-loop\`.

In this mode:

- Record plan approval if it was just granted
- Launch \`./run-automation.sh\` with the configured defaults unless the user
  supplied narrower limits
- Let the supervisor loop own subsequent sessions
- Do not manually continue coding tasks in the current interactive session after
  the supervisor is launched

## Mode Selection

1. Read \`$ARCHITECTURE_FILE\`, \`$TASK_FILE\`, and \`$PROGRESS_FILE\`.
2. If the architecture is missing, the task array is empty, or the plan is not
   approved, switch to Planning Gate mode.
3. If the latest user reply is a bare approval and
   \`execution.bare_approval_starts_execution\` is true, follow
   \`execution.default_mode_after_approval\`.
4. Otherwise choose Checkpoint, Continuous Batch, or Automation Loop from the
   current prompt.

## Task Loop

Repeat this loop once in Checkpoint mode, or **repeatedly** in Continuous Batch
mode (keep looping back after each commit until budget or blocker):

### Phase 1 — Prepare and Implement

1. Read \`$ARCHITECTURE_FILE\`, \`$PROGRESS_FILE\`, \`git log --oneline -20\`, and \`$TASK_FILE\`
2. Run \`./init.sh\`
3. Verify one or two previously passing flows still work
4. Pick the first task where \`passes: false\` and all \`depends_on\` are \`true\`
5. Implement only that task
6. Test thoroughly

### Phase 2 — Record and Commit (MANDATORY, do not skip)

After Phase 1, you MUST complete ALL of the following steps before reporting
success or starting the next task. Skipping any of these steps means the task
is not complete.

1. **Update \`$TASK_FILE\`**: change ONLY \`"passes": false\` to \`"passes": true\`
   for the completed task. Do not rewrite, reorder, or reformat anything else.
2. **Update \`$PROGRESS_FILE\`**: append a session entry with the task title,
   what was done, how it was tested, and current counts (passed/remaining/total).
3. **Verify the checkpoint**: re-read both files and confirm the task shows
   \`"passes": true\` and progress has the matching entry.
4. **Commit**: \`git add\` the implementation files, \`$TASK_FILE\`, and
   \`$PROGRESS_FILE\`, then commit with a descriptive message.

### If Blocked

Stop immediately. Do NOT mark \`passes: true\`. Document the blocker in
\`$PROGRESS_FILE\` and leave the repo buildable.

## Mandatory Completion Checkpoint

A task is NOT complete until BOTH of these are true:

- \`$TASK_FILE\` has the exact task updated to \`"passes": true\`
- \`$PROGRESS_FILE\` has a new entry naming that task with verification evidence and counts

Do NOT report success, start another task, or exit until this checkpoint is
confirmed by re-reading both files. If either file cannot be updated, leave the
task as \`passes: false\`, write a blocker entry, and stop.

## Testing Expectations

- Major UI work must be checked in a browser
- All changes should pass the repo's lint, build, and relevant test commands
- Do not mark a task complete until every step is verified

## Non-Negotiable Rules

1. No implementation before plan approval
2. One task per commit
3. Regression check before each new task
4. Never rewrite task titles, descriptions, or steps during normal coding
5. Never keep a second backlog or progress file in parallel
6. Leave the repo in a clean state for the next agent session or the next loop iteration

## When Work Is Blocked

If the task needs human input or an external dependency:

- Record what was completed in \`$PROGRESS_FILE\`
- Describe the blocker clearly
- Leave the repo building and runnable if possible
- Do not mark the task complete
- Do not commit a misleading "done" state

## Platform Note

This workflow was generated for $instruction_name. The process is the same across
agents; only the surrounding CLI changes.
EOF
}

# --- write files ---

info "Setting up work-loop harness in $(pwd)"
info "Architecture file: $ARCHITECTURE_FILE"
info "Task file: $TASK_FILE"
info "Progress file: $PROGRESS_FILE"
info "Platform: $PLATFORM"
info "Default tasks per session: $TASKS_PER_RUN"

write_file "$ARCHITECTURE_FILE" "$(architecture_file_content)"
write_file "$TASK_FILE" "$(task_file_content)"
write_file "$PROGRESS_FILE" "$(progress_file_content)"
write_file "init.sh" "$(init_file_content)"

if [ ! -e "run-automation.sh" ] || [ "$FORCE" -eq 1 ]; then
    cp "$script_dir/run-automation.sh" "run-automation.sh"
    chmod +x run-automation.sh
    success "Copied run-automation.sh"
else
    warn "run-automation.sh already exists"
fi

chmod +x init.sh 2>/dev/null || true

write_claude() { write_file "CLAUDE.md" "$(instruction_file_content "Claude Code")"; }
write_codex()  { write_file "AGENTS.md" "$(instruction_file_content "Codex")"; }

case "$PLATFORM" in
    claude) write_claude ;;
    codex)  write_codex ;;
    all)    write_claude; write_codex ;;
esac

if [ ! -d ".git" ]; then
    git init -q
    success "Initialized git repository"
else
    warn "Git repository already exists"
fi

echo ""
echo -e "${GREEN}Harness scaffold complete.${NC}"
echo "Next steps:"
echo "  1. Replace the stub in $ARCHITECTURE_FILE with the real architecture"
echo "  2. Populate $TASK_FILE from your product spec and keep approval pending"
echo "  3. Ask the user to approve the architecture and task plan"
echo "  4. After approval, customize init.sh for your stack and start coding"
echo "  5. For repeated unattended runs, use ./run-automation.sh"
