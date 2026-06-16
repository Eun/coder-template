#!/bin/bash
# Pre-download JetBrains IDE backend so Gateway doesn't have to.
# The backend is stored on the persistent volume (/home/coder) and
# symlinked to $HOME/.cache/JetBrains/RemoteDev/dist/ where Gateway
# expects to find it.
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

# Gateway looks for backends in $HOME/.cache/JetBrains/RemoteDev/dist/
# but $HOME is /root which is NOT on the persistent volume (/home/coder).
# Store the actual data on the persistent volume and symlink it.
PERSISTENT_DIR="/home/coder/.cache/JetBrains/RemoteDev/dist"
DIST_DIR="$HOME/.cache/JetBrains/RemoteDev/dist"

mkdir -p "$PERSISTENT_DIR"
mkdir -p "$(dirname "$DIST_DIR")"

# Symlink so Gateway finds the backend at the expected path
if [ ! -L "$DIST_DIR" ]; then
  rm -rf "$DIST_DIR"
  ln -sf "$PERSISTENT_DIR" "$DIST_DIR"
fi

# Check if the exact build is already cached
if [ -n "$(find "$PERSISTENT_DIR" -maxdepth 2 -name "product-info.json" 2>/dev/null)" ] && \
   find "$PERSISTENT_DIR" -maxdepth 2 -name "product-info.json" -exec grep -l "$IDE_BUILD" {} + >/dev/null 2>&1; then
  echo "IDE backend build $IDE_BUILD already cached, skipping download."
  exit 0
fi

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

# Get file size for progress reporting
FILE_SIZE=$(curl -fsSLI "$DOWNLOAD_URL" | grep -i content-length | tail -1 | tr -dc '0-9')
FILE_SIZE_MB=$(( FILE_SIZE / 1024 / 1024 ))

echo "Downloading $IDE_CODE (build $IDE_BUILD) — ${FILE_SIZE_MB} MB"
echo "  URL: $DOWNLOAD_URL"

TMP_FILE=$(mktemp /tmp/jetbrains-ide-XXXXXX.tar.gz)
trap 'rm -f "$TMP_FILE"' EXIT

# Download to temp file, printing progress every 5 seconds
curl -fSL -o "$TMP_FILE" "$DOWNLOAD_URL" &
CURL_PID=$!

while kill -0 "$CURL_PID" 2>/dev/null; do
  sleep 5
  if [ -f "$TMP_FILE" ]; then
    CURRENT=$(stat -c%s "$TMP_FILE" 2>/dev/null || stat -f%z "$TMP_FILE" 2>/dev/null || echo 0)
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

DOWNLOADED_MB=$(( $(stat -c%s "$TMP_FILE" 2>/dev/null || stat -f%z "$TMP_FILE" 2>/dev/null) / 1024 / 1024 ))
echo "Download complete (${DOWNLOADED_MB} MB). Extracting..."

tar xzf "$TMP_FILE" -C "$PERSISTENT_DIR"
rm -f "$TMP_FILE"

echo "IDE backend pre-downloaded to $PERSISTENT_DIR (symlinked from $DIST_DIR)"
