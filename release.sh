#!/bin/zsh
# Builds BusStop.app, tags the version and publishes it as a GitHub Release.
# Usage: ./release.sh 1.0.0
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${1:?Usage: ./release.sh <version>, e.g. 1.0.0}"
TAG="v$VERSION"
ZIP="dist/BusStop-$VERSION.zip"

[[ -z "$(git status --porcelain)" ]] || { echo "Working tree not clean; commit first." >&2; exit 1; }
! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "Tag $TAG already exists." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Not logged in to GitHub; run: gh auth login" >&2; exit 1; }

plutil -replace CFBundleShortVersionString -string "$VERSION" Resources/Info.plist
plutil -replace CFBundleVersion -string "$(( $(git rev-list --count HEAD) + 1 ))" Resources/Info.plist

./build-app.sh
[[ "$(lipo -archs BusStop.app/Contents/MacOS/BusStop)" == *arm64* && \
   "$(lipo -archs BusStop.app/Contents/MacOS/BusStop)" == *x86_64* ]] || { echo "Not a universal binary." >&2; exit 1; }
codesign --verify --deep --strict BusStop.app

mkdir -p dist
rm -f "$ZIP"
ditto -c -k --keepParent BusStop.app "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

git add Resources/Info.plist
git commit -q -m "Release $TAG"
git tag "$TAG"
git push -q origin HEAD "$TAG"

gh release create "$TAG" "$ZIP" --title "Bus Stop $VERSION" --notes "$(cat <<EOF
## Install

1. Download **BusStop-$VERSION.zip** below and double-click it to unzip.
2. Drag **BusStop.app** into your **Applications** folder.
3. Double-click it. macOS will say *"Apple could not verify…"*. Click **Done**.
4. Open **System Settings → Privacy & Security**, scroll down, click **Open Anyway** next to the BusStop message, and confirm.

You only need to do steps 3–4 once. The warning appears because the app isn't notarised by Apple; the full source is in this repository.

Requires macOS 13 or later. Runs natively on Apple Silicon and Intel Macs.

SHA-256: \`$SHA\`
EOF
)"

echo "Released $TAG: $(gh release view "$TAG" --json url -q .url)"
