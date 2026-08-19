#!/usr/bin/env bash
set -euo pipefail

SCOPE="global"
count=0

usage() {
  cat <<EOF
Usage: install.sh [options]

Install rules for Cursor and Claude Code.

Cursor rules are copied into .cursor/rules/ (Cursor loads *.mdc files from
there automatically). Claude Code has no such rules directory, so each rule
is instead appended into CLAUDE.md, wrapped in BEGIN/END RULE markers so
re-running this script updates the block in place instead of duplicating it.

Options:
  --global        Install to user home (default): ~/.cursor/rules/, ~/.claude/CLAUDE.md
  --project       Install to current directory: .cursor/rules/, ./CLAUDE.md
  -h, --help      Show this help

Examples:
  ./scripts/install.sh              # global
  ./scripts/install.sh --project    # current repo
EOF
}

# Cursor loads *.mdc files straight out of a rules/ directory, so this is a
# plain copy.
install_cursor_rules() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for rule in "$src"/*.mdc; do
    [[ -f "$rule" ]] || continue
    cp "$rule" "$dst/"
    echo "  → Cursor: $(basename "$rule")"
    count=$((count + 1))
  done
}

# Claude Code has no rules/ directory — it only auto-loads CLAUDE.md. Each
# rule is upserted as a marker-delimited block so re-running this stays
# idempotent instead of duplicating content on every install.
install_claude_rules() {
  local src="$1" claude_md="$2"
  touch "$claude_md"
  for rule in "$src"/*.md; do
    [[ -f "$rule" ]] || continue
    local rule_name begin_marker end_marker
    rule_name="$(basename "$rule" .md)"
    begin_marker="<!-- BEGIN RULE: $rule_name -->"
    end_marker="<!-- END RULE: $rule_name -->"

    if grep -qF "$begin_marker" "$claude_md"; then
      awk -v b="$begin_marker" -v e="$end_marker" '
        $0==b {skip=1}
        !skip {print}
        $0==e {skip=0}
      ' "$claude_md" | cat -s > "$claude_md.tmp"
      mv "$claude_md.tmp" "$claude_md"
    fi

    {
      echo ""
      echo "$begin_marker"
      sed '/^---$/,/^---$/d' "$rule"
      echo "$end_marker"
    } >> "$claude_md"
    echo "  → Claude (CLAUDE.md): $(basename "$rule")"
    count=$((count + 1))
  done
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
  claude_md="$HOME/.claude/CLAUDE.md"
else
  cursor_dst="$(pwd)/.cursor/rules"
  claude_md="$(pwd)/CLAUDE.md"
fi

install_cursor_rules "$cursor_src" "$cursor_dst"
install_claude_rules "$claude_src" "$claude_md"

if [[ $count -eq 0 ]]; then
  echo "error: no rules found in $cursor_src or $claude_src" >&2
  exit 1
fi

echo "Installed $count rule(s) ($SCOPE scope)"
echo "  Cursor → $cursor_dst"
echo "  Claude → $claude_md"
echo
echo "Restart Cursor / Claude Code if already open."
