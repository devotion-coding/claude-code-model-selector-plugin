#!/usr/bin/env bash
# list-providers.sh — lists providers and models WITHOUT exposing auth_token or base_url
# Usage: list-providers.sh [--list|--models <provider_name>]

set -euo pipefail

PROFILES_FILE="$HOME/.claude/model-profiles.json"

# Auto-init profiles if missing
if [[ ! -f "$PROFILES_FILE" ]]; then
  INIT_SCRIPT="$(dirname "$0")/init-profiles.sh"
  if [[ -f "$INIT_SCRIPT" ]]; then
    # For --list and --models, we need project path. Use CWD as default.
    bash "$INIT_SCRIPT" "$(pwd)"
    if [[ ! -f "$PROFILES_FILE" ]]; then
      echo "ERROR: initialization failed — profiles file still not created"
      exit 1
    fi
  else
    echo "ERROR: model profiles not found at $PROFILES_FILE"
    echo "  init-profiles.sh not found at $INIT_SCRIPT"
    exit 1
  fi
fi

case "${1:---list}" in
  --list)
    COUNT=$(jq '.providers | length' "$PROFILES_FILE")
    if [[ "$COUNT" -eq 0 ]]; then
      echo "ERROR: no providers configured. Add providers to $PROFILES_FILE first."
      exit 1
    fi
    # Output: provider_name<TAB>model_count per line
    jq -r '.providers[] | [.name, (.models | length | tostring)] | join("\t")' "$PROFILES_FILE"
    ;;
  --models)
    PROVIDER="${2:-}"
    if [[ -z "$PROVIDER" ]]; then
      echo "ERROR: --models requires a provider name"
      exit 1
    fi
    # Check if provider exists
    PROVIDER_EXISTS=$(jq -r --arg p "$PROVIDER" '[.providers[] | select(.name == $p)] | length' "$PROFILES_FILE")
    if [[ "$PROVIDER_EXISTS" -eq 0 ]]; then
      echo "ERROR: provider '$PROVIDER' not found"
      exit 1
    fi
    # Output: one model name per line (may be empty if provider has no models)
    MODELS=$(jq -r --arg p "$PROVIDER" '.providers[] | select(.name == $p) | .models[]' "$PROFILES_FILE")
    if [[ -z "$MODELS" ]]; then
      echo "WARN: provider '$PROVIDER' has no models configured"
      exit 1
    fi
    echo "$MODELS"
    ;;
  *)
    echo "Usage: $0 [--list|--models <provider_name>]"
    exit 1
    ;;
esac
