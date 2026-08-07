#!/usr/bin/env bash

set -euo pipefail

# 1. Create NetBird yum repository configuration
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird & NetBird UI
dnf5 install -y --setopt=tsflags=noscripts netbird netbird-ui

# 3. Create systemd preset so systemd enables NetBird on boot automatically
mkdir -p /usr/lib/systemd/system-preset
echo "enable netbird.service" > /usr/lib/systemd/system-preset/50-netbird.preset

# 4. Clean up cache & temp build files
dnf5 clean all
rm -rf /tmp/build_files /var/cache/libdnf5/* /var/log/dnf5.log