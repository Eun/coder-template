#!/bin/bash
# Pre-download JetBrains IDE backend so Gateway doesn't have to.
# The backend is cached on the persistent volume under
# ~/.cache/JetBrains/RemoteDev/dist/ — subsequent starts are instant.
set -euo pipefail

IDE_CODE="${JETBRAINS_IDE_CODE:-}"
if [ -z "$IDE_CODE" ] || [ "$IDE_CODE" = "none" ]; then
  echo "No JetBrains IDE selected, skipping preload."
  exit 0
fi

DIST_DIR="$HOME/.cache/JetBrains/RemoteDev/dist"

# Check if an IDE backend is already cached
if [ -d "$DIST_DIR" ] && [ "$(ls -A "$DIST_DIR" 2>/dev/null)" ]; then
  echo "IDE backend already cached in $DIST_DIR, skipping download."
  exit 0
fi

mkdir -p "$DIST_DIR"

echo "Fetching latest release info for $IDE_CODE..."
RELEASE_JSON=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=${IDE_CODE}&type=release&latest=true")

# The API top-level key varies per product (e.g. IIU for IntelliJ, PCP for PyCharm).
# Extract the download link and build number from the first product in the response.
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r '[.[]][0][0].downloads.linux.link')
BUILD=$(echo "$RELEASE_JSON" | jq -r '[.[]][0][0].build')

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo "ERROR: Could not determine download URL for product code '$IDE_CODE'."
  exit 1
fi

echo "Downloading $IDE_CODE (build $BUILD) from $DOWNLOAD_URL ..."
curl -fSL "$DOWNLOAD_URL" | tar xz -C "$DIST_DIR"
echo "IDE backend pre-downloaded to $DIST_DIR"
