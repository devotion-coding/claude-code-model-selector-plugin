#!/usr/bin/env bash
# switch-model.sh — writes provider/model config to settings file
# Usage: switch-model.sh <provider_name> <model_name> <scope:project|global> [project_path]

set -euo pipefail

PROFILES_FILE="$HOME/.claude/model-profiles.json"
PROVIDER_NAME="$1"
MODEL_NAME="$2"
SCOPE="$3"
PROJECT_PATH="${4:-.}"

# Validate inputs — auto-init profiles if missing
if [[ ! -f "$PROFILES_FILE" ]]; then
  echo "INFO: model-profiles.json not found. Initializing from current settings..."
  INIT_SCRIPT="$(dirname "$0")/init-profiles.sh"
  if [[ -f "$INIT_SCRIPT" ]]; then
    bash "$INIT_SCRIPT" "$PROJECT_PATH"
    if [[ ! -f "$PROFILES_FILE" ]]; then
      echo "ERROR: initialization failed — profiles file still not created"
      exit 1
    fi
    echo ""
  else
    echo "ERROR: model profiles not found at $PROFILES_FILE"
    echo "  init-profiles.sh not found at $INIT_SCRIPT"
    exit 1
  fi
fi

if [[ "$SCOPE" != "project" && "$SCOPE" != "global" ]]; then
  echo "ERROR: scope must be 'project' or 'global', got '$SCOPE'"
  exit 1
fi

# Lookup provider config and validate model in a single jq call
# Use \x01 (SOH) as delimiter to avoid collision with TAB in base_url/auth_token
READ_RESULT=$(jq -r --arg p "$PROVIDER_NAME" --arg m "$MODEL_NAME" '
  .providers[] | select(.name == $p)
  | { base_url: .base_url, auth_token: .auth_token, model_exists: (.models | index($m) != null) }
  | [.base_url, .auth_token, (.model_exists | tostring)] | join("")
' "$PROFILES_FILE")

if [[ -z "$READ_RESULT" ]]; then
  echo "ERROR: provider '$PROVIDER_NAME' not found in profiles"
  exit 1
fi

BASE_URL=$(echo "$READ_RESULT" | cut -d$'\x01' -f1)
AUTH_TOKEN=$(echo "$READ_RESULT" | cut -d$'\x01' -f2)
MODEL_EXISTS=$(echo "$READ_RESULT" | cut -d$'\x01' -f3)

if [[ "$MODEL_EXISTS" != "true" ]]; then
  echo "ERROR: model '$MODEL_NAME' not found under provider '$PROVIDER_NAME'"
  exit 1
fi

# Determine target settings file
if [[ "$SCOPE" == "global" ]]; then
  TARGET_FILE="$HOME/.claude/settings.json"
else
  TARGET_FILE="$PROJECT_PATH/.claude/settings.local.json"
fi

mkdir -p "$(dirname "$TARGET_FILE")"
if [[ ! -f "$TARGET_FILE" ]]; then
  echo '{}' > "$TARGET_FILE"
fi
chmod 600 "$TARGET_FILE"

# Security check: warn if target file might be tracked by git
if [[ "$SCOPE" == "project" ]]; then
  GIT_DIR="$PROJECT_PATH/.git"
  if [[ -d "$GIT_DIR" ]]; then
    REL_PATH=".claude/settings.local.json"
    # Check if file is tracked or would be tracked
    if git -C "$PROJECT_PATH" ls-files --error-unmatch "$REL_PATH" 2>/dev/null; then
      echo "WARN: $REL_PATH is tracked by git! Auth token may be committed."
      echo "  Consider adding '.claude/settings.local.json' to .gitignore"
    fi
  fi
fi

# Write env block, preserving other fields
TMP_FILE=$(mktemp)
trap 'rm -f "${TMP_FILE:-}"' EXIT

jq --arg model "$MODEL_NAME" \
   --arg base_url "$BASE_URL" \
   --arg auth_token "$AUTH_TOKEN" \
   '.env = {
      "ANTHROPIC_MODEL": $model,
      "ANTHROPIC_BASE_URL": $base_url,
      "ANTHROPIC_AUTH_TOKEN": $auth_token
    }' "$TARGET_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$TARGET_FILE"

chmod 600 "$TARGET_FILE"

echo "OK: switched to $PROVIDER_NAME/$MODEL_NAME ($SCOPE scope)"
echo "  Settings written to: $TARGET_FILE"
echo "  Restart Claude Code to apply the new configuration."
echo "  Tip: use /resume to restore your current session."
