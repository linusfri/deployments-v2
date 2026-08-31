{ pkgs, lib, ... }:
{
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    25
    465
  ];

  services.nginx = lib.mkDefault {
    package = pkgs.nginx.override {
      modules = [ pkgs.nginxModules.cache-purge ];
    };
    enable = true;
    enableReload = true;
    logError = "stderr";
  };
}
