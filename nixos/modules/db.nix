{ pkgs, lib, ... }:
{
  # Repo-wide DB engine versions.
  #
  # NOTE: services.mysql.package must stay mkForce'd to mysql84: hetzvps'
  # Nextcloud runs on mysql84 but recently changed to mariadb.
  # Don't feel like migrating this yet.
  services.mysql = {
    package = lib.mkForce pkgs.mysql84;
  };

  # Pin postgres_18 to make sure that conflicts are easier to spot, if a package bumps its version.
  services.postgresql = {
    package = lib.mkForce pkgs.postgresql_18;
  };
}
