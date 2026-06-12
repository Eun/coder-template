#!/bin/bash
set -euo pipefail

pkg-install git jq openssh-client
mkdir -p ~/.ssh/config.d && chmod 700 ~/.ssh
touch ~/.ssh/config && chmod 600 ~/.ssh/config
if ! grep -q 'Include config.d/\*' ~/.ssh/config 2>/dev/null; then
  printf '%s\n\n' 'Include config.d/*' | cat - ~/.ssh/config > ~/.ssh/config.tmp
  mv ~/.ssh/config.tmp ~/.ssh/config
  chmod 600 ~/.ssh/config
fi
cat > ~/.ssh/config.d/verify_host_key << 'CONFIG'
Host *
    StrictHostKeyChecking accept-new
    VerifyHostKeyDNS yes
CONFIG
chmod 600 ~/.ssh/config.d/verify_host_key
