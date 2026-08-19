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

# 2. Install NetBird, NetBird UI, rclone, KVM Stack, and Plymouth dependencies
dnf5 install -y --setopt=tsflags=noscripts \
    netbird \
    netbird-ui \
    rclone \
    htop \
    libvirt-daemon-kvm \
    libvirt-client \
    qemu-kvm \
    virt-install \
    plymouth \
    plymouth-plugin-script \
    plymouth-plugin-label \
    dejavu-sans-fonts

# 3. Copy custom Plymouth theme into system themes folder
mkdir -p /usr/share/plymouth/themes
cp -r /tmp/build_files/plymouth-themes/win10 /usr/share/plymouth/themes/

# Verification check: Ensure theme copied successfully during image build
if [ ! -f "/usr/share/plymouth/themes/win10/win10.plymouth" ]; then
    echo "ERROR: /usr/share/plymouth/themes/win10/win10.plymouth was not found!" >&2
    exit 1
fi

# 4. Set win10 as the default Plymouth theme
plymouth-set-default-theme win10

# 5. Add splash kernel argument & early GPU driver loading for dracut
mkdir -p /usr/lib/bootc/kargs.d
cat <<'EOF' > /usr/lib/bootc/kargs.d/50-splash.conf
kargs = ["splash"]
EOF

mkdir -p /etc/dracut.conf.d
cat <<'EOF' > /etc/dracut.conf.d/plymouth-kms.conf
force_drivers+=" amdgpu i915 intel_i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF

# 6. Regenerate initramfs to bake theme files, drivers, and settings into the boot image
dracut --regenerate-all --force

# 7. Enable libvirtd and NetBird via systemd presets
mkdir -p /usr/lib/systemd/system-preset
cat <<'EOF' > /usr/lib/systemd/system-preset/50-custom-services.preset
enable netbird.service
enable libvirtd.service
EOF

# 8. Explicitly create the NetBird systemd unit file
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

# 9. Clean up cache & temp build files
dnf5 clean all
rm -rf /tmp/build_files /var/cache/libdnf5/* /var/log/dnf5.log