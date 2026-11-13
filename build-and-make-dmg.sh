#!/bin/bash
# Builds MacBook Notch App and packages it into a .dmg installer.
#
# Requirements: Xcode (free from the Mac App Store) installed on your Mac.
# Run from Terminal:   bash build-and-make-dmg.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "Building MacBook Notch App..."
xcodebuild \
  -project MacBookNotchApp.xcodeproj \
  -target MacBookNotchApp \
  -configuration Release \
  SYMROOT="$(pwd)/build" \
  OBJROOT="$(pwd)/build/objs" \
  build

APP="build/Release/MacBookNotchApp.app"
DMG="MacBook Notch App.dmg"
STAGING="build/dmg-staging"

if [ ! -d "$APP" ]; then
  echo "Build did not produce $APP" >&2
  exit 1
fi

echo "Creating $DMG ..."
rm -f "$DMG"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create \
  -volname "MacBook Notch App" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG"
rm -rf "$STAGING"

echo ""
echo "Done. Install by opening the .dmg and dragging the app to Applications."
echo "Never needs an update — no license, no account, no network."
