{
  node,
  inputs,
  ...
}:
let
  applicationsFolderPath = ../../applications;

  applicationFileNames = [
    "calc-api.nix"
    "privacy.nix"
    "mailserver.nix"
    "nextcloud.nix"
    "jellyfin.nix"
    "keycloak.nix"
    "rclone-r2.nix"
    "github-docs.nix"
    "ladugardlive.nix"
    "handy-gleam.nix"
    "conversions.nix"
    "plantuml.nix"
    "odoo.nix"
  ];

  mkFullPaths = folderPath: fileNames: map (fileName: folderPath + "/${fileName}") fileNames;
in
{
  imports = [
    ./hardware.nix
    ./rekey.nix
    ./overlay.nix
    ../../modules/default.nix
    inputs.mailserver.nixosModules.default
  ]
  ++ mkFullPaths applicationsFolderPath applicationFileNames;

  networking = {
    hostName = node.name;
    useNetworkd = true;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [ node.ssh_key ];

  # Pinned to the stateVersion the host was originally installed with;
  # do not bump this when upgrading nixpkgs.
  system.stateVersion = "25.05";
}
