{ config, pkgs, lib, ... }:

{
  imports = [
    ./cyclone-hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernel.sysctl = {
    # Lower latency + better throughput behavior for wireless PCVR streaming.
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.core.rmem_default" = 262144;
    "net.core.wmem_default" = 262144;
  };

  networking.hostName = "Cyclone";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.hosts."127.0.0.1" = [ "searx.home.arpa" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.polkit.enable = true;
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
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      libxml2
      libGL
      libdrm
      mesa
      vulkan-loader
      systemd
      alsa-lib
      pulseaudio
      gtk3
      gdk-pixbuf
      pango
      cairo
      atk
      at-spi2-atk
      fontconfig
      freetype
      dbus
      glib
      nss
      nspr
      libxkbcommon
      wayland
      libx11
      libxext
      libxcursor
      libxi
      libxinerama
      libxrandr
      libxrender
    ];
  };
  programs.firefox.enable = false;

  services.flatpak = {
    enable = true;
    packages = [
      "org.vinegarhq.Sober"
    ];
  };

  services.searx = {
    enable = true;
    redisCreateLocally = true;
    configureNginx = true;
    domain = "searx.home.arpa";
    settings = {
      server = {
        bind_address = "127.0.0.1";
        port = 8080;
        secret_key = "JvwMNKUmen*wL3M[";
        limiter = true;
        image_proxy = true;
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.${config.services.searx.domain} = {
      serverAliases = [ "cyclone.local" "searx.local" ];
      locations."/".extraConfig = ''
        allow 127.0.0.1;
        allow ::1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        allow fc00::/7;
        allow fe80::/10;
        deny all;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  programs.alvr = {
    enable = true;
    openFirewall = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extraPackages = with pkgs; [
      libva
      libdrm
      mesa
      libsForQt5.qt5.qtbase
      libsForQt5.qt5.qtmultimedia
      libsForQt5.qt5.qtwayland
    ];
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
    android-tools
    libva-utils
  ];

  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "24.05";
}
