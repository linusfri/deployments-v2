{ config, ... }:
let
  root = ../../..;
in
{
  age.rekey = {
    hostPubkey = ./ssh-host-key.pub;
    inherit (import (root + /secrets/master-identity.nix)) masterIdentities extraEncryptionPubkeys;
    storageMode = "local";
    localStorageDir = root + "/secrets/rekeyed/${config.networking.hostName}";
  };
}
