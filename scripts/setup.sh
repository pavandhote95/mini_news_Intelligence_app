#!/usr/bin/env bash
# One-time setup: generates Android/iOS runners, adds the INTERNET permission
# for release builds, creates env.json and fetches packages.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --org com.newsintel --project-name mini_news_intelligence --platforms=android,ios

MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  # Insert the permission right after the opening <manifest ...> tag.
  awk 'BEGIN{done=0} {print} !done && /<manifest/ && />/ {print "    <uses-permission android:name=\"android.permission.INTERNET\"/>"; done=1}' \
    "$MANIFEST" > "$MANIFEST.tmp" && mv "$MANIFEST.tmp" "$MANIFEST"
  echo "Added INTERNET permission to $MANIFEST"
fi

if [ ! -f env.json ]; then
  cp env.example.json env.json
  echo "Created env.json — paste your NewsAPI key into it."
fi

flutter pub get
echo
echo "Done. Run:  flutter run --dart-define-from-file=env.json"
