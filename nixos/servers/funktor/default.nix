{
  node,
  inputs,
  ...
}:
let
  applicationsFolderPath = ../../applications;

  applicationFileNames = [

  ];

  mkFullPaths = folderPath: fileNames: map (fileName: folderPath + "/${fileName}") fileNames;
in
{
  imports = [
    ./hardware.nix
    ./rekey.nix
    ./overlay.nix
    ../../modules/default.nix
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
  system.stateVersion = "26.05";
}
