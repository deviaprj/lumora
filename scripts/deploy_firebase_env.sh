#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/deploy_firebase_env.sh staging
#   scripts/deploy_firebase_env.sh prod
#
# Optional:
#   Put values in .env.staging / .env.prod at repo root
#   or export env vars before running.

ENVIRONMENT="${1:-}"
if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: $0 <staging|prod>"
  exit 1
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Invalid environment: $ENVIRONMENT (expected staging or prod)"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.$ENVIRONMENT"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  echo "Loaded env file: $ENV_FILE"
else
  echo "Env file not found ($ENV_FILE). Using current shell environment."
fi

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install: npm i -g firebase-tools"
  exit 1
fi

PROJECT_ID="${FIREBASE_PROJECT_ID:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo "FIREBASE_PROJECT_ID is required."
  exit 1
fi

push_secret() {
  local key="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    echo "Skipping empty secret: $key"
    return
  fi

  printf '%s' "$value" | firebase functions:secrets:set "$key" --project "$PROJECT_ID" --force >/dev/null
  echo "Secret pushed: $key"
}

echo "Project: $PROJECT_ID"
echo "Environment: $ENVIRONMENT"

echo "Pushing Firebase Functions secrets..."
push_secret "REVENUECAT_WEBHOOK_SECRET" "${REVENUECAT_WEBHOOK_SECRET:-}"
push_secret "RESEND_API_KEY" "${RESEND_API_KEY:-}"
push_secret "RESEND_FROM_EMAIL" "${RESEND_FROM_EMAIL:-}"
push_secret "EMAIL_VERIFICATION_PEPPER" "${EMAIL_VERIFICATION_PEPPER:-}"

echo "Deploying Firebase Functions..."
firebase deploy --only functions --project "$PROJECT_ID"

echo "Deployment done for $ENVIRONMENT ($PROJECT_ID)."
