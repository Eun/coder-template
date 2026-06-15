#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

LOCK_DIR="/var/run/lock/install_dep.lock"
HOOKS_DIR="/etc/pkg-install-hooks.d"
mkdir -p "$(dirname "$LOCK_DIR")" "$HOOKS_DIR"

# ── Install from .deb file ──
if [ "${1:-}" = "--deb" ]; then
  shift
  for deb in "$@"; do
    if [ ! -f "$deb" ]; then
      echo "❌ File not found: $deb"
      exit 1
    fi
    # Extract the package name from the .deb and skip if already installed
    pkg_name=$(dpkg-deb --showformat='${Package}' --show "$deb")
    if dpkg -s "$pkg_name" >/dev/null 2>&1; then
      echo "✅ Already installed: $pkg_name"
      continue
    fi
    echo "📦 Installing from file: $deb ($pkg_name)"
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
      echo "⏳ Waiting for another install to finish..."
      sleep 2
    done
    trap 'rm -rf "$LOCK_DIR"' EXIT
    apt-get -o DPkg::Lock::Timeout=-1 install -y --no-install-recommends "$deb"
    rm -rf "$LOCK_DIR"
    trap - EXIT
    echo "✅ $pkg_name installed"
  done
  exit 0
fi

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
