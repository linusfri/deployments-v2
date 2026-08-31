{
  config,
  pkgs,
  node,
  inputs,
  ...
}:
let
  siteName = "schoolity";
  siteCfg = config.services.ts1997.laravelSites.${siteName};
in
{
  imports = [ inputs.devops-templates.nixosModules.default ];

  services.ts1997.laravelSites.${siteName} = {
    enable = true;
    appName = "Schoolity portal";
    locale = "sv";
    domain = "schema.skagget.se";
    forceWWW = false;

    database.driver = "mysql";

    # No Inertia SSR, queued jobs, or scheduled tasks today (see the app's
    # own DEPLOY.md) - it's Livewire/Volt over Blade with database-backed
    # cache/sessions. Flip these back on if that changes.
    inertiaSsr.enable = false;
    queue.enable = false;
    scheduler.enable = false;
    redis.enable = false;

    # Deployed as an immutable package (read-only Nix store output) rather
    # than a mutable rsync'd checkout: only storage/ and bootstrap/cache/
    # are writable, symlinked out to workingDir (passed here as dataDir).
    package = pkgs.callPackage "${inputs.schoolity-portal}/package.nix" {
      dataDir = siteCfg.workingDir;
    };

    # Runs "php artisan migrate --force" on every deploy that ships a new
    # package (there's no CI workflow doing this for package-mode sites).
    migrate.enable = true;

    env = {
      APP_TIMEZONE = "Europe/Stockholm";
    };

    envSecretsFile = config.age.secrets.schoolityEnv.path;
  };

  # APP_KEY encrypts sessions/cookies; SCHOOLITY_ENCRYPTION_KEY separately
  # encrypts stored Schoolity connections at rest (kept apart so APP_KEY can
  # be rotated on its normal schedule without invalidating those). Both are
  # generated once and merged into the site's env file by generate-env.
  age.generators.laravel-app-keys =
    { pkgs, ... }:
    ''
      cat <<EOF
      APP_KEY=base64:$(${pkgs.openssl}/bin/openssl rand -base64 32)
      SCHOOLITY_ENCRYPTION_KEY=base64:$(${pkgs.openssl}/bin/openssl rand -base64 32)
      EOF
    '';

  age.secrets.schoolityEnv = {
    rekeyFile = ../servers/${node.name}/secrets/schoolity-env.age;
    generator.script = "laravel-app-keys";
  };
}
