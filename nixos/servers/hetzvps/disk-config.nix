{ ... }:
{
  # This host predates disko: it was never partitioned/installed through it,
  # and its real partitions (declared as plain `fileSystems` entries) live in
  # ./hardware.nix instead. Keep this module a no-op so the generic
  # `disko.nixosModules.disko` import in flake.nix doesn't generate
  # `fileSystems`/bootloader config that conflicts with (or overwrites) the
  # real, already-partitioned disk on this server.
}
