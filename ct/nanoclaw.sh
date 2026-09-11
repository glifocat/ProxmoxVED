#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: glifocat
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/nanocoai/nanoclaw

APP="NanoClaw"
var_tags="${var_tags:-ai;agent;development}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/nanoclaw && ! -d /home/nanoclaw/nanoclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  # The branch helper resets and cleans an existing checkout. Development
  # installs need NanoClaw's staged update, migrations and rollback instead.
  msg_error "Helper updates are not supported for this development checkout."
  msg_info "As the nanoclaw user, follow .claude/skills/update-nanoclaw/SKILL.md in your checkout."
  exit 1
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} development checkout is prepared at /opt/nanoclaw.${CL}"
echo -e "${INFO}${YW}Complete authentication, agent setup and service installation with the interactive wizard:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}pct enter ${CT_ID}${CL}"
echo -e "${TAB}${GATEWAY}${BGN}machinectl shell nanoclaw@${CL}"
echo -e "${TAB}${GATEWAY}${BGN}cd /opt/nanoclaw && bash nanoclaw.sh${CL}"
