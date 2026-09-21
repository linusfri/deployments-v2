{
  config,
  node,
  pkgs,
  ...
}:
{
  services.linusfri.nextcloud = {
    enable = true;
    hostName = node.domains.nextcloud;
    adminpassFile = config.age.secrets.nextcloudAdminPass.path;
    package = pkgs.nextcloud35;

    s3 = {
      bucket = "nextcloudbucket";
      key = "4d23100824c5df222d14fc527c4b929a";
      secretFile = config.age.secrets.cloudflares3SecretKey.path;
      hostname = "912391589165daea759d3cdcea0c7ced.r2.cloudflarestorage.com";
      region = "auto";
    };
  };

  services.dbBackup.nextcloud-db = {
    dumpCommand = pkgs.writeShellScript "dump-nextcloud-db" ''
      exec ${config.services.mysql.package}/bin/mysqldump -u root nextcloud
    '';
  };

  age.secrets.nextcloudAdminPass = {
    rekeyFile = ../servers/${node.name}/secrets/nextcloud_admin_pass.age;
    generator.script = "passphrase";
  };

  age.secrets.cloudflares3SecretKey = {
    rekeyFile = ../servers/${node.name}/secrets/cloudflares3_secret_key.age;
    generator.script = "passphrase";
  };
}
