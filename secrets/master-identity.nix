[
  {
    # agenix-rekey takes `identity` unescaped into its own generated bash
    # script, so this command substitution is executed by bash at actual
    # rekey/decrypt time (not by Nix). unlock-master-identity decrypts to /tmp and then removes on shell exit.
    # This is to not have to reenter password ad infinitum in same shell instance.
    identity = "\"$(unlock-master-identity)\"";
    pubkey = "age1d7x5yu2cw6rx7pcmv5u4v37lcs0dpzztshyczlfuc6z38j6a3dks3mlar6"; # Specify the public key explicitly
  }
]