{ pkgs }:
let
  stateWrapper = command: ''
    set -euo pipefail

    root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    state="$root/terraform.tfstate"
    tmp="$(mktemp)"

    cleanup() {
      rm -f "$tmp"
      if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "$root" rm --cached -q -f --ignore-unmatch -- "$state" >/dev/null 2>&1 || true
      fi
      rm -f "$state"
    }
    trap cleanup EXIT

    credentials="$root/.tokens.sh"
    if [[ ! -f "$credentials" ]]; then
      echo "Missing $credentials; enter the development shell and run 'tokens' first." >&2
      exit 1
    fi

    # shellcheck disable=SC1090
    source "$credentials"

    ${pkgs.opentofu}/bin/tofu -chdir="$root/opentofu" state pull > "$tmp"
    mv "$tmp" "$state"

    if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$root" add -f "$state"
    fi

    cd "$root"
    ${command}
  '';
in
{
  refresh-infrastructure = pkgs.writeShellApplication {
    name = "refresh-infrastructure";
    runtimeInputs = [ pkgs.git pkgs.opentofu ];
    text = stateWrapper ''
      echo "OpenTofu state is available for the lifetime of this command."
      nix eval .#infrastructure.nodes --json | ${pkgs.jq}/bin/jq
    '';
  };

  install-system = pkgs.writeShellApplication {
    name = "install-system";
    runtimeInputs = [ pkgs.git pkgs.opentofu ];
    text = ''
      host="''${1:?Usage: install-system HOST [TARGET] [NIXOS-ANYWHERE-ARGS...]}"
      shift
    '' + stateWrapper ''

      if (( $# > 0 )); then
        target="$1"
        shift
      else
        target="root@$(nix eval --raw ".#infrastructure.nodes.$host.ip")"
      fi

      nix run .#nixos-anywhere -- \
        --flake ".#$host" \
        --target-host "$target" \
        "$@"
    '';
  };

  deploy-system = pkgs.writeShellApplication {
    name = "deploy-system";
    runtimeInputs = [ pkgs.git pkgs.opentofu ];
    text = ''
      host="''${1:?Usage: deploy-system HOST [DEPLOY-RS-ARGS...]}"
      shift
    '' + stateWrapper ''
      nix run .#deploy-rs -- ".#$host" "$@"
    '';
  };

  tofuAge = pkgs.writeShellApplication {
    name = "tofuAge";
    runtimeInputs = [ pkgs.agenix-rekey pkgs.git pkgs.opentofu ];
    text = stateWrapper ''
      agenix "$@"
    '';
  };
}
