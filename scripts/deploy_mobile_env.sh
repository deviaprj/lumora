#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/deploy_mobile_env.sh staging
#   scripts/deploy_mobile_env.sh prod --build
#
# Purpose:
# - load mobile env vars (.env.staging / .env.prod)
# - verify native files exist before release
# - generate dart-define file for Flutter builds
# - optionally run a build smoke command

ENVIRONMENT="${1:-}"
RUN_BUILD="${2:-}"

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: $0 <staging|prod> [--build]"
  exit 1
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Invalid environment: $ENVIRONMENT (expected staging or prod)"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.$ENVIRONMENT"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  echo "Create it from .env.${ENVIRONMENT}.example"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

echo "Loaded: $ENV_FILE"

require_var() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "Missing required variable: $key"
    exit 1
  fi
}

echo "Checking required mobile variables..."
require_var FIREBASE_API_KEY
require_var FIREBASE_PROJECT_ID
require_var FIREBASE_MESSAGING_SENDER_ID
require_var FIREBASE_STORAGE_BUCKET
require_var FIREBASE_ANDROID_APP_ID
require_var FIREBASE_IOS_APP_ID
require_var FIREBASE_IOS_BUNDLE_ID
require_var ADMOB_ANDROID_APP_ID
require_var ADMOB_REWARDED_UNIT_ID
require_var REVENUECAT_ANDROID_KEY
require_var FACEBOOK_APP_ID
require_var FACEBOOK_CLIENT_TOKEN

echo "Checking native files..."
ANDROID_FIREBASE_FILE="$ROOT_DIR/android/app/google-services.json"
IOS_FIREBASE_FILE="$ROOT_DIR/ios/Runner/GoogleService-Info.plist"

[[ -f "$ANDROID_FIREBASE_FILE" ]] || { echo "Missing $ANDROID_FIREBASE_FILE"; exit 1; }
[[ -f "$IOS_FIREBASE_FILE" ]] || { echo "Missing $IOS_FIREBASE_FILE"; exit 1; }

echo "Generating iOS Facebook config..."
IOS_FB_CONFIG="$ROOT_DIR/ios/Flutter/FacebookConfig.xcconfig"
cat > "$IOS_FB_CONFIG" <<EOF
FACEBOOK_APP_ID=$FACEBOOK_APP_ID
FACEBOOK_CLIENT_TOKEN=$FACEBOOK_CLIENT_TOKEN
FACEBOOK_DISPLAY_NAME=${FACEBOOK_DISPLAY_NAME:-Lumora Mobile}
FACEBOOK_URL_SCHEME=${FACEBOOK_URL_SCHEME:-fb}
EOF

echo "Generating Flutter dart-define file..."
DEFINE_DIR="$ROOT_DIR/build"
mkdir -p "$DEFINE_DIR"
DEFINE_FILE="$DEFINE_DIR/dart_defines.$ENVIRONMENT.env"
cat > "$DEFINE_FILE" <<EOF
FIREBASE_API_KEY=$FIREBASE_API_KEY
FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID
FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
FIREBASE_ANDROID_APP_ID=$FIREBASE_ANDROID_APP_ID
FIREBASE_IOS_APP_ID=$FIREBASE_IOS_APP_ID
FIREBASE_IOS_BUNDLE_ID=$FIREBASE_IOS_BUNDLE_ID
ADMOB_ANDROID_APP_ID=$ADMOB_ANDROID_APP_ID
ADMOB_REWARDED_UNIT_ID=$ADMOB_REWARDED_UNIT_ID
REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY
FACEBOOK_APP_ID=$FACEBOOK_APP_ID
FACEBOOK_CLIENT_TOKEN=$FACEBOOK_CLIENT_TOKEN
STAGING_SMOKE_AUTH=$([[ "$ENVIRONMENT" == "staging" ]] && echo true || echo false)
EOF

echo "Preflight OK."
echo "Dart defines file: $DEFINE_FILE"
echo "Build command example:"
echo "  flutter build apk --debug --dart-define-from-file=$DEFINE_FILE"

if [[ "$RUN_BUILD" == "--build" ]]; then
  echo "Running build smoke command..."
  export PATH="/home/geekai/flutter/bin:$PATH"
  cd "$ROOT_DIR"
  flutter build apk --debug --dart-define-from-file="$DEFINE_FILE"
fi
