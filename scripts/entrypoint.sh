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

# Enable x86_64 binary support on arm64 hosts (e.g. OrbStack on Apple Silicon).
# JetBrains IDE backends are x86_64-only and need the amd64 dynamic linker.
if [ "$(uname -m)" = "aarch64" ] && [ ! -f /lib64/ld-linux-x86-64.so.2 ]; then
  echo "arm64 host detected — installing x86_64 emulation support..."
  dpkg --add-architecture amd64
  apt-get update -qq
  apt-get install -y -qq libc6:amd64 qemu-user-static binfmt-support 2>/dev/null || true
fi

locale-gen en_US.UTF-8 || true

${init_script}
