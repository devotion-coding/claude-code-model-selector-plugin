#!/usr/bin/env bash
# list-providers.sh — lists providers and models WITHOUT exposing auth_token or base_url
# Usage: list-providers.sh [--list|--models <provider_name>]

set -euo pipefail

PROFILES_FILE="$HOME/.claude/model-profiles.json"

if [[ ! -f "$PROFILES_FILE" ]]; then
  echo "ERROR: model profiles not found at $PROFILES_FILE"
  exit 1
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
    # Output: one model name per line
    MODELS=$(jq -r --arg p "$PROVIDER" '.providers[] | select(.name == $p) | .models[]' "$PROFILES_FILE")
    if [[ -z "$MODELS" ]]; then
      echo "ERROR: provider '$PROVIDER' not found"
      exit 1
    fi
    echo "$MODELS"
    ;;
  *)
    echo "Usage: $0 [--list|--models <provider_name>]"
    exit 1
    ;;
esac
