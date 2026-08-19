{ pkgs, ... }:
{
  services.mysql = {
    enable = true;

    package = pkgs.mysql84;
  };

  services.postgresql = {
    package = pkgs.postgresql_18;
  };
}
