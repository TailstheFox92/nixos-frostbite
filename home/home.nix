{ config, pkgs, ... }:

let
  waybarConfig = ''
    {
      "layer": "top",
      "position": "top",
      "height": 28,
      "modules-left": ["workspaces"],
      "modules-center": ["clock"],
      "modules-right": ["network", "battery", "custom/cpu"],
      "workspaces": {
        "disable-scroll": true
      },
      "clock": {
        "format": "{:%Y-%m-%d %H:%M}"
      },
      "network": {
        "format-online": " {essid} ({ip})",
        "format-offline": " offline"
      },
      "battery": {
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-full": ""
      },
      "custom/cpu": {
        "format": "CPU {usage}%",
        "exec": "grep -m1 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print usage}'"
      }
    }
  '';
  waybarStyle = ''
    /* Avali‑style dark purple / blue theme */

    * {
      font-family: "Roboto Mono", monospace;
      font-size: 12px;
      color: #cba6f7;
      background: #1e1e2f;
    }

    /* modules panels */
    #workspaces button,
    #workspaces button.active {
      background: transparent;
      border: 1px solid #6c71c4;
      padding: 2px 6px;
      margin: 0 2px;
      border-radius: 3px;
    }

    #clock {
      color: #89b4fa;
    }

    #network,
    #battery,
    #custom-cpu {
      margin-left: 8px;
    }

    /* icons */
    .icon {
      margin-right: 4px;
      color: #f5c2e7;
    }
  '';
in
{
  # Home Manager version
  home.stateVersion = "24.05";

  # Install user packages
  home.packages = with pkgs; [
    rofi  # Application launcher
    thunar  # File manager
    waterfox-bin  # Web browser (use waterfox-bin for binary package if needed)
    alacritty  # Terminal emulator
    fastfetch # For the funny ascii system info in the terminal
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-python.python
      ms-vscode.cpptools
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
    ];
  };

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

  # Waybar config files
  home.file.".config/waybar/config" = {
    text = waybarConfig;
  };
  home.file.".config/waybar/style.css" = {
    text = waybarStyle;
  };
}