#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-skill.sh [--skill name] [--force] [--uninstall] [--target codex|claude|all] [--mode copy|symlink] [--project /path/to/project]

Install skills from this repository for Codex and/or Claude Code.
By default, installs every first-level directory that contains SKILL.md.

Examples:
  bash install-skill.sh --skill gold-miner
  bash install-skill.sh --skill work-loop --project /path/to/project
  bash install-skill.sh --target codex --mode copy

Options:
  --skill name       Install or uninstall only one skill directory.
  --project path     Initialize Work Loop files in a project. Only applies to work-loop.

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
skill_name=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skill)
      skill_name="${2:-}"
      shift 2
      ;;
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

codex_skills_dir="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
claude_skills_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

discover_skills() {
  local dir

  for dir in "$script_dir"/*; do
    if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
      basename "$dir"
    fi
  done | sort
}

resolve_skills() {
  if [ -n "$skill_name" ]; then
    if [ ! -f "$script_dir/$skill_name/SKILL.md" ]; then
      echo "Skill not found: $skill_name" >&2
      echo "Available skills:" >&2
      discover_skills >&2
      return 2
    fi
    printf '%s\n' "$skill_name"
    return
  fi

  discover_skills
}

install_one() {
  local root_dir="$1"
  local name="$2"
  local source_dir="$3"
  local dest="$root_dir/$name"

  mkdir -p "$root_dir"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$force" != "yes" ]; then
      echo "Skipped existing $dest (use --force to replace)"
      return
    fi
    rm -rf "$dest"
  fi

  if [ "$mode" = "symlink" ]; then
    ln -s "$source_dir" "$dest"
  else
    mkdir -p "$dest"
    tar -C "$source_dir" -cf - . | tar -C "$dest" -xf -
  fi

  echo "Installed $name to $dest ($mode)"
}

uninstall_one() {
  local root_dir="$1"
  local name="$2"
  local dest="$root_dir/$name"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
    echo "Uninstalled $name from $dest"
  else
    echo "No $name install found at $dest"
  fi
}

resolved_skills="$(resolve_skills)" || exit 2

skills=()
while IFS= read -r name; do
  if [ -n "$name" ]; then
    skills+=("$name")
  fi
done <<< "$resolved_skills"

if [ "${#skills[@]}" -eq 0 ]; then
  echo "No skills found under $script_dir" >&2
  exit 2
fi

if [ -n "$project_dir" ]; then
  project_supported="no"
  for name in "${skills[@]}"; do
    if [ "$name" = "work-loop" ]; then
      project_supported="yes"
      break
    fi
  done

  if [ "$project_supported" != "yes" ]; then
    echo "--project only applies to work-loop" >&2
    exit 2
  fi
fi

for name in "${skills[@]}"; do
  source_dir="$script_dir/$name"

  if [ "$target" = "codex" ] || [ "$target" = "all" ]; then
    if [ "$uninstall" = "yes" ]; then
      uninstall_one "$codex_skills_dir" "$name"
    else
      install_one "$codex_skills_dir" "$name" "$source_dir"
    fi
  fi

  if [ "$target" = "claude" ] || [ "$target" = "all" ]; then
    if [ "$uninstall" = "yes" ]; then
      uninstall_one "$claude_skills_dir" "$name"
    else
      install_one "$claude_skills_dir" "$name" "$source_dir"
    fi
  fi
done

if [ -n "$project_dir" ]; then
  if [ "$uninstall" = "yes" ]; then
    echo "--project is ignored when --uninstall is used" >&2
  else
    setup_args=()
    if [ "$force" = "yes" ]; then
      setup_args+=(--force)
    fi
    bash "$script_dir/work-loop/scripts/setup-harness.sh" "${setup_args[@]}" "$project_dir"
  fi
fi
