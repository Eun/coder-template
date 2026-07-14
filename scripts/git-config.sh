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

# Rewrite github.com HTTPS URLs to SSH so Go (and git) can fetch
# private modules using the workspace SSH key instead of requiring
# a token embedded in the URL.
git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "→ git url.insteadOf: https://github.com/ → git@github.com:"

echo "✅ Git configured"
