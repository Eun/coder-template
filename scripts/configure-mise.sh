#!/bin/bash
set -euo pipefail

# Register hook to add mise apt repo (runs only if mise not yet installed)
cat > /etc/pkg-install-hooks.d/mise << 'HOOK'
#!/bin/bash
set -euo pipefail
if [ ! -f /etc/apt/sources.list.d/mise.list ]; then
  echo "📦 Adding mise apt repository..."
  install -dm 755 /etc/apt/keyrings
  curl -fsSL https://mise.jdx.dev/gpg-key.pub \
    | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" \
    | tee /etc/apt/sources.list.d/mise.list > /dev/null
fi
HOOK
chmod +x /etc/pkg-install-hooks.d/mise

pkg-install mise

# Trust all mise config files in the workspace directory
if [ -d "$PROJECT_DIR" ]; then
  mise trust --all -C "$PROJECT_DIR" 2>/dev/null || true
fi

echo "✅ mise configured"
