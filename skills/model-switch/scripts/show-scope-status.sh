#!/usr/bin/env bash
# show-scope-status.sh — displays current provider/model at each scope level
# Usage: show-scope-status.sh <project_path>

set -euo pipefail

PROJECT_PATH="${1:-.}"
PROJECT_SETTINGS="$PROJECT_PATH/.claude/settings.local.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"

# Read project-level env
if [[ -f "$PROJECT_SETTINGS" ]]; then
  PROJ_MODEL=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$PROJECT_SETTINGS" 2>/dev/null || true)
  if [[ -n "$PROJ_MODEL" ]]; then
    PROJ_DISPLAY="$PROJ_MODEL"
  else
    PROJ_DISPLAY="(not set, inherits global)"
  fi
else
  PROJ_DISPLAY="(not set, inherits global)"
fi

# Read global-level env
if [[ -f "$GLOBAL_SETTINGS" ]]; then
  GLOB_MODEL=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$GLOBAL_SETTINGS" 2>/dev/null || true)
  if [[ -n "$GLOB_MODEL" ]]; then
    GLOB_DISPLAY="$GLOB_MODEL"
  else
    GLOB_DISPLAY="(not set)"
  fi
else
  GLOB_DISPLAY="(not set)"
fi

echo "Current status:"
echo "  Project-level: $PROJ_DISPLAY"
echo "  Global-level:  $GLOB_DISPLAY"
