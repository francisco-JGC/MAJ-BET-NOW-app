#!/usr/bin/env bash
# Verifica que el APK release está firmado correctamente con el keystore
# de MajbetNow. Se corre después de `flutter build apk --release`.
#
# Uso:
#   ./scripts/verify-signature.sh
#
# Éxito → SHA-256 del certificado del APK coincide con el del keystore.
# Falla → APK sin firmar o firmado con otro keystore.

set -euo pipefail

APK="build/app/outputs/flutter-apk/app-release.apk"
KEYSTORE="$HOME/keystores/majbetnow/majbetnow-release.jks"
APKSIGNER="$HOME/Library/Android/sdk/build-tools/36.1.0/apksigner"

# Huella esperada del keystore de MajbetNow (verificada al crearlo).
EXPECTED_FINGERPRINT="BE:23:D8:D0:DC:16:CA:BF:F2:63:36:EA:1E:4D:3D:23:51:FA:E8:24:05:AF:41:67:0C:95:AF:66:1C:21:1B:F9"

if [ ! -f "$APK" ]; then
  echo "ERROR: no encuentro el APK en $APK"
  echo "Corré primero: flutter build apk --release"
  exit 1
fi

if [ ! -f "$KEYSTORE" ]; then
  echo "ERROR: no encuentro el keystore en $KEYSTORE"
  exit 1
fi

echo "==> Verificando firma del APK..."
"$APKSIGNER" verify --verbose "$APK"

echo ""
echo "==> Extrayendo huella SHA-256 del certificado del APK..."
APK_FINGERPRINT=$("$APKSIGNER" verify --print-certs "$APK" \
  | grep -i "SHA-256 digest" \
  | head -1 \
  | awk -F': ' '{print $2}' \
  | tr '[:lower:]' '[:upper:]' \
  | sed 's/../&:/g;s/:$//')

echo "APK:      $APK_FINGERPRINT"
echo "Esperado: $EXPECTED_FINGERPRINT"

if [ "$APK_FINGERPRINT" = "$EXPECTED_FINGERPRINT" ]; then
  echo ""
  echo "✅ OK — el APK está firmado con el keystore de MajbetNow."
else
  echo ""
  echo "❌ MISMATCH — el APK NO fue firmado con el keystore esperado."
  echo "   Revisá android/key.properties y el keystore en \$HOME/keystores/."
  exit 1
fi
