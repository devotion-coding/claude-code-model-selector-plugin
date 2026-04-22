#!/usr/bin/env bash
# switch-model.sh — writes provider/model config to settings file
# Usage: switch-model.sh <provider_name> <model_name> <scope:project|global> [project_path]

set -euo pipefail

PROFILES_FILE="$HOME/.claude/model-profiles.json"
PROVIDER_NAME="$1"
MODEL_NAME="$2"
SCOPE="$3"
PROJECT_PATH="${4:-.}"

# Validate inputs
if [[ ! -f "$PROFILES_FILE" ]]; then
  echo "ERROR: model profiles not found at $PROFILES_FILE"
  exit 1
fi

if [[ "$SCOPE" != "project" && "$SCOPE" != "global" ]]; then
  echo "ERROR: scope must be 'project' or 'global', got '$SCOPE'"
  exit 1
fi

# Lookup provider in profiles
BASE_URL=$(jq -r --arg p "$PROVIDER_NAME" '.providers[] | select(.name == $p) | .base_url' "$PROFILES_FILE")
AUTH_TOKEN=$(jq -r --arg p "$PROVIDER_NAME" '.providers[] | select(.name == $p) | .auth_token' "$PROFILES_FILE")

if [[ -z "$BASE_URL" || "$BASE_URL" == "null" ]]; then
  echo "ERROR: provider '$PROVIDER_NAME' not found in profiles"
  exit 1
fi

# Validate model exists under this provider
MODEL_EXISTS=$(jq -r --arg p "$PROVIDER_NAME" --arg m "$MODEL_NAME" \
  '.providers[] | select(.name == $p) | .models | index($m) // empty' "$PROFILES_FILE")

if [[ -z "$MODEL_EXISTS" ]]; then
  echo "ERROR: model '$MODEL_NAME' not found under provider '$PROVIDER_NAME'"
  exit 1
fi

# Determine target settings file
if [[ "$SCOPE" == "global" ]]; then
  TARGET_FILE="$HOME/.claude/settings.json"
else
  TARGET_FILE="$PROJECT_PATH/.claude/settings.local.json"
  mkdir -p "$(dirname "$TARGET_FILE")"
  if [[ ! -f "$TARGET_FILE" ]]; then
    echo '{}' > "$TARGET_FILE"
  fi
fi

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "ERROR: settings file not found at $TARGET_FILE"
  exit 1
fi

# Write env block, preserving other fields
TMP_FILE=$(mktemp)
jq --arg model "$MODEL_NAME" \
   --arg base_url "$BASE_URL" \
   --arg auth_token "$AUTH_TOKEN" \
   '.env = {
      "ANTHROPIC_MODEL": $model,
      "ANTHROPIC_BASE_URL": $base_url,
      "ANTHROPIC_AUTH_TOKEN": $auth_token
    }' "$TARGET_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$TARGET_FILE"

echo "OK: switched to $PROVIDER_NAME/$MODEL_NAME ($SCOPE)"
echo "  ANTHROPIC_MODEL=$MODEL_NAME"
echo "  ANTHROPIC_BASE_URL=$BASE_URL"
echo "  Settings written to: $TARGET_FILE"
