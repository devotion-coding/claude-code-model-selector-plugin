#!/usr/bin/env bash
# show-scope-status.sh — displays current provider/model at each scope level
# Usage: show-scope-status.sh <project_path>

set -euo pipefail

# Resolve to absolute path
PROJECT_PATH="${1:-.}"
if command -v realpath &>/dev/null; then
  PROJECT_PATH="$(realpath "$PROJECT_PATH")"
elif [[ "$PROJECT_PATH" != /* ]]; then
  PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
fi
PROJECT_SETTINGS="$PROJECT_PATH/.claude/settings.local.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
PROFILES_FILE="$HOME/.claude/model-profiles.json"

# Resolve provider name from base_url by matching against profiles
resolve_provider() {
  local base_url="$1"
  if [[ -z "$base_url" || "$base_url" == "null" || ! -f "$PROFILES_FILE" ]]; then
    echo ""
    return
  fi
  local provider
  provider=$(jq -r --arg url "$base_url" '[.providers[] | select(.base_url == $url) | .name] | first // empty' "$PROFILES_FILE" 2>/dev/null || true)
  echo "$provider"
}

# Read project-level env
if [[ -f "$PROJECT_SETTINGS" ]]; then
  PROJ_MODEL=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$PROJECT_SETTINGS" 2>/dev/null || true)
  PROJ_BASE_URL=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$PROJECT_SETTINGS" 2>/dev/null || true)
  if [[ -n "$PROJ_MODEL" ]]; then
    PROJ_PROVIDER=$(resolve_provider "$PROJ_BASE_URL")
    if [[ -n "$PROJ_PROVIDER" ]]; then
      PROJ_DISPLAY="$PROJ_PROVIDER / $PROJ_MODEL"
    else
      PROJ_DISPLAY="$PROJ_MODEL"
    fi
  else
    PROJ_DISPLAY="(not set, inherits global)"
  fi
else
  PROJ_DISPLAY="(not set, inherits global)"
fi

# Read global-level env
if [[ -f "$GLOBAL_SETTINGS" ]]; then
  GLOB_MODEL=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$GLOBAL_SETTINGS" 2>/dev/null || true)
  GLOB_BASE_URL=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$GLOBAL_SETTINGS" 2>/dev/null || true)
  if [[ -n "$GLOB_MODEL" ]]; then
    GLOB_PROVIDER=$(resolve_provider "$GLOB_BASE_URL")
    if [[ -n "$GLOB_PROVIDER" ]]; then
      GLOB_DISPLAY="$GLOB_PROVIDER / $GLOB_MODEL"
    else
      GLOB_DISPLAY="$GLOB_MODEL"
    fi
  else
    GLOB_DISPLAY="(not set)"
  fi
else
  GLOB_DISPLAY="(not set)"
fi

echo "Current status:"
echo "  Project-level: $PROJ_DISPLAY"
echo "  Global-level:  $GLOB_DISPLAY"
