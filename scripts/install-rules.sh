#!/usr/bin/env bash
set -euo pipefail

SCOPE="global"
count=0
SELECTED=()

usage() {
  cat <<USAGE
Usage: install-rules.sh [options]

Install rules for Cursor and Claude Code.

Cursor rules are copied into .cursor/rules/ (Cursor loads *.mdc files from
there automatically). Claude Code has no such rules directory, so each rule
is instead appended into CLAUDE.md, wrapped in BEGIN/END RULE markers so
re-running this script updates the block in place instead of duplicating it.

With no --rule flag every available rule is installed.

Options:
  --global          Install to user home (default): ~/.cursor/rules/, ~/.claude/CLAUDE.md
  --project         Install to current directory: .cursor/rules/, ./CLAUDE.md
  --rule NAME       Install only this rule; repeatable, or comma-separated
  -l, --list        List available rules and exit
  -h, --help        Show this help

Examples:
  ./scripts/install-rules.sh                                  # all rules, global
  ./scripts/install-rules.sh --list                           # see what is available
  ./scripts/install-rules.sh --rule top-down-function-order   # just one
  ./scripts/install-rules.sh --rule a --rule b --project      # two rules, this repo
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cursor_src="$REPO_ROOT/rules/cursor"
claude_src="$REPO_ROOT/rules/claude"

# A rule is identified by its base name, which may exist as a Cursor .mdc, a
# Claude .md, or both. Collect the union so --rule and --list speak one
# vocabulary regardless of which editor happens to carry the rule.
available_rules() {
  {
    for rule in "$cursor_src"/*.mdc; do
      [[ -f "$rule" ]] && basename "$rule" .mdc
    done
    for rule in "$claude_src"/*.md; do
      [[ -f "$rule" ]] && basename "$rule" .md
    done
  } 2>/dev/null | sort -u
}

is_selected() {
  local name="$1"
  [[ ${#SELECTED[@]} -eq 0 ]] && return 0
  local want
  for want in "${SELECTED[@]}"; do
    [[ "$want" == "$name" ]] && return 0
  done
  return 1
}

# Cursor loads *.mdc files straight out of a rules/ directory, so this is a
# plain copy.
install_cursor_rules() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for rule in "$src"/*.mdc; do
    [[ -f "$rule" ]] || continue
    is_selected "$(basename "$rule" .mdc)" || continue
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
    is_selected "$rule_name" || continue
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
    --rule)
      [[ $# -ge 2 ]] || { echo "error: --rule needs a rule name" >&2; exit 1; }
      IFS=',' read -r -a names <<< "$2"
      SELECTED+=("${names[@]}")
      shift 2
      ;;
    --rule=*)
      IFS=',' read -r -a names <<< "${1#*=}"
      SELECTED+=("${names[@]}")
      shift
      ;;
    -l|--list)
      echo "Available rules:"
      available_rules | sed 's/^/  /'
      exit 0
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Fail on a typo'd rule name rather than silently installing nothing.
if [[ ${#SELECTED[@]} -gt 0 ]]; then
  known="$(available_rules)"
  for want in "${SELECTED[@]}"; do
    if ! grep -qxF "$want" <<< "$known"; then
      echo "error: unknown rule '$want'" >&2
      echo "Available rules:" >&2
      sed 's/^/  /' <<< "$known" >&2
      exit 1
    fi
  done
fi

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

echo "Installed $count rule file(s) ($SCOPE scope)"
echo "  Cursor → $cursor_dst"
echo "  Claude → $claude_md"
echo
echo "Restart Cursor / Claude Code if already open."
