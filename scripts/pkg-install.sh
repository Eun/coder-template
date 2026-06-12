#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

LOCK_DIR="/var/run/lock/install_dep.lock"
HOOKS_DIR="/etc/pkg-install-hooks.d"
mkdir -p "$(dirname "$LOCK_DIR")" "$HOOKS_DIR"

# ── Handle apt packages ──
missing=()
for pkg in "$@"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "📦 Installing apt packages: ${missing[*]}"

  # Acquire atomic lock (mkdir is atomic on Linux)
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    echo "⏳ Waiting for another install to finish..."
    sleep 2
  done
  trap 'rm -rf "$LOCK_DIR"' EXIT

  # Run pre-install hooks (e.g. add apt repos) for missing packages
  needs_update=false
  for pkg in "${missing[@]}"; do
    if [ -x "$HOOKS_DIR/$pkg" ]; then
      echo "🔧 Running hook for $pkg..."
      "$HOOKS_DIR/$pkg"
      needs_update=true
    fi
  done

  # Only run apt-get update if a hook added a repo, or no update ran recently
  if [ "$needs_update" = true ] || [ ! -f /var/cache/apt/pkgcache.bin ] || \
     [ "$(find /var/cache/apt/pkgcache.bin -mmin +5 2>/dev/null)" ]; then
    apt-get -o DPkg::Lock::Timeout=-1 update -qq
  fi

  for pkg in "${missing[@]}"; do
    apt-get -o DPkg::Lock::Timeout=-1 install -y --no-install-recommends "$pkg"
  done

  rm -rf "$LOCK_DIR"
  trap - EXIT
else
  echo "✅ All apt packages already installed: $*"
fi
