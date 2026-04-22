#!/usr/bin/env bash
# init-profiles.sh — initializes ~/.claude/model-profiles.json from current settings
# Usage: init-profiles.sh [project_path]
#
# Extracts env config from global and project-level settings files,
# creates an initial model-profiles.json with detected providers.

set -euo pipefail

PROJECT_PATH="${1:-.}"
if command -v realpath &>/dev/null; then
  PROJECT_PATH="$(realpath "$PROJECT_PATH")"
elif [[ "$PROJECT_PATH" != /* ]]; then
  PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
fi

PROFILES_FILE="$HOME/.claude/model-profiles.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
PROJECT_SETTINGS="$PROJECT_PATH/.claude/settings.local.json"

if [[ -f "$PROFILES_FILE" ]]; then
  echo "ERROR: model-profiles.json already exists at $PROFILES_FILE"
  exit 1
fi

# Helper: derive provider name from base_url hostname
derive_provider_name() {
  local base_url="$1"
  # Extract hostname, then take the most meaningful subdomain part
  # e.g. https://coding.dashscope.aliyuncs.com/apps/anthropic → coding
  # e.g. https://api.openai.com/v1 → api
  # e.g. https://localhost:8080 → localhost
  local host
  host=$(echo "$base_url" | sed -E 's|^https?://||' | sed -E 's|[:/].*||')
  # Split by dots, take the first non-empty segment that's not a common prefix
  local first_part
  first_part=$(echo "$host" | cut -d. -f1)
  # If first part is too generic (www, api), use the second part instead
  if [[ "$first_part" == "www" || "$first_part" == "api" || -z "$first_part" ]]; then
    first_part=$(echo "$host" | cut -d. -f2)
  fi
  # Sanitize: replace non-alphanumeric chars with underscores
  echo "$first_part" | tr -c 'a-zA-Z0-9' '_' | sed 's/_*$//'
}

# Collect unique provider entries from settings files
# Format: "base_url|auth_token|model" per line, deduplicated by provider_name+model
COLLECTED=""

collect_from_settings() {
  local settings_file="$1"
  local source_label="$2"

  if [[ ! -f "$settings_file" ]]; then
    echo "$source_label: file not found, skipping"
    return
  fi

  local base_url model auth_token
  base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$settings_file" 2>/dev/null || true)
  model=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$settings_file" 2>/dev/null || true)
  auth_token=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$settings_file" 2>/dev/null || true)

  if [[ -z "$base_url" || "$base_url" == "null" ]]; then
    echo "$source_label: no env.ANTHROPIC_BASE_URL found, skipping"
    return
  fi

  if [[ -z "$model" || "$model" == "null" ]]; then
    echo "$source_label: no env.ANTHROPIC_MODEL found, skipping"
    return
  fi

  local provider_name
  provider_name=$(derive_provider_name "$base_url")
  echo "$source_label: detected provider '$provider_name' ($model)"

  # Check if this provider+model combo already collected
  if echo "$COLLECTED" | grep -qF "${provider_name}|${model}"; then
    echo "$source_label: provider '$provider_name' with model '$model' already collected, skipping duplicate"
    return
  fi

  # Store as: provider_name|base_url|auth_token|model
  COLLECTED="${COLLECTED}${provider_name}|${base_url}|${auth_token}|${model}
"
}

collect_from_settings "$GLOBAL_SETTINGS" "Global settings"
collect_from_settings "$PROJECT_SETTINGS" "Project settings"

if [[ -z "$COLLECTED" ]]; then
  echo "ERROR: no provider configuration found in settings files."
  echo "  Checked: $GLOBAL_SETTINGS"
  echo "  Checked: $PROJECT_SETTINGS"
  echo "  Please create $PROFILES_FILE manually with provider details."
  exit 1
fi

# Build JSON using jq
# Start with empty providers array
JSON='{"providers":[]}'

# Process collected entries line by line
while IFS='|' read -r provider_name base_url auth_token model; do
  [[ -z "$provider_name" ]] && continue

  # Check if this provider already exists in JSON
  provider_exists=$(echo "$JSON" | jq --arg name "$provider_name" '[.providers[] | select(.name == $name)] | length')

  if [[ "$provider_exists" -eq 0 ]]; then
    # New provider: add entry with single model
    JSON=$(echo "$JSON" | jq \
      --arg name "$provider_name" \
      --arg base_url "$base_url" \
      --arg auth_token "$auth_token" \
      --arg model "$model" \
      '.providers += [{
        "name": $name,
        "base_url": $base_url,
        "auth_token": $auth_token,
        "models": [$model]
      }]')
  else
    # Provider exists: add model if not already in array
    JSON=$(echo "$JSON" | jq \
      --arg name "$provider_name" \
      --arg model "$model" \
      '.providers = [.providers[] |
        if .name == $name then
          if (.models | index($model)) then .
          else .models += [$model]
          end
        else .
        end
      ]')
  fi
done <<< "$COLLECTED"

# Write profiles file
mkdir -p "$(dirname "$PROFILES_FILE")"
echo "$JSON" | jq '.' > "$PROFILES_FILE"
chmod 600 "$PROFILES_FILE"

# Count providers
provider_count=$(echo "$JSON" | jq '.providers | length')

echo "OK: initialized model-profiles.json with $provider_count provider(s)"
echo "$JSON" | jq -r '.providers[] | "  - \(.name) (models: \(.models | join(", ")))"'
echo "  File: $PROFILES_FILE"
