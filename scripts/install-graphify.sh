#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Install the graphifyy CLI.
#
# Preference order:
#   1. uv    → `uv tool install graphifyy`
#   2. pipx  → `pipx install graphifyy`
#
# If neither tool manager is present, uv is installed via its official
# standalone installer; pipx is used as a fallback via pkg-install.
# ─────────────────────────────────────────────────────────────────────────────

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

install_with_uv() {
  echo "📦 Installing graphifyy via 'uv tool install'..."
  uv tool install graphifyy
}

install_with_pipx() {
  echo "📦 Installing graphifyy via 'pipx install'..."
  pipx install graphifyy
}

# ── 1. uv (preferred) ──
if command -v uv >/dev/null 2>&1; then
  install_with_uv
  echo "✅ graphifyy installed (uv)"
  exit 0
fi

# ── 2. pipx (already available) ──
if command -v pipx >/dev/null 2>&1; then
  install_with_pipx
  echo "✅ graphifyy installed (pipx)"
  exit 0
fi

# ── Neither present: try to bootstrap uv ──
echo "ℹ️  Neither uv nor pipx found — bootstrapping uv..."
if curl -fsSL https://astral.sh/uv/install.sh | sh; then
  export PATH="$HOME/.local/bin:$PATH"
  if command -v uv >/dev/null 2>&1; then
    install_with_uv
    echo "✅ graphifyy installed (uv)"
    exit 0
  fi
fi

# ── Fall back to installing pipx via pkg-install ──
echo "ℹ️  Falling back to pipx..."
pkg-install pipx
export PATH="$HOME/.local/bin:$PATH"
install_with_pipx
echo "✅ graphifyy installed (pipx)"
