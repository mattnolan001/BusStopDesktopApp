#!/bin/zsh
# Builds BusStop.app in this directory. Usage: ./build-app.sh
# Uses swiftc directly so it works with just the Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p .build
swiftc -O -parse-as-library \
    -target "$(uname -m)-apple-macosx13.0" \
    -o .build/BusStop Sources/BusStop/*.swift

APP=BusStop.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/BusStop "$APP/Contents/MacOS/BusStop"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $PWD/$APP  (drag it to /Applications to install)"
