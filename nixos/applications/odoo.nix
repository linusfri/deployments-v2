{ config, pkgs, node, ... }:
let
  domain = node.domains.odoo;
in
{
  services.odoo = {
    enable = true;
    domain = domain;
    autoInit = true;
  };

  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
  };

  services.dbBackup.odoo-postgres = {
    dumpCommand = pkgs.writeShellScript "dump-odoo-db" ''
      exec ${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dump --dbname=odoo
    '';
  };
}
