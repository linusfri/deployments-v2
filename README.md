# deployments-v2

Minimal NixOS server deployment built around four separate responsibilities:

- **OpenTofu** provisions Hetzner and Cloudflare infrastructure.
- **The infrastructure parser** reads the pulled `terraform.tfstate` and exposes its `terraflake`/`nixiform` node output to Nix.
- **nixos-anywhere + disko** perform the initial destructive NixOS installation.
- **deploy-rs** deploys all later NixOS generations.
- **agenix-rekey** generates, rekeys, and deploys secrets.

## Prerequisites

The OpenTofu backend and provider credentials must already be available in the environment. Initialize it once:

    tofu -chdir=opentofu init

The workflow commands pull the remote state into a temporary, ignored `terraform.tfstate`, temporarily add it to the Git index for pure flake evaluation, and remove it on exit. Never commit this state file.

For the tokens command to work, you need to generate a new age identity and update ```master-identity.nix```.
```
age-keygen -o /tmp/new-master.txt
# note the printed "Public key: age1..." line
age -p -o secrets/rekeyed/new-master.age /tmp/new-master.txt
shred -u /tmp/new-master.txt   # or `rm -P`/`rm` if shred unavailable
```

## Development shell

    nix develop

Provisioning credentials are stored in the encrypted token bundle. On the first use, decrypt and export them, then re-enter the shell so they are loaded into the environment:

    tokens
    exit
    nix develop

Or if you're using direnv this is done automatically.

The generated credential bash file is checked whenever the development shell starts; rerun `tokens` if the encrypted bundle changes.

No command assumes a host. Omitting the host from installation or deployment fails with usage information.

Inspect parsed node outputs:

    show-infra

## Provision infrastructure

    tofu -chdir=opentofu apply

The root OpenTofu module must expose nodes through an output named `terraflake` or `nixiform`. Each node must at least contain `name`, `ip`, and `ssh_key`.

## Initial installation

Review `nixos/servers/<host>/disk-config.nix` first. Installation repartitions and formats the target disk.

For the configured node:

    install-system hetzvps

This infers `root@<node.ip>` from state. An explicit target and extra nixos-anywhere arguments can be supplied:

    install-system hetzvps root@203.0.113.10 --copy-host-keys

Use `--copy-host-keys` when replacing an existing installation and retaining its SSH host key. For a new host, update `nixos/servers/<host>/ssh-host-key.pub` from `ssh-keyscan`, then run `tofuAge rekey -a` before pushing secrets.

## Subsequent deployment

    deploy-system hetzvps

Additional arguments are forwarded to deploy-rs:

    deploy-system hetzvps --dry-activate

### Deploy all systems

    deploy-all

This will deploy to all nodes in `deploy.nodes` parsed from tofu state. 

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
3. Ensure the directory name exactly matches the node's `name` in tofu state.
4. Run `show-infra`, then install or deploy with the explicit host name.

The flake derives `nixosConfigurations` and `deploy.nodes` from the parsed state; no separate host list is maintained.
