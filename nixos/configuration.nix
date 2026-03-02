{ config, pkgs, lib, ... }:

{
  imports = [
    #./hardware-configuration.nix
  ];

  # Bootloader and kernel settings (minimal example)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking (enable as needed)
  networking.hostName = "Frostbite";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "America/New_York";  # Adjust based on your location
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable sound and graphics
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User configuration
  users.users.qu1ck51lv3r = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;  # Optional: Use Zsh or adjust to your preference
  };

  programs.zsh.enable = true;  # Enable Zsh for the user

  nixpkgs.config.allowUnfree = true;  # Allow unfree packages (for VSCode, etc.)

  # Enable Sway and Wayland support
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;  # Enable GTK theme support
    extraPackages = with pkgs; [
      swaylock  # For screen locking
      swayidle  # For idle management
      wl-clipboard  # Wayland clipboard utilities
      waybar  # Optional status bar (configurable in Home Manager)
    ];
  };

  # Display manager (GDM for Wayland/Sway support)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Fonts (basic set for better UI)
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  # System packages (minimal; most user apps via Home Manager)
  environment.systemPackages = with pkgs; [
    git  # For managing your config repository
  ];

  # Nix settings
  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
  };

  system.stateVersion = "24.05";  # Adjust based on your NixOS version
}