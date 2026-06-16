#!/bin/bash
set -euo pipefail

pkg-install git

# Add workspace directory to git safe.directory
if [ -n "${WORKSPACE_BASE:-}" ]; then
  git config --global --add safe.directory "$WORKSPACE_BASE"
  echo "→ git safe.directory += $WORKSPACE_BASE"
fi

if [ -n "${GIT_AUTHOR_NAME:-}" ]; then
  git config --global user.name "$GIT_AUTHOR_NAME"
  echo "→ git user.name = $GIT_AUTHOR_NAME"
fi
if [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
  git config --global user.email "$GIT_AUTHOR_EMAIL"
  echo "→ git user.email = $GIT_AUTHOR_EMAIL"
fi

echo "✅ Git configured"
