#!/bin/bash
# Pre-download JetBrains IDE backend so Gateway doesn't have to.
#
# The remote-dev-worker that Gateway uses to detect installed IDEs does NOT
# follow symlinks, so we must extract directly to the dist dir it expects
# (/root/.cache/JetBrains/RemoteDev/dist/).
#
# Since /root is not on the persistent volume, the extracted IDE is
# lost on container restart. To avoid re-downloading every time, we cache
# the tarball on the persistent volume and re-extract from it on subsequent
# starts.
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

DIST_DIR="/root/.cache/JetBrains/RemoteDev/dist"
CACHE_DIR="/home/coder/.cache/JetBrains/RemoteDev"
CACHED_TARBALL="$CACHE_DIR/ide-${IDE_CODE}-${IDE_BUILD}.tar.gz"

mkdir -p "$DIST_DIR" "$CACHE_DIR"

# Extract tarball and rename the inner directory to the <CODE>-<BUILD> format
# that Gateway expects (e.g. IU-261.25134.95), then create the
# .expandSucceeded marker so Gateway recognises the installation.
extract_and_rename() {
  local tarball="$1"
  local tmp_extract="$DIST_DIR/.extract-tmp-$$"
  rm -rf "$tmp_extract"
  mkdir -p "$tmp_extract"
  tar xzf "$tarball" -C "$tmp_extract"

  # The tarball contains a single top-level dir (e.g. idea-IU-261.25134.95)
  local inner
  inner=$(ls -1 "$tmp_extract" | head -1)

  # Move to the name Gateway expects
  rm -rf "$IDE_DIR"
  mv "$tmp_extract/$inner" "$IDE_DIR"
  rm -rf "$tmp_extract"

  # Create the sentinel file Gateway checks
  touch "$IDE_DIR/.expandSucceeded"
  echo "IDE backend extracted to $IDE_DIR"
}

# Gateway expects the IDE at $DIST_DIR/<CODE>-<BUILD> (e.g. IU-261.25134.95)
# with a .expandSucceeded marker file inside it.
IDE_DIR="$DIST_DIR/${IDE_CODE}-${IDE_BUILD}"

# Check if the IDE is already correctly installed
if [ -f "$IDE_DIR/.expandSucceeded" ] && [ -f "$IDE_DIR/product-info.json" ]; then
  echo "IDE backend build $IDE_BUILD already installed in $IDE_DIR."
  exit 0
fi

# If we have a cached tarball, extract from it (fast — no download needed)
if [ -f "$CACHED_TARBALL" ]; then
  echo "Found cached tarball, extracting $IDE_CODE build $IDE_BUILD..."
  extract_and_rename "$CACHED_TARBALL"
  exit 0
fi

# Download the IDE
echo "Fetching release info for $IDE_CODE build $IDE_BUILD..."
RELEASE_JSON=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=${IDE_CODE}&build=${IDE_BUILD}")

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

# Get file size for progress reporting
FILE_SIZE=$(curl -fsSLI "$DOWNLOAD_URL" | grep -i content-length | tail -1 | tr -dc '0-9')
FILE_SIZE_MB=$(( FILE_SIZE / 1024 / 1024 ))

echo "Downloading $IDE_CODE (build $IDE_BUILD) — ${FILE_SIZE_MB} MB"
echo "  URL: $DOWNLOAD_URL"

# Download to the persistent cache location
curl -fSL -o "$CACHED_TARBALL.tmp" "$DOWNLOAD_URL" &
CURL_PID=$!

while kill -0 "$CURL_PID" 2>/dev/null; do
  sleep 5
  if [ -f "$CACHED_TARBALL.tmp" ]; then
    CURRENT=$(stat -c%s "$CACHED_TARBALL.tmp" 2>/dev/null || stat -f%z "$CACHED_TARBALL.tmp" 2>/dev/null || echo 0)
    CURRENT_MB=$(( CURRENT / 1024 / 1024 ))
    if [ "$FILE_SIZE" -gt 0 ]; then
      PCT=$(( CURRENT * 100 / FILE_SIZE ))
      echo "  Progress: ${CURRENT_MB} / ${FILE_SIZE_MB} MB (${PCT}%)"
    else
      echo "  Progress: ${CURRENT_MB} MB downloaded"
    fi
  fi
done

wait "$CURL_PID"
mv "$CACHED_TARBALL.tmp" "$CACHED_TARBALL"

DOWNLOADED_MB=$(( $(stat -c%s "$CACHED_TARBALL" 2>/dev/null || stat -f%z "$CACHED_TARBALL" 2>/dev/null) / 1024 / 1024 ))
echo "Download complete (${DOWNLOADED_MB} MB). Extracting..."

# Remove old cached tarballs for different builds
find "$CACHE_DIR" -maxdepth 1 -name "ide-${IDE_CODE}-*.tar.gz" ! -name "ide-${IDE_CODE}-${IDE_BUILD}.tar.gz" -delete 2>/dev/null || true

extract_and_rename "$CACHED_TARBALL"
echo "IDE backend installed to $IDE_DIR (tarball cached at $CACHED_TARBALL)"
