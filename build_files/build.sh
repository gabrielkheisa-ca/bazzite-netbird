#!/usr/bin/env bash
set -euo pipefail

# 1. Remove obsolete packages (GNOME handles rounded corners natively)
dnf5 remove -y gnome-rounded-blur || true

# 2. Create NetBird yum repository configuration
cat <<'EOF' > /etc/yum.repos.d/netbird.repo
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# 3. Install standard repository packages normally (allowing scriptlets)
dnf5 install -y --nodocs \
    iotop-c \
    ncdu \
    rclone \
    htop \
    libvirt-daemon-kvm \
    libvirt-client \
    qemu-kvm \
    virt-install

# 4. Install NetBird packages with noscripts to prevent failure in container builds
# (NetBird's %post scriptlet fails because systemd is not running as PID 1)
dnf5 install -y --nodocs --setopt=tsflags=noscripts \
    netbird \
    netbird-ui

# 5. Install RustDesk and ensure desktop entry + binary integration
# Download the RPM locally
curl -Lo /tmp/rustdesk.rpm "https://github.com/rustdesk/rustdesk/releases/download/1.5.0/rustdesk-1.5.0-0.x86_64.rpm"

# Install RustDesk dependencies and the package with noscripts to avoid init crashes
dnf5 install -y --nodocs --setopt=tsflags=noscripts /tmp/rustdesk.rpm

# 6. Explicitly set up RustDesk binaries, desktop files, and icons
if [ -f /usr/share/rustdesk/rustdesk ] && [ ! -f /usr/bin/rustdesk ]; then
    ln -sf /usr/share/rustdesk/rustdesk /usr/bin/rustdesk
fi

# Ensure desktop entry is in standard applications path
if [ -f /usr/share/rustdesk/rustdesk.desktop ]; then
    install -Dm644 /usr/share/rustdesk/rustdesk.desktop /usr/share/applications/rustdesk.desktop
fi

# Link icons if placed in non-standard location
if [ -d /usr/share/rustdesk/icons ]; then
    cp -r /usr/share/rustdesk/icons/* /usr/share/icons/hicolor/ || true
fi

# Update desktop and icon databases
update-desktop-database -q /usr/share/applications || true
if [ -d /usr/share/icons/hicolor ]; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi

# 7. Create custom systemd presets to enable services on actual boot
mkdir -p /usr/lib/systemd/system-preset
cat <<'EOF' > /usr/lib/systemd/system-preset/99-custom-services.preset
enable netbird.service
enable libvirtd.service
enable rustdesk.service
EOF

# 8. Create systemd service files manually (bypassing failed package installers)
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

cat <<'EOF' > /usr/lib/systemd/system/rustdesk.service
[Unit]
Description=RustDesk Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/rustdesk --service
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 9. Define transient /var state via systemd-tmpfiles (prevents bootc lint warnings)
mkdir -p /usr/lib/tmpfiles.d
cat <<'EOF' > /usr/lib/tmpfiles.d/custom-build.conf
d /var/cache/libvirt 0711 root root - -
d /var/cache/libvirt/qemu 0750 root root - -
EOF

# 10. Clean up temporary build artifacts and package caches
dnf5 clean all
rm -rf \
    /tmp/rustdesk.rpm \
    /etc/yum.repos.d/netbird.repo \
    /var/cache/libdnf5/* \
    /var/lib/dnf/* \
    /var/log/dnf* \
    /run/dnf \
    /run/gluster \
    /tmp/* \
    /var/tmp/*