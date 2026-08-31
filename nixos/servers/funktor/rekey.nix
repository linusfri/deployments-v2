{ config, ... }:
let
  root = ../../..;
in
{
  age.rekey = {
    hostPubkey = ./ssh-host-key.pub;
    masterIdentities = import (root + /secrets/master-identity.nix);
    storageMode = "local";
    localStorageDir = root + "/secrets/rekeyed/${config.networking.hostName}";
  };
}
