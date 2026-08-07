#!/usr/bin/env bash

set -euo pipefail

# 1. Create NetBird yum repository directly (Official NetBird config)
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird (and netbird-ui for Bazzite GNOME app integration)
# We do standard dnf5 install so RPM places all unit files in /usr/lib/systemd/system/
dnf5 install -y netbird netbird-ui gtk4 webkitgtk6.0 xdg-utils || dnf5 install -y netbird

# 3. Enable NetBird service natively for system boot
systemctl enable netbird.service