{ config, pkgs, ... }:

let
  waybarWeather = pkgs.writeShellScriptBin "waybar-weather" ''
    weather="$(${pkgs.curl}/bin/curl -s --max-time 5 'https://wttr.in/?format=%c+%t')"
    if [ -n "$weather" ]; then
      echo " $weather"
    else
      echo " n/a"
    fi
  '';
  waybarConfig = ''
    {
      "layer": "top",
      "position": "top",
      "height": 28,
      "modules-left": ["sway/workspaces"],
      "modules-center": ["clock"],
      "modules-right": ["custom/weather", "cpu", "memory", "temperature", "network", "battery", "tray"],
      "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
      },
      "custom/weather": {
        "format": "{}",
        "interval": 600,
        "exec": "${waybarWeather}/bin/waybar-weather",
        "tooltip": false
      },
      "cpu": {
        "format": " {usage}%",
        "interval": 2
      },
      "memory": {
        "format": " {}%",
        "interval": 2
      },
      "temperature": {
        "critical-threshold": 85,
        "format": " {temperatureC}°C",
        "format-critical": " {temperatureC}°C"
      },
      "clock": {
        "format": "{:%Y-%m-%d %H:%M}"
      },
      "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ifname}",
        "format-disconnected": " offline"
      },
      "battery": {
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-full": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
      },
      "tray": {
        "spacing": 8
      }
    }
  '';
  waybarStyle = ''
    /* Avali‑style dark purple / blue theme */

    * {
      font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", "Font Awesome 6 Brands", monospace;
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

    #custom-weather,
    #cpu,
    #memory,
    #temperature,
    #network,
    #battery,
    #tray {
      margin-left: 8px;
    }

    /* icons */
    .icon {
      margin-right: 4px;
      color: #f5c2e7;
    }
  '';
  rofiTheme = builtins.toFile "rofi-theme.rasi" ''
    * {
      background-color: #1e1e2f;
      text-color: #cba6f7;
      font: "JetBrainsMono Nerd Font 12";
      border: 2px;
      border-color: #6c71c4;
      border-radius: 6px;
    }

    window {
      background-color: #1e1e2f;
      border: 2px;
      border-color: #6c71c4;
      border-radius: 6px;
      padding: 5px;
    }

    inputbar {
      background-color: #262635;
      text-color: #89b4fa;
      cursor: #89b4fa;
      border: 0px;
      padding: 8px;
    }

    listview {
      lines: 10;
      fixed-height: false;
      spacing: 4px;
    }

    element {
      background-color: transparent;
      text-color: #cba6f7;
      border-radius: 3px;
      padding: 2px;
    }
    element selected {
      background-color: #6c71c4;
      text-color: #1e1e2f;
    }

    scrollbar {
      width: 8px;
      handle-color: #6c71c4;
    }
  '';
  rofiDebugLauncher = pkgs.writeShellScriptBin "rofi-debug-launcher" ''
    #!/usr/bin/env sh
    log_dir="$HOME/.local/state/rofi"
    log_file="$log_dir/launcher.log"

    mkdir -p "$log_dir"
    {
      printf '\n[%s] Launching rofi\n' "$(date -Is)"
      rofi -show drun "$@"
      status=$?
      printf '[%s] Exit code: %s\n' "$(date -Is)" "$status"
      exit "$status"
    } >>"$log_file" 2>&1
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
    papirus-icon-theme
    bibata-cursors
    libsForQt5.qt5ct               # Qt theme configuration tool
  ];

  gtk = {
    enable = true;
    theme = {
      package = pkgs.adapta-gtk-theme;
      name = "Adapta-Nokto";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

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
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        jnoortheen.nix-ide
        vscodevim.vim
      ];
      userSettings = {
        "editor.fontFamily" = "JetBrainsMono Nerd Font, 'Droid Sans Mono', monospace";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      };
    };
  };

  # session environment for theming
  home.sessionVariables = {
    GTK_THEME = "Adapta-Nokto";           # use dark/purple GTK theme
    QT_QPA_PLATFORMTHEME = "qt5ct";       # tell Qt to use qt5ct for styling
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Qt5 configuration utility
  qt.qt5ctSettings = {
    enable = true;
    settings = {
      style = "Adapta-Nokto";            # pick the matching style
      iconTheme = "Papirus-Dark";
    };
  };

  # Basic Sway configuration
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";  # Super key
      terminal = "alacritty";
      menu = "${rofiDebugLauncher}/bin/rofi-debug-launcher";  # Use Rofi launcher with debug logging

      # Keybindings (basic examples)
      keybindings = pkgs.lib.mkOptionDefault {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+d" = "exec ${menu}";
        "${modifier}+e" = "exec thunar";  # Launch Thunar
        "${modifier}+w" = "exec brave";  # Launch Brave
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
        font-family: "JetBrainsMono Nerd Font", monospace;
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
  home.file.".config/fastfetch/logo.txt" = {
    text = ''
                                 #           
                               ###           
                              ####           
                            ######           
                           #######           
                          #######            
                         #######             
              ######## -#######      ###     
           ####        ########   #####+     
         ###          ########  #######      
        ###          #######. ########       
       ##           ####### ########         
      .##          ###### #########          
      ##           #### #########            
      ##          #### ########. #           
      ##         +### ########    ######     
       ##        ### #####   #########       
       ###       # ####  ##########          
        ###     # ##   #########             
          ###    -  #########                
            ##    #       ##                 
                  ######-                    
    '';
  };
  home.file.".config/fastfetch/config.jsonc" = {
    text = ''
      {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
        "logo": {
          "type": "file",
          "source": "~/.config/fastfetch/logo.txt",
          "color": {
            "1": "38;5;208"
          },
          "printRemaining": true,
          "position": "left"
        },
        "modules": [
          "title",
          "separator",
          "os",
          "host",
          "kernel",
          "uptime",
          "packages",
          "shell",
          "display",
          "de",
          "wm",
          "wmtheme",
          "theme",
          "icons",
          "font",
          "cursor",
          "terminal",
          "terminalfont",
          "cpu",
          "gpu",
          "memory",
          "swap",
          "disk",
          "localip",
          "battery",
          "poweradapter",
          "locale",
          "break",
          "colors"
        ]
      }
    '';
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
    initContent = ''
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