#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: glifocat
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/nanocoai/nanoclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# The branch helper deletes its destination before cloning. Refuse existing
# paths, including dangling symlinks and the previous helper's home directory.
if [[ -e /opt/nanoclaw || -L /opt/nanoclaw || -e /home/nanoclaw || -L /home/nanoclaw ]] || id -u nanoclaw &>/dev/null; then
  msg_error "Existing NanoClaw path or account found. Use a fresh container; this installer does not replace development checkouts."
  exit 1
fi

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3 \
  git \
  dbus-user-session \
  libpam-systemd \
  systemd-container
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="corepack" setup_nodejs

# NanoClaw runs natively; Docker is its required agent/OneCLI runtime.
setup_docker

fetch_and_deploy_gh_branch "nanoclaw" "nanocoai/nanoclaw" "main"

msg_info "Preparing Development Checkout"
$STD git -C /opt/nanoclaw config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
$STD git -C /opt/nanoclaw fetch --unshallow --tags origin
# A developer login keeps CLI credentials and the upstream user service in
# one home. Docker group access grants root-equivalent access inside the LXC.
$STD useradd --create-home --shell /bin/bash nanoclaw
$STD usermod -aG docker nanoclaw
$STD chown -R nanoclaw:nanoclaw /opt/nanoclaw
$STD loginctl enable-linger nanoclaw
msg_ok "Prepared Development Checkout"

msg_info "Installing Node Dependencies"
cd /opt/nanoclaw || exit 1
$STD runuser -u nanoclaw -- pnpm install --frozen-lockfile
msg_ok "Installed Node Dependencies"

msg_info "Building NanoClaw"
$STD runuser -u nanoclaw -- pnpm run build
msg_ok "Built NanoClaw"

motd_ssh
customize
cleanup_lxc
