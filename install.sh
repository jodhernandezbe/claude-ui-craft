#!/usr/bin/env bash
# Install (or refresh) the ui-craft kit in a project.
#
#   ./install.sh <project-root> [ui-dir]
#
# ui-dir is the UI package relative to the project root (default: frontend; "." for the root).
# Copies the skill, the /ui-check command and the reminder hook into <project>/.claude/, adds the
# hook to <project>/.claude/settings.json without removing existing hooks, and scaffolds
# <ui-dir>/DESIGN.md from the template only when none exists. Safe to run repeatedly.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-}"
UI_DIR="${2:-frontend}"

if [ -z "$PROJECT" ] || [ ! -d "$PROJECT" ]; then
  echo "usage: $0 <project-root> [ui-dir]" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd -P)"
UI_DIR="${UI_DIR%/}"

# The first argument is the PROJECT ROOT, not the UI folder. Passing the UI folder puts .claude
# in the wrong place and scaffolds a nested design document, so refuse it and print the command
# that would have worked.
ROOT="$(git -C "$PROJECT" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] && ROOT="$(cd "$ROOT" && pwd -P)"
if [ -n "$ROOT" ] && [ "$ROOT" != "$PROJECT" ]; then
  REL="${PROJECT#"$ROOT"/}"
  echo "error: '$PROJECT' is not the project root; it is '$REL' inside the repository at:" >&2
  echo "         $ROOT" >&2
  echo "       .claude/ belongs at the root, so Claude Code finds it from anywhere in the repo." >&2
  echo "       Did you mean:" >&2
  echo "         $0 \"$ROOT\" \"$REL\"" >&2
  exit 1
fi
if [ -z "$ROOT" ] && [ ! -d "$PROJECT/.git" ]; then
  echo "note: '$PROJECT' is not a git repository; installing there as the project root." >&2
fi

if [ "$UI_DIR" = "." ] || [ -z "$UI_DIR" ]; then
  UI_SRC="src"; DESIGN_DIR="$PROJECT"
else
  if [ ! -d "$PROJECT/$UI_DIR" ]; then
    echo "error: ui dir '$UI_DIR' does not exist under $PROJECT" >&2
    echo "       candidates found:" >&2
    find "$PROJECT" -maxdepth 3 -name package.json -not -path "*/node_modules/*" 2>/dev/null |
      sed "s|^$PROJECT/||; s|/package.json$||" | sed 's/^/         /' >&2
    echo "       or pass '.' when the UI is the whole repository." >&2
    exit 1
  fi
  UI_SRC="$UI_DIR/src"; DESIGN_DIR="$PROJECT/$UI_DIR"
fi
[ -d "$PROJECT/$UI_SRC" ] || UI_SRC="$UI_DIR"

say() { printf '  %s\n' "$*"; }

echo "ui-craft -> $PROJECT (ui dir: $UI_DIR, watched: $UI_SRC)"

# 1. Skill, command, hook script (overwritten: the kit is the source of truth).
mkdir -p "$PROJECT/.claude/skills" "$PROJECT/.claude/commands" "$PROJECT/.claude/hooks"
rm -rf "$PROJECT/.claude/skills/ui-craft"
cp -R "$KIT/skills/ui-craft" "$PROJECT/.claude/skills/ui-craft"
cp "$KIT/commands/ui-check.md" "$PROJECT/.claude/commands/ui-check.md"
cp "$KIT/commands/ui-audit.md" "$PROJECT/.claude/commands/ui-audit.md"
cp "$KIT/hooks/ui-reminder.sh" "$PROJECT/.claude/hooks/ui-reminder.sh"
chmod +x "$PROJECT/.claude/hooks/ui-reminder.sh"
say "skill    .claude/skills/ui-craft/"
say "commands .claude/commands/ui-check.md, ui-audit.md"
say "hook     .claude/hooks/ui-reminder.sh"

# 2. Hook registration in settings.json (append, never remove).
SETTINGS="$PROJECT/.claude/settings.json"
SNIPPET="$(sed "s#__UI_SRC__#$UI_SRC#" "$KIT/hooks/settings.hooks.json")"
if ! command -v jq >/dev/null 2>&1; then
  say "settings jq not found: add this to $SETTINGS by hand:"
  printf '%s\n' "$SNIPPET"
elif [ ! -f "$SETTINGS" ]; then
  printf '%s\n' "$SNIPPET" > "$SETTINGS"
  say "settings .claude/settings.json created with the PostToolUse hook"
elif jq -e '[.hooks.PostToolUse[]?.hooks[]?.command // "" | select(contains("ui-reminder.sh"))] | length > 0' "$SETTINGS" >/dev/null; then
  say "settings hook already registered (unchanged)"
else
  ENTRY="$(printf '%s' "$SNIPPET" | jq '.hooks.PostToolUse[0]')"
  TMP="$(mktemp)"
  jq --argjson entry "$ENTRY" '.hooks = (.hooks // {}) | .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [$entry])' "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
  say "settings hook appended to existing .claude/settings.json"
fi

# 3. DESIGN.md scaffold, only when absent.
mkdir -p "$DESIGN_DIR"
if [ -f "$DESIGN_DIR/DESIGN.md" ]; then
  say "design   $DESIGN_DIR/DESIGN.md exists (left untouched)"
else
  cp "$KIT/templates/DESIGN.template.md" "$DESIGN_DIR/DESIGN.md"
  say "design   $DESIGN_DIR/DESIGN.md scaffolded from the template"
fi

# 4. Token tests next to the UI source, only when absent (paths are adjusted by /ui-craft-init).
for test in designDoc.test.ts contrast.test.ts; do
  if [ -d "$PROJECT/$UI_SRC" ] && [ ! -f "$PROJECT/$UI_SRC/$test" ]; then
    cp "$KIT/templates/$test" "$PROJECT/$UI_SRC/$test"
    say "test     $UI_SRC/$test copied (check its path constants)"
  fi
done

cat <<EOF

Next steps (or run /ui-craft-init in Claude Code, which does them):
  1. Fill $DESIGN_DIR/DESIGN.md: in Claude Code say
     "Use the ui-craft skill to write DESIGN.md from the existing stylesheet and components."
  2. Add the two bullets from $KIT/templates/frontend-CLAUDE.section.md to $UI_DIR/CLAUDE.md.
  3. Check the path constants and token pairs in $UI_SRC/designDoc.test.ts and contrast.test.ts;
     for screenshots copy vitest.visual.config.ts and Example.visual.tsx and add "test:visual".
  4. Edit a component, see the reminder, run /ui-check <surface>.
EOF
