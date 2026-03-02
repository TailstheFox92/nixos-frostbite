{
  description = "Frostbite: NixOS configuration with Sway, Home Manager, and Avali-style UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-generators, ... }@inputs: {
    nixosConfigurations = {
      Frostbite = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.qu1ck51lv3r = import ./home/home.nix;
          }
        ];
      };
    };

    packages = {
      x86_64-linux.iso = nixos-generators.nixosGenerate {
        inherit (nixpkgs) lib;
        system = "x86_64-linux";
        format = "iso";
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.qu1ck51lv3r = import ./home/home.nix;
          }
          # Auto-install configuration for unattended installation
          ({ config, pkgs, ... }: {
            systemd.services.auto-install = {
              description = "Auto-install Frostbite to /dev/sda";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                StandardOutput = "journal";
                StandardError = "journal";
              };
              path = with pkgs; [ util-linux e2fsprogs dosfstools parted ];
              script = ''
                set -e
                
                TARGET_DISK="/dev/sda"
                EFI_SIZE="1G"
                
                echo "[*] Starting Frostbite auto-installation to $TARGET_DISK"
                
                # Check if disk exists
                if [ ! -e "$TARGET_DISK" ]; then
                  echo "[!] Error: $TARGET_DISK not found" >&2
                  exit 1
                fi
                
                # Wipe partition table
                echo "[*] Wiping disk and creating GPT partition table..."
                parted -s "$TARGET_DISK" mklabel gpt
                
                # Create EFI partition (1GB)
                echo "[*] Creating 1GB EFI partition..."
                parted -s "$TARGET_DISK" mkpart ESP fat32 1MiB $EFI_SIZE
                parted -s "$TARGET_DISK" set 1 esp on
                
                # Create root partition (rest of disk)
                echo "[*] Creating root partition with remaining space..."
                parted -s "$TARGET_DISK" mkpart primary ext4 $EFI_SIZE 100%
                
                # Wait for device nodes
                sleep 2
                udevadm settle
                
                # Format partitions
                echo "[*] Formatting EFI partition..."
                mkfs.fat -F 32 "$TARGET_DISK"1
                
                echo "[*] Formatting root partition..."
                mkfs.ext4 -F "$TARGET_DISK"2
                
                # Mount filesystems
                echo "[*] Mounting filesystems..."
                mkdir -p /mnt /mnt/boot
                mount "$TARGET_DISK"2 /mnt
                mount "$TARGET_DISK"1 /mnt/boot
                
                # Run NixOS installation
                echo "[*] Running nixos-install..."
                nixos-install --flake /etc/nixos#Frostbite --no-root-password
                
                echo "[*] Installation complete!"
                echo "[*] Rebooting in 10 seconds..."
                sleep 10
                reboot
              '';
            };
          })
        ];
      };
    };
  };
}