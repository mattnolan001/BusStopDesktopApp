#!/bin/zsh
# Builds BusStop.app (universal: Apple Silicon + Intel) in this directory. Usage: ./build-app.sh
# Uses swiftc directly so it works with just the Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p .build
for arch in arm64 x86_64; do
    swiftc -O -parse-as-library \
        -target "$arch-apple-macosx13.0" \
        -o ".build/BusStop-$arch" Sources/BusStop/*.swift
done
lipo -create -output .build/BusStop .build/BusStop-arm64 .build/BusStop-x86_64

APP=BusStop.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/BusStop "$APP/Contents/MacOS/BusStop"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $PWD/$APP  (drag it to /Applications to install)"
