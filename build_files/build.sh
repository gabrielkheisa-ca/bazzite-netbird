#!/usr/bin/env bash

set -euo pipefail

# 1. Add NetBird Yum Repo
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 2. Install NetBird without letting RPM scriptlets crash the build
dnf5 install -y --setopt=tsflags=noscripts netbird netbird-ui

# 3. Create a systemd preset to enable NetBird automatically on boot
mkdir -p /usr/lib/systemd/system-preset
echo "enable netbird.service" > /usr/lib/systemd/system-preset/50-netbird.preset

# 4. Enable service natively
systemctl enable netbird.service || true

# 5. Clean up DNF cache and temp files to satisfy bootc lint
dnf5 clean all
rm -rf /tmp/build_files /var/cache/libdnf5/* /var/log/dnf5.log /var/lib/dnf/repos/*