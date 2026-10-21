# Everyone listed here can decrypt every repo secret. Secrets are encrypted to
# all of these keys; you decrypt with your own private key via $AGE_IDENTITY
# (.envrc picks the ~/.ssh key whose .pub matches an entry below).
# After changing this list, run `tofuage update-masterkeys` and re-encrypt the
# token bundle (see README).
# Format must be exactly "<type> <base64>" (no comment).
let
  # Break-glass backup: secrets/rekeyed/master.age (passphrase protected age key).
  # Never remove it, see README.
  masterPubkey = "age1d7x5yu2cw6rx7pcmv5u4v37lcs0dpzztshyczlfuc6z38j6a3dks3mlar6";

  people = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY" # linus
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzhVNFL+zJsluU3b8lIh2QvgqZ4PGS7O/kPkb5fN/UT6CCY/So78NSrPEB/GlUw+fGzNwxDCB54ylJDKQ+65nZ4qfROcTbpzVphS7Dv2wR+8pIc4cmsn9xMAJGLG0BRE7iE+4ar3FNzPhgKf9YGb/dwNso9lxufT0ssMT5tISj1Rwn+Welu5tqAHwfIBnoBRKgEQ9vYlwInzTtRSkfaS66JZw3vw8G0D7UI6AehwT3/b3rajI1kaIUe8MzDikqC/1ngkXtcA8WYJ3e9JNq9rnjx39AIQGipgaxF2a2MvOa4VSxzOBGYO5HUFB5Z7PQkCw01e1cxMG7rwu7EPTR/LtrUJRUFtC9nFnV1Fj9cTtIq8Jr8AUiCkC3FVcI0AXELuMMzkLwXlCf8839Qz2alTawzowRzT5+rQyqcSJkw0yr6G3UPqvydd7xbF6ZeImrmP+PfdZXmkZmbCa88x0u47awY8Hpv74zPyK+wFbNH7yP/PN+aW14QFTMEdQsxIoEt8cDJC1VdSclA2ZnFnbHdZQFcFRHWwcbv6N0ZrOoPjGxcZ+OgYbXHxDHx3XmL+6Y2R/Hsx1fZv06b0xuQ0v4fDjMJJYTy66Onq4P85nq/qh5DQ4EJgTKzUC5Lq0fDMX3MglfryZe7Wk4NbSpW5XsWpi5s7OK9iSBZOO5UdEGK+ns/w==" # linus @ worklaptop
  ];
in
{
  # A single decryption identity: whatever key $AGE_IDENTITY points to.
  masterIdentities = [
    {
      identity = "\"$AGE_IDENTITY\"";
      pubkey = masterPubkey;
    }
  ];
  # Secrets are encrypted to masterPubkey plus everyone in `people`.
  extraEncryptionPubkeys = people;
}