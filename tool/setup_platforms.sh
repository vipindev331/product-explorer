#!/usr/bin/env bash
# Generates the Android/iOS host projects (if missing) and adds the INTERNET
# permission Android needs for release builds. Safe to run more than once:
# `flutter create` never overwrites existing files without --overwrite.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --project-name product_explorer --org com.example --platforms=android,ios

MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.INTERNET" />#' "$MANIFEST"
  echo "Added INTERNET permission to $MANIFEST"
fi

flutter pub get
echo "Platform folders ready. Run: flutter run"
