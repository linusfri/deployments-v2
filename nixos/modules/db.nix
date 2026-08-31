{ pkgs, lib, ... }:
{
  # Repo-wide fallback DB engine versions. Use mkOptionDefault (priority 1500)
  # rather than mkDefault (1000) so that service modules with their own
  # mkDefault package choice (e.g. nixpkgs' nextcloud.nix picking mariadb for
  # a locally-managed mysql db) win instead of conflicting with this one.
  services.mysql = {
    package = lib.mkOptionDefault pkgs.mysql84;
  };

  services.postgresql = {
    package = lib.mkOptionDefault pkgs.postgresql_18;
  };
}
