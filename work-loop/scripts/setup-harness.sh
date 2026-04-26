#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-harness.sh [--force] /path/to/project

Create lightweight Work Loop files in a target project.

Files are not overwritten unless --force is provided.
USAGE
}

force="no"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="yes"
      shift
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
      if [ "${project_dir:-}" ]; then
        echo "Only one project path is supported." >&2
        exit 2
      fi
      project_dir="$1"
      shift
      ;;
  esac
done

if [ -z "${project_dir:-}" ]; then
  usage >&2
  exit 2
fi

mkdir -p "$project_dir"
project_dir="$(cd "$project_dir" && pwd)"

write_file() {
  local path="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if [ -e "$path" ] && [ "$force" != "yes" ]; then
    echo "Skipped existing $path"
    rm -f "$tmp"
    return
  fi

  mkdir -p "$(dirname "$path")"
  mv "$tmp" "$path"
  echo "Wrote $path"
}

write_file "$project_dir/architecture.md" <<'EOF'
# Architecture

## Goal

Describe the user-visible goal for this project.

## Current Facts

- Repository shape:
- Existing stack:
- Important commands:

## Approach

Describe the intended implementation at a level the user can approve before coding.

## Verification

- Add the main checks for this project here.
EOF

write_file "$project_dir/task.json" <<'EOF'
{
  "project": "Project name",
  "description": "Short project goal",
  "approval": {
    "status": "pending",
    "approved_by": "",
    "approved_at": ""
  },
  "execution": {
    "default_mode_after_approval": "continuous-batch",
    "default_tasks_per_run": 3,
    "default_max_runs_after_approval": 10
  },
  "tasks": [
    {
      "id": 1,
      "title": "Define the first implementation task",
      "category": "functional",
      "description": "Replace this placeholder with the first concrete task.",
      "depends_on": [],
      "steps": [
        "Open or run the relevant project surface",
        "Perform the user-visible action",
        "Verify the expected result",
        "Run the relevant repository check"
      ],
      "acceptance": [
        "All listed steps pass",
        "No related previously-passing behavior regresses"
      ],
      "verification": [
        "Run the relevant lint/build/test command",
        "For UI changes, verify the flow in a browser and check for console errors"
      ],
      "passes": false
    }
  ]
}
EOF

write_file "$project_dir/progress.md" <<EOF
# Progress

## Current State

- Approval: pending
- Next task: first task with "passes": false
- Last verification: not run

## Log

- $(date +%F): Initialized Work Loop files.
EOF

write_file "$project_dir/init.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Initializing project environment..."

run_node_app() {
  local install_cmd="$1"
  local dev_cmd="$2"

  echo "Installing dependencies with: $install_cmd"
  $install_cmd

  if node -e "const s=require('./package.json').scripts||{}; process.exit(s.dev ? 0 : 1)" >/dev/null 2>&1; then
    if [ -f .work-loop-dev.pid ] && kill -0 "$(cat .work-loop-dev.pid)" 2>/dev/null; then
      echo "Development server already running with PID $(cat .work-loop-dev.pid)."
    else
      echo "Starting development server with: $dev_cmd"
      nohup $dev_cmd > .work-loop-dev.log 2>&1 &
      echo $! > .work-loop-dev.pid
      sleep 3
      echo "Development server started with PID $(cat .work-loop-dev.pid). Logs: .work-loop-dev.log"
    fi
  else
    echo "No package.json dev script found; dependency setup complete."
  fi
}

if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then
    command -v pnpm >/dev/null 2>&1 || { echo "pnpm is required but not installed."; exit 1; }
    run_node_app "pnpm install" "pnpm run dev"
  elif [ -f yarn.lock ]; then
    command -v yarn >/dev/null 2>&1 || { echo "yarn is required but not installed."; exit 1; }
    run_node_app "yarn install" "yarn dev"
  elif [ -f package-lock.json ]; then
    command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed."; exit 1; }
    run_node_app "npm install" "npm run dev"
  else
    command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed."; exit 1; }
    run_node_app "npm install" "npm run dev"
  fi
elif [ -f pyproject.toml ]; then
  echo "Detected Python project. Add the project-specific install and server commands to init.sh."
elif [ -f Cargo.toml ]; then
  command -v cargo >/dev/null 2>&1 || { echo "cargo is required but not installed."; exit 1; }
  cargo fetch
elif [ -f go.mod ]; then
  command -v go >/dev/null 2>&1 || { echo "go is required but not installed."; exit 1; }
  go mod download
else
  echo "No common dependency manifest detected. Add project-specific setup commands to init.sh."
fi

echo "Initialization complete."
EOF
chmod +x "$project_dir/init.sh"

write_file "$project_dir/AGENTS.md" <<'EOF'
# Codex Project Instructions

Use the Work Loop files in this repository for long-running tasks.

- Read `architecture.md`, `task.json`, and `progress.md` before implementation.
- Do not implement until `task.json` has `"approval": { "status": "approved" }` or the user approves the plan.
- Create missing Work Loop files proactively when starting a long task.
- Run `./init.sh` at the start of every coding session; it should install dependencies and start the dev server when applicable.
- Work on the first task with `"passes": false` whose `depends_on` tasks are already passing.
- Before new work, regression-check 1-2 already passing tasks.
- Complete the task's `steps`, satisfy `acceptance`, and pass `verification` before marking it as passed.
- Update `progress.md` with a concise handoff entry before stopping.
EOF

write_file "$project_dir/CLAUDE.md" <<'EOF'
# Claude Code Project Instructions

Use the Work Loop files in this repository for long-running tasks.

- Read `architecture.md`, `task.json`, and `progress.md` before implementation.
- Do not implement until `task.json` has `"approval": { "status": "approved" }` or the user approves the plan.
- Create missing Work Loop files proactively when starting a long task.
- Run `./init.sh` at the start of every coding session; it should install dependencies and start the dev server when applicable.
- Work on the first task with `"passes": false` whose `depends_on` tasks are already passing.
- Before new work, regression-check 1-2 already passing tasks.
- Complete the task's `steps`, satisfy `acceptance`, and pass `verification` before marking it as passed.
- Update `progress.md` with a concise handoff entry before stopping.
EOF

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$script_dir/run-automation.sh" ]; then
  if [ -e "$project_dir/run-automation.sh" ] && [ "$force" != "yes" ]; then
    echo "Skipped existing $project_dir/run-automation.sh"
  else
    cp "$script_dir/run-automation.sh" "$project_dir/run-automation.sh"
    chmod +x "$project_dir/run-automation.sh"
    echo "Wrote $project_dir/run-automation.sh"
  fi
fi

echo "Work Loop harness setup complete: $project_dir"
