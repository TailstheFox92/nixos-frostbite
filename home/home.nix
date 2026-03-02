{ config, pkgs, ... }:

{
  # Home Manager version
  home.stateVersion = "24.05";

  # Install user packages
  home.packages = with pkgs; [
    rofi  # Application launcher
    thunar  # File manager
    waterfox-bin  # Web browser (use waterfox-bin for binary package if needed)
    alacritty  # Terminal emulator
  ];

  # Basic Sway configuration
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";  # Super key
      terminal = "alacritty";
      menu = "rofi -show drun";  # Use Rofi as app launcher

      # Keybindings (basic examples)
      keybindings = pkgs.lib.mkOptionDefault {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+d" = "exec ${menu}";
        "${modifier}+e" = "exec thunar";  # Launch Thunar
        "${modifier}+w" = "exec waterfox";  # Launch Waterfox
        "${modifier}+Shift+q" = "kill";  # Close window
      };

      # Bars (using Waybar as an example)
      bars = [{
        command = "${pkgs.waybar}/bin/waybar";
      }];

      # Input/output settings (adjust for your hardware)
      input = {
        "*" = {
          xkb_layout = "us";
        };
      };
    };
    extraConfig = ''
      # Additional Sway config options here
      default_border pixel 2
      gaps inner 5
    '';
  };

  # Optional: Configure Alacritty (basic example)
  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 12.0;
      window.opacity = 0.9;
    };
  };

  # Optional: Configure Rofi (basic theme)
  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
  };
}