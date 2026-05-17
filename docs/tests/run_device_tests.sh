#!/bin/bash
# ---------------------------------------------------------------------------
# Script de tests automatisés sur device physique — Lumora
# Usage : ./run_device_tests.sh [device_id]
# ---------------------------------------------------------------------------

set -e

DEVICE_ID="${1:-6db039ac}"
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

echo "=== Lumora Device Tests ==="
echo "Device : $DEVICE_ID"
echo "Project: $PROJECT_DIR"
echo ""

# Vérifier que le device est connecté
echo "[1/5] Vérification du device..."
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo "ERREUR : Device $DEVICE_ID non connecté"
    exit 1
fi

# Compiler l'APK de test
echo "[2/5] Compilation de l'APK de test..."
cd "$PROJECT_DIR"
flutter build apk --debug

# Installer l'APK
echo "[3/5] Installation sur le device..."
adb -s "$DEVICE_ID" install -r "$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

# Capturer un screenshot avant les tests
echo "[4/5] Screenshot de référence..."
mkdir -p "$PROJECT_DIR/docs/tests/screenshots"
adb -s "$DEVICE_ID" exec-out screencap -p > "$PROJECT_DIR/docs/tests/screenshots/00_pre_test.png"

# Exécuter les tests d'intégration sur le device
echo "[5/5] Exécution des tests d'intégration..."
flutter test integration_test/full_device_test.dart --device-id "$DEVICE_ID"

echo ""
echo "=== Tests terminés avec succès ==="
