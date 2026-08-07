#!/usr/bin/env bash

set -euo pipefail

# 1. Create NetBird repo
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird binary without running post-install scriptlets
dnf5 install -y --setopt=tsflags=noscripts netbird

# 3. Register the systemd unit file cleanly
netbird service install

# 4. Enable the service for system boot
systemctl enable netbird