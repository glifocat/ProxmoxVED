# NanoClaw development LXC

This helper prepares a **fresh, unprivileged Debian 13 LXC for personal
NanoClaw development**. It installs Node.js 22, Corepack, Docker and native build
dependencies, then builds a full Git checkout of `nanocoai/nanoclaw`'s `main`
branch at `/opt/nanoclaw`. Defaults are 2 CPUs, 8 GiB RAM and 40 GiB storage,
with nesting and keyctl enabled.

The helper finishes when the checkout is built. NanoClaw's interactive wizard
still needs to configure credentials, OneCLI, the agent image, a channel and
the service. There is no web interface port or default password.

## Fit with the contribution guidance

Reviewed against ProxmoxVED `bbfb8e580fa735cf6b8885421c53ab8bc52a1d85`,
community-scripts/core `447e90df8b84a2f660fd7aea25c15f94c1bacdaa`, and
NanoClaw `74224f62a6c08418acccc727114ab02f92e403bf`. The installer follows
upstream `main` at install time; these hashes identify the reviewed sources.

| Expectation | Implementation |
| --- | --- |
| Standard CT, installer and metadata files | `ct/nanoclaw.sh`, `install/nanoclaw-install.sh`, `json/nanoclaw.json`; current core bootstrap and standard installer footer |
| Shared runtime and download helpers | `setup_nodejs` with `NODE_MODULE="corepack"`, `setup_docker`, `fetch_and_deploy_gh_branch` |
| No redundant dependencies or logging | Only native build and user-session packages; helpers supply their own messages; `apt` and build commands use `$STD` |
| Genuine development source | Clone `main` through the branch helper, then fetch full history, tags and branch refs; no tarball with reconstructed Git history |
| Accurate metadata and completion | Matching resources and paths, repository URL, no web port, `updateable: false`, explicit wizard instructions |

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

The implementation is suitable for local evaluation; these exceptions and a
real Proxmox test remain relevant to maintainer acceptance.

## Run an unpublished checkout on Proxmox

Place this modified ProxmoxVED checkout and a checkout of
`community-scripts/core` next to each other **on the Proxmox host**:

```text
/opt/core/
/opt/ProxmoxVED/
```

From the host's root shell:

```bash
cd /opt/ProxmoxVED
dev_mode=keep,net,timing bash ct/nanoclaw.sh
```

The engine reads the local installer and pipes it into the LXC. No public
branch is required for this test. `keep` preserves a failed container for
inspection. See [script origin](source-origin.md) for alternate checkout paths
and public-fork execution. Downloaded CT scripts require an explicit
`COMMUNITY_SCRIPTS_URL` pointing at a published branch; fetching just the CT
script from a fork does not select that fork's installer.

## Finish setup and develop

Use the container ID printed by the helper:

```bash
pct enter <CT_ID>
machinectl shell nanoclaw@
cd /opt/nanoclaw
bash nanoclaw.sh
```

`machinectl shell` creates the login session needed to reach the systemd user
manager. Linger keeps that manager available after logout. The account has no
password set by this helper; configure an SSH key separately if desired.

Work as `nanoclaw` in `/opt/nanoclaw`. The checkout has full history, tags and
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

Local validation on 2026-09-11 passed Linux Bash syntax checks for all 252
repository scripts, JSON metadata assertions and ShellCheck at warning level
for both NanoClaw scripts (excluding `SC1090` for the standard dynamic core
bootstrap).

An isolated Debian test used the actual core branch helper against a local
Git fixture, with package installation, runtime setup, systemd and pnpm
commands stubbed. It verified full history and refs, developer ownership and
build command context, refusal of existing paths/accounts and dangling
symlinks, preservation of local work on reinstall/update attempts, and early
exit when dependency installation fails. This does not verify real runtime
installation, the NanoClaw build or LXC behavior.

A complete Proxmox test must verify the default unprivileged container,
Docker access from the developer login, a successful interactive wizard,
real agent inference, service operation after logout and reboot, and the
upstream update workflow with preserved local work. Neither syntax checks nor
a successful TypeScript build establishes these outcomes. ARM64 support is
left undeclared until tested.
