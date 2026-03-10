{ config, pkgs, lib, ... }:

{
  imports = [
    ./cyclone-hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "kvm-amd" ];

  networking.hostName = "Cyclone";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      vulkan-tools
      vulkan-validation-layers
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.gfernandez = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  programs.firefox.enable = false;

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.defaultSession = "hyprland";
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "none";
      full_color = true;
      bg = "0x001e1e2e";
      border_fg = "0x00cba6f7";
      error_bg = "0x001e1e2e";
      error_fg = "0x01f38ba8";
      fg = "0x00cdd6f4";
      input_bg = "0x001e1e2e";
      input_fg = "0x00f9e2af";
      msg_bg = "0x001e1e2e";
      msg_fg = "0x00a6e3a1";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  environment.systemPackages = with pkgs; [
    git
    foot
    rofi
    calamares
    mangohud
  ];

  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "24.05";
}
