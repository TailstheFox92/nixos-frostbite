{
  description = "Sample NixOS configuration with Sway and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      yourhostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";  # Adjust for your architecture, e.g., "aarch64-linux"
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.yourusername = import ./home/home.nix;
          }
        ];
      };
    };
  };
}