#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Install the graphifyy CLI via pipx.
# ─────────────────────────────────────────────────────────────────────────────

export PATH="$HOME/.local/bin:$PATH"

# Ensure pipx is available (installed via pkg-install if missing).
if ! command -v pipx >/dev/null 2>&1; then
  echo "ℹ️  pipx not found — installing via pkg-install..."
  pkg-install pipx
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "📦 Installing graphifyy via 'pipx install'..."
pipx install graphifyy

echo "✅ graphifyy installed (pipx)"
