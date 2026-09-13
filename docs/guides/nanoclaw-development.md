# NanoClaw development LXC

This helper prepares a **fresh, unprivileged Debian 13 LXC for personal
NanoClaw development**. It installs Node.js 22, Corepack, Docker and native build
dependencies, then builds a full Git checkout of `nanocoai/nanoclaw`'s `main`
branch at `/home/nanoclaw/nanoclaw`, owned by the `nanoclaw` developer account.
Defaults are 2 CPUs, 8 GiB RAM and 40 GiB storage,
with nesting and keyctl enabled.

After building the checkout, an interactive run asks **Start NanoClaw setup
now?** Choosing Yes opens the upstream wizard in the same terminal as the
`nanoclaw` user. The wizard configures credentials, OneCLI, the agent image,
a channel and the service. Choosing No, pressing Enter or waiting 60 seconds
leaves setup for later. Unattended runs skip this prompt. There is no web
interface port or default password.

## Fit with the contribution guidance

This branch is deliberately for development and continues to follow `main`.
Before preparing an upstream helper-script PR, convert installation to an
official NanoClaw release tag using the shared release helper, restore a
working release-based update path, and test installation and updates end to
end. That conversion belongs to the submission stage, not the current
development workflow. Docker's role as the agent runtime remains a separate
question for the maintainers; selecting a release does not settle it.

Reviewed against ProxmoxVED `334d584e`, community-scripts/core `49ccc2c`, and
NanoClaw `3f9ed607b7e7a4872747295f75286f1c377d7c33` on 2026-09-13. The installer follows
upstream `main` at install time; these hashes identify the reviewed sources.

| Expectation | Implementation |
| --- | --- |
| Standard CT, installer and metadata files | `ct/nanoclaw.sh`, `install/nanoclaw-install.sh`, `json/nanoclaw.json`; current core bootstrap and standard installer footer |
| Shared runtime and download helpers | `setup_nodejs` with `NODE_MODULE="corepack"`, `setup_docker`, `fetch_and_deploy_gh_branch` |
| No redundant dependencies or logging | Only native build and user-session packages; helpers supply their own messages; `apt` and build commands use `$STD` |
| Genuine development source | Clone `main` through the branch helper, then fetch full history, tags and branch refs; no tarball with reconstructed Git history |
| Accurate metadata and completion | Matching resources and home-directory paths, repository URL, no web port, `updateable: false`, optional wizard launch and a single resume command |
| Prompts can be skipped | Shared `is_unattended` and `prompt_confirm` helpers; non-terminal runs skip the wizard; the caller's unattended mode is recorded before provisioning changes it |

There are material differences from the release-oriented template which need
maintainer agreement before an upstream submission:

- **Docker:** the host application is installed natively, but agents and
  OneCLI require Docker. This cannot satisfy an absolute prohibition on Docker.
- **Developer account:** `nanoclaw` owns the checkout and runs the interactive
  tools and upstream user service. It has Docker group access, which is
  root-equivalent inside the LXC. This differs from the normal root-only template.
- **Updates:** this is a development checkout of a branch, not a release
  deployment. The core branch helper uses `reset --hard` and `clean -fd` on an
  existing checkout. The installer refuses existing paths/accounts, and the CT
  update entry point exits with an error directing users to NanoClaw's
  transactional updater. It does not claim helper-managed updates.
- **Service and authentication:** the upstream wizard owns these steps. The
  helper does not create a competing service or preinstall a provider CLI.

The optional wizard handoff preserves the script structure and uses a shared
prompt helper, but it does not resolve the exceptions above. In particular,
the [new-script PR checklist](https://github.com/community-scripts/ProxmoxVED/blob/main/.github/pull_request_template.md)
explicitly prohibits Docker, while the
[contribution guidance](https://github.com/community-scripts/ProxmoxVED/blob/main/AGENTS.md)
expects release-based deployment and a functional helper update path. This
personal-development helper cannot claim full compliance with those rules.

The implementation is suitable for local evaluation; these exceptions and
the remaining runtime and update validation matter for maintainer acceptance.

## Run an unpublished checkout on Proxmox

Place this modified ProxmoxVED checkout and a checkout of
`community-scripts/core` next to each other **on the Proxmox host**:

```text
/root/core/
/root/ProxmoxVED/
```

From the host's root shell:

```bash
cd /root/ProxmoxVED
dev_mode=keep,net,timing bash ct/nanoclaw.sh
```

The engine reads the local installer and pipes it into the LXC. No public
branch is required for this test. `keep` preserves a failed container for
inspection. See [script origin](source-origin.md) for alternate checkout paths
and public-fork execution. Downloaded CT scripts require an explicit
`COMMUNITY_SCRIPTS_URL` pointing at a published branch; fetching just the CT
script from a fork does not select that fork's installer.

## Finish setup and develop

Accept **Start NanoClaw setup now?** to continue directly into NanoClaw's
wizard. Authentication and channel questions stay in NanoClaw's own setup
flow, so the helper does not need a separate copy of that logic.

To continue later, run the single command printed by the helper from a
terminal on the Proxmox host. Replace `123` with your container ID:

```bash
pct exec 123 --keep-env 0 -- machinectl shell nanoclaw@ /usr/bin/bash -lc 'cd /home/nanoclaw/nanoclaw && exec bash nanoclaw.sh'
```

`machinectl shell` creates the login session needed to reach the systemd user
manager. Linger keeps that manager available after logout. The account has no
password set by this helper; configure an SSH key separately if desired.

The handoff requires terminal input and output. An unattended mode supplied
by the caller, such as `mode=default` or `var_unattended=yes`, skips it. An
interactive choice of default container settings still offers NanoClaw setup.
Returning from the wizard does not by itself prove configuration is complete;
follow its result and verification steps.

Work as `nanoclaw` in `~/nanoclaw`. The checkout has full history, tags and
remote branch refs for normal Git development. Follow the checkout's own
development instructions for builds and tests. NanoClaw mounts agent source
into its runtime containers; changes to agent dependencies or image tooling
also require the upstream image-build workflow.

For an established installation, follow
`.claude/skills/update-nanoclaw/SKILL.md` in the checkout. It stages integration
and validation, snapshots mutable state, handles migrations and checks the
service after cutover. Save local changes first and stop any manually running
development host. Raw pulls or branch changes alone do not complete this
workflow: NanoClaw gates startup on an exact-code upgrade marker. Do not bypass
that gate by deleting or blindly rewriting the marker.

## Validation before an upstream submission

Local validation on 2026-09-13 passed Linux Bash syntax checks for all 252
repository scripts, JSON metadata assertions and ShellCheck at warning level
for both NanoClaw scripts (excluding `SC1090` for the standard dynamic core
bootstrap).

An isolated Debian test used the actual core branch helper against a local
Git fixture, with package installation, runtime setup, systemd and pnpm
commands stubbed. It verified full history and refs, developer ownership and
write access under `/home/nanoclaw/nanoclaw`, dependency and build command
context, refusal of existing paths/accounts and dangling
symlinks, preservation of local work on reinstall/update attempts, and early
exit when dependency installation fails. This does not verify real runtime
installation, the NanoClaw build or LXC behavior.

Fifteen terminal cases used the actual core prompt helpers and a stubbed
container launcher. They verified the offered wizard after interactive default
and advanced settings, acceptance and decline, Enter to defer, wizard failure
and cancellation, explicit unattended modes, redirected input/output, exact
launch arguments and the printed resume command.

Fresh Proxmox runs on 2026-09-13 exercised the modified helper against core
`49ccc2cf4450eea708c806cd4fba5749ff049a0a` and NanoClaw
`3f9ed607b7e7a4872747295f75286f1c377d7c33`. Selecting Default Install created an
unprivileged Debian 13 LXC, installed dependencies and built the full checkout
under `/home/nanoclaw/nanoclaw`. Accepting the helper's setup prompt opened
NanoClaw's public wizard in the same terminal. The progression log confirmed
`user: nanoclaw`, the home checkout and a successful bootstrap. Ownership,
write access, Docker access and the lingering systemd user manager were also
verified. The wizard completed its environment check, built the local agent
image and installed OneCLI.

A complete fresh run then passed the public wizard in one invocation of the
helper. It selected Claude, imported the authorized OAuth credential through
the wizard, retained a terminal agent and received the correct answer to a
random arithmetic question. Every required setup step succeeded; the
progression log had a clean completion footer, and final `VERIFY` reported
success with one registered group, configured credentials and mount allowlist,
a local image and a running service.

After the terminal exited, an independent check matched the systemd user
service's current process to this exact checkout and connected to its CLI
socket. The container was then rebooted. A changed boot ID, the enabled user
service, Docker access and the CLI socket were verified, and the retained
agent answered a second random arithmetic question correctly. Sanitized logs
and results were validated against checksums, run identity, revision, exit
status and credential redaction before being saved locally.

The test harness was adapted for the current runtime picker, ASCII prompts
and timezone confirmation. On this core revision the guest inherited the
host's Europe/Madrid timezone even when the fixture requested UTC; the
successful run used the normal helper defaults and selected UTC through
NanoClaw's own prompts. The test required the recorded choice and successful
UTC persistence. Earlier failed or cancelled attempts retain separate evidence;
none was converted into a pass, and no product repair or setup bypass was used.

This qualifies fresh installation and the interactive wizard path on the
tested amd64 Proxmox configuration. The upstream update workflow with preserved
local work, future release-based installation and helper updates still need
their own end-to-end validation before submission. ARM64 support remains
undeclared until tested.
