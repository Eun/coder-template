#!/bin/bash
set -euo pipefail

pkg-install git

if [ -n "${GIT_AUTHOR_NAME:-}" ]; then
  git config --global user.name "$GIT_AUTHOR_NAME"
  echo "→ git user.name = $GIT_AUTHOR_NAME"
fi
if [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
  git config --global user.email "$GIT_AUTHOR_EMAIL"
  echo "→ git user.email = $GIT_AUTHOR_EMAIL"
fi

echo "✅ Git configured"
