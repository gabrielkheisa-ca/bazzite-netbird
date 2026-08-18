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

# 2. Install NetBird, NetBird UI, rclone, and KVM Virtualization Stack
dnf5 install -y --setopt=tsflags=noscripts \
    netbird \
    netbird-ui \
    rclone \
    htop \
    libvirt-daemon-kvm \
    libvirt-client \
    qemu-kvm \
    virt-install

# 3. Enable libvirtd and NetBird via systemd presets
mkdir -p /usr/lib/systemd/system-preset
cat <<'EOF' > /usr/lib/systemd/system-preset/50-custom-services.preset
enable netbird.service
enable libvirtd.service
EOF

# 4. Explicitly create the NetBird systemd unit file
cat <<'EOF' > /usr/lib/systemd/system/netbird.service
[Unit]
Description=NetBird daemon
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/netbird service run
Restart=always
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# 5. Clean up cache & temp build files
dnf5 clean all
rm -rf /tmp/build_files /var/cache/libdnf5/* /var/log/dnf5.log