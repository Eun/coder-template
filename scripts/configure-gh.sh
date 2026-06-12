#!/bin/bash
set -euo pipefail

# Register hook to add GitHub CLI apt repo (runs only if gh not yet installed)
cat > /etc/pkg-install-hooks.d/gh << 'HOOK'
#!/bin/bash
set -euo pipefail
if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
  echo "📦 Adding GitHub CLI apt repository..."
  install -dm 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
fi
HOOK
chmod +x /etc/pkg-install-hooks.d/gh

pkg-install gh

if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "🔑 Authenticating GitHub CLI..."
  echo "$GITHUB_TOKEN" | gh auth login --with-token 2>&1
  gh auth setup-git 2>&1
  echo "✅ GitHub CLI authenticated"
fi
echo "✅ GitHub CLI configured"
