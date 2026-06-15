#!/bin/bash
set -euo pipefail

# Ensure dependencies are installed via pkg-install
pkg-install curl jq

# Install gh-web-auth via .deb from GitHub Releases
if ! command -v gh-web-auth >/dev/null 2>&1; then
  ARCH=$(dpkg --print-architecture)
  DEB_URL=$(curl -sfL https://api.github.com/repos/Eun/gh-web-auth/releases/latest \
    | jq -r ".assets[] | select(.name | endswith(\"linux_${ARCH}.deb\")) | .browser_download_url")
  if [ -z "$DEB_URL" ]; then
    echo "❌ No gh-web-auth .deb found for arch: $ARCH"
    exit 1
  fi
  curl -sfL -o /tmp/gh-web-auth.deb "$DEB_URL"
  pkg-install --deb /tmp/gh-web-auth.deb
  rm -f /tmp/gh-web-auth.deb
fi

# gh-web-auth reads config from env vars set by Terraform:
#   GH_WEB_AUTH_BASE_PATH      — frontend URL prefix for browser fetch calls
#   GH_WEB_AUTH_BACKEND_PREFIX — path prefix stripped by server (defaults to "/", correct for Coder)

echo "🔑 Starting gh-web-auth on port 18515 (base-path: ${GH_WEB_AUTH_BASE_PATH})..."
nohup gh-web-auth --listen-addr 0.0.0.0:18515 > /tmp/gh-web-auth.log 2>&1 &

echo "✅ gh-web-auth started in background (pid $!, log: /tmp/gh-web-auth.log)"
