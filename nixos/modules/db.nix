{ pkgs, lib, ... }:
{
  # Repo-wide DB engine versions.
  #
  # NOTE: services.mysql.package must stay mkForce'd to mysql84: hetzvps'
  # /var/lib/mysql is a MySQL 8.4 datadir (uses #innodb_redo/, no ib_logfile0),
  # which MariaDB cannot read. nixpkgs' nextcloud.nix sets
  # `services.mysql.package = lib.mkDefault pkgs.mariadb` when
  # database.createLocally is used with dbtype=mysql, and mkDefault (1000)
  # would win over mkOptionDefault (1500), silently switching engines and
  # breaking mysql.service on deploy. A future migration to MariaDB requires a
  # logical mysqldump -> wipe datadir -> restore.
  services.mysql = {
    package = lib.mkForce pkgs.mysql84;
  };

  # Pin postgres_18 to make sure that conflicts are easier to spot, if a package bumps its version.
  services.postgresql = {
    package = lib.mkForce pkgs.postgresql_18;
  };
}
