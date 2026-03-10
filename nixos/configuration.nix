{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader and kernel settings (minimal example)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "elan_i2c" ];
  boot.kernelModules = [ "i2c_hid_acpi" "hid_multitouch" ];

  # Networking (enable as needed)
  networking.hostName = "Frostbite";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "America/New_York";  # Adjust based on your location
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable sound and graphics
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
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
  programs.firefox.enable = false;

  nixpkgs.config.allowUnfree = true;  # Allow unfree packages (for VSCode, etc.)

  # Enable Sway and Wayland support
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;  # Enable GTK theme support
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
    ];
  };

  # Display manager (Ly TUI greeter with Gruvbox styling)
  services.displayManager.defaultSession = "sway";

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "none";
      full_color = true;
      bg = "0x00282828";
      border_fg = "0x00d65d0e";
      error_bg = "0x00282828";
      error_fg = "0x01fb4934";
      fg = "0x00ebdbb2";
      input_bg = "0x00282828";
      input_fg = "0x00fabd2f";
      msg_bg = "0x00282828";
      msg_fg = "0x00b8bb26";
    };
  };

  # Fonts (basic set for better UI)
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  # System packages (minimal; most user apps via Home Manager)
  # Add terminal and launcher to live environment for Calamares
  environment.systemPackages = with pkgs; [
    git # For managing your config repository
    foot  # Terminal emulator for live environment
    rofi       # Application launcher for live environment
    calamares  # Ensure Calamares is available in $PATH
  ];

  # Nix settings
  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
  };

  system.stateVersion = "24.05";  # Adjust based on your NixOS version
}