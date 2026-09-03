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
    appName = "Fritidsschema";
    locale = "sv";
    domain = "schema.skagget.se";
    forceWWW = false;

    database.driver = "mysql";

    inertiaSsr.enable = false;
    queue.enable = false;
    scheduler.enable = false;
    redis.enable = false;

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
