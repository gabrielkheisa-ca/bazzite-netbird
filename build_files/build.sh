#!/usr/bin/env bash

set -euo pipefail

# 1. Add NetBird Yum Repository
curl -fsSL https://pkgs.netbird.io/yum/repo.repo -o /etc/yum.repos.d/netbird.repo

# 2. Install NetBird via dnf5
dnf5 install -y netbird

# 3. Enable NetBird Systemd Service
systemctl enable netbird.service