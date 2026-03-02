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
  rofiTheme = ''
    window {
      background: #1e1e2f;
      color: #cba6f7;
      border: { color: #6c71c4; width: 2px; };  
      radius: 6px;
      padding: 5px 10px;
    }

    inputbar {
      background: #262635;
      text-color: #89b4fa;
      cursor: #89b4fa;
    }

    listview {
      lines: 10;
      fixed-height: 0;
    }

    element {
      background: transparent;
      selected {
        background: #6c71c4;
        text-color: #1e1e2f;
      }
    }

    scrollbar {
      width: 8px;
      handle-color: #6c71c4;
      bar-color: #2a2a3b;
      radius: 4px;
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
    brave  # Web browser
    alacritty  # Terminal emulator
    fastfetch # For the funny ascii system info in the terminal
    dropbox # Dropbox client
    mako # Notification daemon
    vencord # Discord client with Vencord mod support

    # theming packages
    adapta-gtk-theme        # GTK theme close to our Waybar/Mako palette
    qt5.qt5ct               # Qt theme configuration tool
    qt5.qtstyleplugins      # provide good fallback styles for Qt5
    kvantum                 # engine for Qt themes (Adapta available)
  ];

  # Optional: Configure Dropbox as a systemd user service
  systemd.user.services.dropbox = {
    Unit = {
      Description = "Dropbox service";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      Restart = "on-failure";
    };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-python.python
      ms-vscode.cpptools
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      jnoortheen.nix-ide
    ];
  };

  # session environment for theming
  home.sessionVariables = {
    GTK_THEME = "Adapta-Nokto";           # use dark/purple GTK theme
    QT_QPA_PLATFORMTHEME = "qt5ct";       # tell Qt to use qt5ct for styling
  };

  # Qt5 configuration utility
  qt.qt5ctSettings = {
    enable = true;
    settings = {
      style = "Adapta-Nokto";            # pick the matching style
      iconTheme = "Papirus";              # optional icon theme
    };
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

  # Optional: Configure Rofi (custom Avali‑style theme)
  programs.rofi = {
    enable = true;
    theme = rofiTheme;
  };

  # Mako notification theme matching Waybar/Avali UI
  services.mako = {
    enable = true;
    extraConfig = ''
      * {
        font-family: "Roboto Mono", monospace;
        font-size: 12px;
        color: #cba6f7;
        background-color: #1e1e2f;
        border: 1px solid #6c71c4;
        border-radius: 4px;
        padding: 8px;
      }

      notification {
        margin: 4px;
      }

      .title {
        font-weight: bold;
        color: #89b4fa;
      }

      .body {
        color: #cba6f7;
      }

      /* icon color matches bar accent */
      .icon {
        margin-right: 6px;
        color: #f5c2e7;
      }
    '';
  };

  # Waybar config files
  home.file.".config/waybar/config" = {
    text = waybarConfig;
  };
  home.file.".config/waybar/style.css" = {
    text = waybarStyle;
  };

  # Zsh configuration with fastfetch and quality-of-life features
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    };
    initExtra = ''
      # Show system info on terminal open
      fastfetch

      # Set a nice prompt
      PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '

      # History settings
      HISTSIZE=5000
      SAVEHIST=5000
      HISTFILE=~/.zsh_history
      setopt inc_append_history
      setopt share_history
      setopt hist_ignore_dups
      setopt hist_reduce_blanks

      # Enable mouse support in terminal
      bindkey -v
    '';
  };
}