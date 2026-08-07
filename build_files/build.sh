#!/usr/bin/env bash

set -euo pipefail

# 1. Create NetBird yum repository directly
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird without running RPM post-install scriptlets (bypasses systemd start error)
dnf5 install -y --setopt=tsflags=noscripts netbird

# 3. Enable the NetBird systemd service for boot time
systemctl enable netbird.service