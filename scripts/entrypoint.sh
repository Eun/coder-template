#!/bin/bash

# Create coder user if it doesn't exist
if ! id coder >/dev/null 2>&1; then
  useradd -m -s /bin/bash -d /home/coder coder
  echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder
  chmod 0440 /etc/sudoers.d/coder
fi

# Ensure ~/.local/bin is on PATH
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' /home/coder/.bashrc 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/coder/.bashrc

# Ensure home dir ownership
chown -R coder:coder /home/coder 2>/dev/null || true

# Create project directory
mkdir -p /home/coder/${workspace_name}
chown coder:coder /home/coder/${workspace_name}

# Deploy pkg-install helper from file
mkdir -p /etc/pkg-install-hooks.d
echo '${pkg_install_b64}' | base64 -d > /usr/local/bin/pkg-install
chmod +x /usr/local/bin/pkg-install

# Install base packages
pkg-install curl gnupg lsb-release unzip sudo ca-certificates git locales procps jq

locale-gen en_US.UTF-8 || true

${init_script}
