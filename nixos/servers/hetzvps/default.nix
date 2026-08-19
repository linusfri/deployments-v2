{
  node,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./rekey.nix
    ../../modules/default.nix
  ];

  networking = {
    hostName = node.name;
    useNetworkd = true;
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [ node.ssh_key ];

  system.stateVersion = "25.05";
}
