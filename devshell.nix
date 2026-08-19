{
  pkgs,
  deploy-rs,
  nixos-anywhere,
  workflows,
}:
let
  tokens = pkgs.writeShellApplication {
    name = "tokens";
    runtimeInputs = [
      pkgs.age
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      tokens_json=$(age -d -i "$AGE_KEY" "$SECRETS")

      # Format: "json_key:ENV_VAR_NAME"
      # The selector in the json file comes first
      # and then the actual variable name to export
      variable_pairs_to_export=(
        "cloudflare_token:TF_VAR_cloudflare_token"
        "hcloud_token:HCLOUD_TOKEN"
        "aws_access_key_id:AWS_ACCESS_KEY_ID"
        "aws_secret_access_key:AWS_SECRET_ACCESS_KEY"
        "aws_region:AWS_REGION"
        "storagebox_backups_password:TF_VAR_storagebox_backups_password"
      )

      # Overwrite the file each time this is run
      : > "$ROOT_DIR/.tokens.sh"

      for pair in "''${variable_pairs_to_export[@]}"; do
        json_key="''${pair%%:*}"
        env_var="''${pair##*:}"
        value=$(jq -r ".$json_key // \"\"" <<<"$tokens_json")
        echo "export $env_var='$value'" >> "$ROOT_DIR/.tokens.sh"
      done

      # Record a hash of the encrypted secrets file so we can detect when new
      # secrets are added and avoid secrets getting out of sync.
      sha256sum "$SECRETS" | cut -d' ' -f1 > "$ROOT_DIR/.tokens.hash"

      echo "Tokens exported to .tokens.sh"
    '';
  };

  fetchRcloneConfig = pkgs.writeShellScriptBin "fetch-rclone-config" ''
    set -euo pipefail

    SECRET_FILE="$ROOT_DIR/nixos/servers/hetzvps/secrets/rcloneConfig.age"
    DEST_FILE="$HOME/.config/rclone/rclone.conf"

    mkdir -p "$(dirname "$DEST_FILE")"
    tofuage view "$SECRET_FILE" > "$DEST_FILE"

    echo "rclone config written to $DEST_FILE"
  '';

  setEnvironment = pkgs.writeShellApplication {
    name = "set-environment";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      GREEN="\033[0;32m"
      RED="\033[0;31m"
      RESET="\033[0m"

      if [[ -f "$ROOT_DIR/.tokens.sh" ]]; then
        echo -e "''${GREEN}.tokens.sh found, setting environment.''${RESET}"
        # This file is generated at runtime by the tokens command.
        # shellcheck source=/dev/null
        source "$ROOT_DIR/.tokens.sh"

        # Warn if the encrypted secrets have changed since .tokens.sh was generated.
        if [[ -f "$ROOT_DIR/.tokens.hash" ]]; then
          current_hash=$(sha256sum "$SECRETS" | cut -d' ' -f1)
          stored_hash=$(cat "$ROOT_DIR/.tokens.hash")
          if [[ "$current_hash" != "$stored_hash" ]]; then
            echo -e "''${RED}Secrets have changed since .tokens.sh was generated, run 'tokens' to refresh.''${RESET}"
          fi
        fi
      else
        echo -e "''${RED}.tokens.sh not found, run 'tokens' ''${RESET}"
      fi
    '';
  };

in
pkgs.mkShell {
  packages = (builtins.attrValues workflows) ++ [
    pkgs.age
    pkgs.agenix-rekey
    pkgs.git
    pkgs.jq
    pkgs.opentofu
    deploy-rs
    nixos-anywhere
    setEnvironment
    fetchRcloneConfig
    tokens
  ];

  shellHook = ''
    export ROOT_DIR="$PWD"
    export SECRETS="$ROOT_DIR/secrets/tofu-tokens/tokens.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/rekeyed/master.age"

    source set-environment

    echo "Commands: tokens, refresh-infrastructure, install-system, deploy-system, tofuAge"
  '';
}
