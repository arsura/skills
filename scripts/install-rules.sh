#!/usr/bin/env bash
set -euo pipefail

SCOPE="global"

usage() {
  cat <<EOF
Usage: install.sh [options]

Install rules for Cursor and Claude Code.

Options:
  --global        Install to user home (default)
  --project       Install to .cursor/rules/ and .claude/rules/ in current directory
  -h, --help      Show this help

Examples:
  ./scripts/install.sh              # global
  ./scripts/install.sh --project    # current repo
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) SCOPE="global"; shift ;;
    --project) SCOPE="project"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option $1" >&2; usage >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cursor_src="$REPO_ROOT/rules/cursor"
claude_src="$REPO_ROOT/rules/claude"

if [[ "$SCOPE" == "global" ]]; then
  cursor_dst="$HOME/.cursor/rules"
  claude_dst="$HOME/.claude/rules"
else
  cursor_dst="$(pwd)/.cursor/rules"
  claude_dst="$(pwd)/.claude/rules"
fi

mkdir -p "$cursor_dst" "$claude_dst"

count=0
for rule in "$cursor_src"/*.mdc; do
  [[ -f "$rule" ]] || continue
  cp "$rule" "$cursor_dst/"
  echo "  → Cursor: $(basename "$rule")"
  count=$((count + 1))
done

for rule in "$claude_src"/*.md; do
  [[ -f "$rule" ]] || continue
  cp "$rule" "$claude_dst/"
  echo "  → Claude: $(basename "$rule")"
  count=$((count + 1))
done

if [[ $count -eq 0 ]]; then
  echo "error: no rules found in $cursor_src or $claude_src" >&2
  exit 1
fi

echo "Installed $count rule(s) ($SCOPE scope)"
echo "  Cursor → $cursor_dst"
echo "  Claude → $claude_dst"
echo
echo "Restart Cursor / Claude Code if already open."
