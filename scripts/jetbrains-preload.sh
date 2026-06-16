#!/bin/bash
# Pre-download JetBrains IDE backend so Gateway doesn't have to.
# The backend is cached on the persistent volume under
# ~/.cache/JetBrains/RemoteDev/dist/ — subsequent starts are instant.
set -euo pipefail

# Ensure curl and jq are available
pkg-install curl jq

IDE_CODE="${JETBRAINS_IDE_CODE:-}"
IDE_BUILD="${JETBRAINS_IDE_BUILD:-}"

if [ -z "$IDE_CODE" ] || [ "$IDE_CODE" = "none" ]; then
  echo "No JetBrains IDE selected, skipping preload."
  exit 0
fi

if [ -z "$IDE_BUILD" ]; then
  echo "ERROR: JETBRAINS_IDE_BUILD is not set — cannot determine which version to download."
  exit 1
fi

DIST_DIR="$HOME/.cache/JetBrains/RemoteDev/dist"

# Check if the exact build is already cached
if [ -d "$DIST_DIR" ] && find "$DIST_DIR" -maxdepth 2 -name "product-info.json" -exec grep -l "$IDE_BUILD" {} + >/dev/null 2>&1; then
  echo "IDE backend build $IDE_BUILD already cached in $DIST_DIR, skipping download."
  exit 0
fi

mkdir -p "$DIST_DIR"

echo "Fetching release info for $IDE_CODE build $IDE_BUILD..."
RELEASE_JSON=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=${IDE_CODE}&build=${IDE_BUILD}")

# The API top-level key varies per product (e.g. IIU for IntelliJ, PCP for PyCharm).
# Extract the download link from the first product in the response.
# Pick the correct download for the host architecture
case "$(uname -m)" in
  aarch64) DOWNLOAD_KEY="linuxARM64" ;;
  *)       DOWNLOAD_KEY="linux" ;;
esac
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r "[.[]][0][0].downloads.${DOWNLOAD_KEY}.link")

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo "ERROR: Could not determine download URL for $IDE_CODE build $IDE_BUILD."
  exit 1
fi

echo "Downloading $IDE_CODE (build $IDE_BUILD) from $DOWNLOAD_URL ..."
curl -fSL "$DOWNLOAD_URL" | tar xz -C "$DIST_DIR"
echo "IDE backend pre-downloaded to $DIST_DIR"
