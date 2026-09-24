# NanoClaw development LXC

This helper prepares a **fresh, unprivileged Debian 13 amd64 LXC for personal
NanoClaw development**. It installs Node.js 22, Corepack, Docker and native build
dependencies, then builds a full Git checkout of `nanocoai/nanoclaw`'s `main`
branch at `/home/nanoclaw/nanoclaw`, owned by the `nanoclaw` developer account.
Defaults are 2 CPUs, 8 GiB RAM and 40 GiB storage, with nesting and keyctl enabled.

After building the checkout, an interactive run asks **Start NanoClaw setup
now?** Choosing Yes opens the upstream wizard in the same terminal as the
`nanoclaw` user. The wizard owns provider installation, authentication, OneCLI,
the agent image, agent creation and the user service. Choosing No, pressing Enter
or waiting for the prompt timeout leaves setup for later. Unattended runs skip
the prompt. There is no web interface port or default password.

## Scope and contribution fit

This is a personal-development helper that intentionally tracks NanoClaw
`main`. It is not the upstream release helper: that script installs tagged
NanoClaw releases with a helper-managed update path and is maintained as a
separate submission to community-scripts/ProxmoxVED. This variant differs from
it in several ways:

- NanoClaw runs natively, but its agent and OneCLI runtimes require Docker.
- A writable `nanoclaw` developer account owns the checkout and belongs to the
  Docker group, which is root-equivalent inside the LXC.
- `fetch_and_deploy_gh_branch` is appropriate for this development checkout,
  but official submissions require a release-based deployment and update path.
- Helper-managed updates are disabled because branch replacement would destroy
  local work. Established installs use NanoClaw's transactional updater.
- amd64 is the only architecture declared until a separate ARM64 run passes.

These exceptions must not be described as compliance with the upstream
ProxmoxVED new-script checklist. A future release-helper submission needs an
explicit maintainer decision on Docker, a working update lifecycle, and its own
fresh-install and update evidence.

The current refresh was reviewed on 2026-09-21 against ProxmoxVED
`db61346b49f2333020be843f929cc2bec6bd6a3f`, community-scripts/core
`1d9caf9d876ff67cda297cc6a6847cd98af6d68e`, NanoClaw
`7902716b5b930215dbee4f56b8fb5b938d40468d`, and OSS Dev Tools
`30ead7f8439b0810dd00017a875abaf19efda3b7`. These hashes identify the
reviewed sources; live qualification is recorded separately below.

## Run an unpublished checkout

Place this ProxmoxVED worktree and a checkout of `community-scripts/core` next
to each other on the Proxmox host:

```text
/root/core/
/root/ProxmoxVED/
```

Then run:

```bash
cd /root/ProxmoxVED
dev_mode=keep,net,timing bash ct/nanoclaw.sh
```

The engine reads the local installer and pipes it into the new LXC. `keep`
preserves a failed container for inspection. Downloaded CT scripts need an
explicit `COMMUNITY_SCRIPTS_URL` pointing at the same published branch; fetching
only the CT script from a fork does not select that fork's installer.

## Resume setup and develop

Accept the helper prompt to continue directly into NanoClaw's public wizard.
To resume later, run the command printed by the helper from the Proxmox host,
replacing `123` with the container ID:

```bash
pct exec 123 --keep-env 0 -- machinectl shell nanoclaw@ /usr/bin/bash -lc 'cd /home/nanoclaw/nanoclaw && exec bash nanoclaw.sh'
```

`machinectl shell` creates the login session needed for the systemd user
manager. Linger keeps that manager available after logout. The account has no
password set by this helper; configure an SSH key separately if required.

Work as `nanoclaw` in `~/nanoclaw`. The checkout has full history, tags and
remote branch refs. For an established installation, follow
`.claude/skills/update-nanoclaw/SKILL.md`. Save local changes first and stop any
manually running development host. A raw pull or branch change does not complete
NanoClaw's migration, rebuild, service and rollback workflow.

## Validation contract

Static acceptance requires Bash syntax, ShellCheck at warning level, JSON
parsing and metadata assertions. Fixture coverage must prove checkout ownership,
full history, build context, refusal of existing paths/accounts, local-work
preservation and prompt behavior.

Live acceptance uses the OSS Dev Tools public-wizard Proxmox adapter on a fresh
unprivileged Debian 13 amd64 LXC. It must bind the exact NanoClaw and provider
payload commits, complete the real wizard, receive a computed reply from the
retained agent, verify the effective provider and model, pass NanoClaw's final
verification, match the user service to the tested checkout, reach the CLI
socket, and export validated sanitized artifacts. Every created guest is retained
until evidence and ownership are checked; cleanup is separately authorized.

The 2026-09-13 baseline passed this contract with Claude and also passed reboot
recovery. That evidence remains tied to NanoClaw `3f9ed607b7e7a4872747295f75286f1c377d7c33`,
core `49ccc2cf4450eea708c806cd4fba5749ff049a0a`, and helper merge
`7e468bcc1799ca57540f57d86375c81a7369ef28`. It does not qualify current
NanoClaw, current core, OpenCode, ARM64, release installation or helper updates.

The refreshed OpenCode-on-Proxmox result will be added here only after a new
fresh run satisfies the acceptance contract without product repair.
