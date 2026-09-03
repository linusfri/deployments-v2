{
  lib,
  config,
  node,
  ...
}:
let
  cfg = config.services.dbBackup;
in
{
  # Declare a job with: services.dbBackup.<name> = { dumpCommand = ...; };
  # `<name>` is used as both the borgbackup job name and the storage box repo name.
  options.services.dbBackup = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.dumpCommand = lib.mkOption {
          type = lib.types.path;
          description = "Program whose stdout is piped into `borg create` for this backup job.";
        };
      }
    );
    default = { };
    description = ''
      Database backups shipped off-server via
      borgbackup, one job per attribute name.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    services.borgbackup.jobs = lib.mapAttrs (backupName: backupCfg: {
      inherit (backupCfg) dumpCommand;

      repo = "ssh://${node.storagebox.username}@${node.storagebox.server}:23/./${backupName}";

      encryption.mode = "none";

      environment.BORG_RSH = "ssh -i ${config.age.secrets.backupSshKey.path} -o UserKnownHostsFile=/root/.cache/borg/known_hosts -o StrictHostKeyChecking=accept-new";

      compression = "auto,zstd";
      startAt = "03:30";
      persistentTimer = true;

      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
    }) cfg;

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
  };
}
