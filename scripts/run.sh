#!/usr/bin/env bash
# Genera el proyecto, compila para el simulador, instala y abre la app.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Instalando XcodeGen…"; brew install xcodegen; }
xcodegen generate --quiet

devices() { xcrun simctl list devices available | grep -E '^\s+iPhone'; }
UDID=$(devices | grep -m1 Booted | grep -oE '[0-9A-F-]{36}' || true)
if [ -z "$UDID" ]; then
  UDID=$(devices | head -1 | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot "$UDID" || true
fi
open -a Simulator

echo "Compilando…"
xcodebuild -project EventoApp.xcodeproj -scheme EventoApp \
  -destination "id=$UDID" -derivedDataPath build -quiet \
  CODE_SIGNING_ALLOWED=NO build

xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/EventoApp.app
xcrun simctl launch "$UDID" com.trescloud.evento
echo "Listo. Enlace profundo de prueba: xcrun simctl openurl booted evento://charla/d1-r1-1"
