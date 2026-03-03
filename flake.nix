{
  description = "Frostbite: NixOS configuration with Sway, Home Manager, and Avali-style UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixos-generators removed; use upstream image builder
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
          # Add the graphical ISO module for isoImage support
          { imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix" ]; }
          # Manual text-based installer service for Frostbite
          ({ config, pkgs, ... }: {
            systemd.services.manual-install = {
              description = "Manual text-based NixOS install for Frostbite";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              requires = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                StandardOutput = "journal";
                StandardError = "journal";
              };
              path = with pkgs; [ util-linux e2fsprogs dosfstools parted ];
              script = ''
                echo "\n[*] Welcome to the Frostbite manual installer!"
                echo "[*] To install, run the following commands as root:"
                echo ""
                echo "  parted /dev/sda mklabel gpt"
                echo "  parted /dev/sda mkpart ESP fat32 1MiB 1GiB"
                echo "  parted /dev/sda set 1 esp on"
                echo "  parted /dev/sda mkpart primary ext4 1GiB 100%"
                echo "  mkfs.fat -F 32 /dev/sda1"
                echo "  mkfs.ext4 -F /dev/sda2"
                echo "  mount /dev/sda2 /mnt"
                echo "  mkdir -p /mnt/boot"
                echo "  mount /dev/sda1 /mnt/boot"
                echo "  nixos-install --flake /etc/nixos#Frostbite --no-root-password"
                echo ""
                echo "[*] After install, reboot manually."
                echo "[*] You can edit /etc/nixos/configuration.nix before running nixos-install if needed."
                echo "[*] For help, see: https://nixos.org/manual"
              '';
            };
          })
        ];
      };
    };

    packages.x86_64-linux.iso = self.nixosConfigurations.Frostbite.config.system.build.isoImage;
  };
}