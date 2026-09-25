{ pkgs, config, node, ... }:
{
  services.nginx = {
    virtualHosts = {
      "${node.domains.ladugardlive}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.ladugard-live;
      };
    };
  };
}
