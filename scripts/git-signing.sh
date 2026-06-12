#!/bin/bash
set -euo pipefail

pkg-install git jq curl openssh-client

mkdir -p $HOME/.ssh/config.d && chmod 700 $HOME/.ssh
touch "$HOME/.ssh/config" && chmod 600 "$HOME/.ssh/config"
if ! grep -q 'Include config.d/\*' "$HOME/.ssh/config" 2>/dev/null; then
  printf '%s\n\n' 'Include config.d/*' | cat - "$HOME/.ssh/config" > "$HOME/.ssh/config.tmp"
  mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
fi

SIGNING_KEY="$HOME/.ssh/coder_signing"

if [ -n "${CODER_AGENT_TOKEN:-}" ] && [ -n "${CODER_AGENT_URL:-}" ]; then
  echo "Fetching Coder git SSH key from agent API..."
  GITSSH_RESPONSE=$(curl -sf \
    -H "Coder-Session-Token: $CODER_AGENT_TOKEN" \
    "${CODER_AGENT_URL}/api/v2/workspaceagents/me/gitsshkey" 2>/dev/null || true)
  if [ -n "$GITSSH_RESPONSE" ]; then
    echo "$GITSSH_RESPONSE" | jq -r '.private_key' > "$SIGNING_KEY"
    echo "$GITSSH_RESPONSE" | jq -r '.public_key' > "$SIGNING_KEY.pub"
    chmod 600 "$SIGNING_KEY"
    chmod 644 "$SIGNING_KEY.pub"
  fi
fi

if [ -f "$SIGNING_KEY" ]; then
  git config --global gpg.format ssh
  git config --global user.signingkey "$SIGNING_KEY"
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true

  GIT_EMAIL=$(git config --global user.email || true)
  if [ -n "$GIT_EMAIL" ] && [ -f "$SIGNING_KEY.pub" ]; then
    echo "$GIT_EMAIL $(cat "$SIGNING_KEY.pub")" > "$HOME/.ssh/allowed_signers"
    git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
  fi

  mkdir -p "$HOME/.ssh/config.d"
  cat > "$HOME/.ssh/config.d/commit_signing" << SSH_SIGNING
Host *
    IdentityFile $SIGNING_KEY
SSH_SIGNING
  chmod 600 "$HOME/.ssh/config.d/commit_signing"
  echo "✅ Git commit signing enabled (SSH)"
fi
