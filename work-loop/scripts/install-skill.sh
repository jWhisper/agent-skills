#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-skill.sh [--force] [--uninstall] [--target codex|claude|all] [--mode copy|symlink] [--project /path/to/project]

Install the work-loop skill for Codex and/or Claude Code.
Optionally initialize Work Loop files in a target project with --project.

Defaults:
  --target all
  --mode symlink

Environment overrides for tests:
  CODEX_SKILLS_DIR
  CLAUDE_SKILLS_DIR
USAGE
}

target="all"
mode="symlink"
force="no"
uninstall="no"
project_dir=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="yes"
      shift
      ;;
    --uninstall)
      uninstall="yes"
      shift
      ;;
    --target)
      target="${2:-}"
      shift 2
      ;;
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --project)
      project_dir="${2:-}"
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

case "$target" in
  codex|claude|all) ;;
  *)
    echo "Invalid --target: $target" >&2
    exit 2
    ;;
esac

case "$mode" in
  copy|symlink) ;;
  *)
    echo "Invalid --mode: $mode" >&2
    exit 2
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"

codex_skills_dir="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
claude_skills_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

install_one() {
  local root_dir="$1"
  local dest="$root_dir/work-loop"

  mkdir -p "$root_dir"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$force" != "yes" ]; then
      echo "Skipped existing $dest (use --force to replace)"
      return
    fi
    rm -rf "$dest"
  fi

  if [ "$mode" = "symlink" ]; then
    ln -s "$skill_dir" "$dest"
  else
    mkdir -p "$dest"
    tar -C "$skill_dir" -cf - . | tar -C "$dest" -xf -
  fi

  echo "Installed work-loop to $dest ($mode)"
}

uninstall_one() {
  local root_dir="$1"
  local dest="$root_dir/work-loop"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
    echo "Uninstalled work-loop from $dest"
  else
    echo "No work-loop install found at $dest"
  fi
}

if [ "$target" = "codex" ] || [ "$target" = "all" ]; then
  if [ "$uninstall" = "yes" ]; then
    uninstall_one "$codex_skills_dir"
  else
    install_one "$codex_skills_dir"
  fi
fi

if [ "$target" = "claude" ] || [ "$target" = "all" ]; then
  if [ "$uninstall" = "yes" ]; then
    uninstall_one "$claude_skills_dir"
  else
    install_one "$claude_skills_dir"
  fi
fi

if [ -n "$project_dir" ]; then
  if [ "$uninstall" = "yes" ]; then
    echo "--project is ignored when --uninstall is used" >&2
  else
    setup_args=()
    if [ "$force" = "yes" ]; then
      setup_args+=(--force)
    fi
    bash "$script_dir/setup-harness.sh" "${setup_args[@]}" "$project_dir"
  fi
fi
