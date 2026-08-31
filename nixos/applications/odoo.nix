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

  # Daily encrypted backup of the odoo postgres database, shipped off-server
  # to the Hetzner storage box defined in infrastructure/friikod/server.tf.
  services.borgbackup.jobs.odoo-postgres = {
    dumpCommand = pkgs.writeShellScript "dump-odoo-db" ''
      exec ${pkgs.util-linux}/bin/runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dump --dbname=odoo
    '';

    repo = "ssh://${node.storagebox.username}@${node.storagebox.server}:23/./odoo-postgres";

    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.odooBorgPassphrase.path}";
    };

    environment.BORG_RSH = "ssh -i ${config.age.secrets.backupSshKey.path} -o UserKnownHostsFile=/root/.cache/borg/known_hosts -o StrictHostKeyChecking=accept-new";

    compression = "auto,zstd";
    startAt = "03:30";
    persistentTimer = true;

    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
  };

  age.secrets.odooBorgPassphrase = {
    rekeyFile = ../servers/${node.name}/secrets/odoo_borg_passphrase.age;
    generator.script = "passphrase";
  };

  # Generates a dedicated ed25519 keypair for authenticating to the storage
  # box. Shared across any backup jobs targeting the same storage box, so
  # it's named generically rather than per-app. The private key ends up in
  # the .age file (rekeyed for the host as usual); the public key is written
  # in plaintext right next to it as
  # nixos/servers/${node.name}/secrets/backup_ssh_key.pub after running
  # `agenix generate`. Add that public key to the storage box's authorized
  # keys (e.g. hcloud_storage_box.backups.ssh_keys in terraform).
  age.generators.ssh-ed25519-with-pub =
    {
      pkgs,
      lib,
      file,
      name,
      ...
    }:
    ''
      key=$(mktemp)
      trap 'rm -f "$key" "$key.pub"' EXIT
      ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C ${lib.escapeShellArg name} -f "$key" <<< y >/dev/null
      cp "$key.pub" ${lib.escapeShellArg (lib.removeSuffix ".age" file + ".pub")}
      cat "$key"
    '';

  age.secrets.backupSshKey = {
    rekeyFile = ../servers/${node.name}/secrets/backup_ssh_key.age;
    generator.script = "ssh-ed25519-with-pub";
  };
}
