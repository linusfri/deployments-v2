# nixiform-v2

Minimal NixOS server deployment built around four separate responsibilities:

- **OpenTofu** provisions Hetzner and Cloudflare infrastructure.
- **The infrastructure parser** reads the pulled `terraform.tfstate` and exposes its `terraflake`/`nixiform` node output to Nix.
- **nixos-anywhere + disko** perform the initial destructive NixOS installation.
- **deploy-rs** deploys all later NixOS generations.
- **agenix-rekey** generates, rekeys, and deploys secrets.

No application modules are included. The host imports only `authorized-keys`, `common`, `db`, `virtualisation`, and `www`.

## Prerequisites

The OpenTofu backend and provider credentials must already be available in the environment. Initialize it once:

    tofu -chdir=opentofu init

The workflow commands pull the remote state into a temporary, ignored `terraform.tfstate`, temporarily add it to the Git index for pure flake evaluation, and remove it on exit. Never commit this state file.

## Development shell

    nix develop

Provisioning credentials are stored in the encrypted token bundle. On the first use, decrypt and export them, then re-enter the shell so they are loaded into the environment:

    tokens
    exit
    nix develop

The generated credential script is ignored by Git and created with mode `0600`. Its hash is checked whenever the development shell starts; rerun `tokens` if the encrypted bundle changes.

No command assumes a host. Omitting the host from installation or deployment fails with usage information.

Inspect parsed node outputs:

    refresh-infrastructure

## Provision infrastructure

    tofu -chdir=opentofu apply

The root OpenTofu module must expose nodes through an output named `terraflake` or `nixiform`. Each node must at least contain `name`, `ip`, and `ssh_key`.

## Initial installation

Review `nixos/servers/<host>/disk-config.nix` first. Installation repartitions and formats the target disk.

For the configured node:

    install-system hetzvps

This infers `root@<node.ip>` from state. An explicit target and extra nixos-anywhere arguments can be supplied:

    install-system hetzvps root@203.0.113.10 --copy-host-keys

Use `--copy-host-keys` when replacing an existing installation and retaining its SSH host key. For a new host, update `nixos/servers/<host>/ssh-host-key.pub` from `ssh-keyscan`, then run `tofuAge rekey -a` before installing secrets.

## Subsequent deployment

    deploy-system hetzvps

Additional arguments are forwarded to deploy-rs:

    deploy-system hetzvps --dry-activate

## Secrets

The host imports both agenix and agenix-rekey. Host-specific configuration is in `nixos/servers/<host>/rekey.nix`.

Typical commands:

    tofuAge generate -a
    tofuAge rekey -a
    tofuAge edit

Define secrets in an imported NixOS module with `age.secrets.<name>.rekeyFile`. Rekeyed files use `secrets/rekeyed/<host>`.

## Adding a host

1. Add the node to the OpenTofu `terraflake` output.
2. Create `nixos/servers/<name>/default.nix`, `disk-config.nix`, `hardware.nix`, `rekey.nix`, and `ssh-host-key.pub`.
3. Ensure the directory name exactly matches the node's `name` in state.
4. Run `refresh-infrastructure`, then install or deploy with the explicit host name.

The flake derives `nixosConfigurations` and `deploy.nodes` from the parsed state; no separate host list is maintained.
