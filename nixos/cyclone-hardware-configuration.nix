{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4d12f4a6-3664-44f3-b2f7-433411663f86";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DD0C-9E32";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/25d3d553-e808-44ef-86e8-3dff4f7d25ae";
    fsType = "ext4";
  };

  fileSystems."/mnt/games2" = {
    device = "/dev/disk/by-uuid/c54def54-721e-469b-ad0d-110583c6ef3b";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/007e82e3-bf56-431d-affe-55e1fa1f4f78"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
