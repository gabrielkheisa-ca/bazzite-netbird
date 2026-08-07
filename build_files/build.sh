#!/usr/bin/env bash

set -euo pipefail

# 1. Create NetBird repo configuration
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird & GUI
dnf5 install -y netbird netbird-ui || true

# 3. Explicitly install & enable the service so unit files exist
/usr/bin/netbird service install || true
systemctl enable netbird.service

# 4. Clean up DNF cache and temporary build files to pass bootc lint cleanly
dnf5 clean all
rm -rf /tmp/build_files /var/cache/libdnf5/* /var/log/dnf5.log