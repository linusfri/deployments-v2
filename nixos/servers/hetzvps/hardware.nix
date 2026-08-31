{ modulesPath, ... }:
{
  # Real hardware/network facts for the running hetzvps server, carried over
  # verbatim from the old deployments repo. Do not regenerate/guess these.
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking.useNetworkd = true;

  systemd.network.networks."10-wan" = {
    matchConfig.MACAddress = "92:00:06:ae:79:11";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
    };
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1949-8C0B";
    fsType = "vfat";
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
}
