{ ... }:

{
  # Placeholder hardware config for Snowflake.
  # Replace this file with one generated on the target laptop:
  #   sudo nixos-generate-config
  #   sudo cp /etc/nixos/hardware-configuration.nix ./nixos/snowflake-hardware-configuration.nix

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];
}
