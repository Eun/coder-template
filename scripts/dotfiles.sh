#!/bin/bash
set -euo pipefail

echo "Applying dotfiles from ${DOTFILES_REPO}..."
coder dotfiles -y "${DOTFILES_REPO}" 2>&1 || true
echo "✅ Dotfiles applied"
