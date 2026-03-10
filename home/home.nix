{ config, pkgs, lib, ... }:

let
  wallpaperPath = "${config.home.homeDirectory}/.local/share/backgrounds/default-wallpaper.png";
  lockScreen = pkgs.writeShellScriptBin "lock-screen" ''
    #!/usr/bin/env sh
    exec ${pkgs.swaylock}/bin/swaylock -f -i ${wallpaperPath} -s fill
  '';
  screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
    #!/usr/bin/env sh
    set -eu

    dir="$HOME/Pictures/Screenshots"
    ts="$(date +"%Y-%m-%d_%H-%M-%S")"
    file="$dir/$ts.png"

    mkdir -p "$dir"
    ${pkgs.grim}/bin/grim "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
    ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
  '';
  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region" ''
    #!/usr/bin/env sh
    set -eu

    dir="$HOME/Pictures/Screenshots"
    ts="$(date +"%Y-%m-%d_%H-%M-%S")"
    file="$dir/$ts.png"

    mkdir -p "$dir"
    geometry="$(${pkgs.slurp}/bin/slurp)"
    [ -n "$geometry" ] || exit 0

    ${pkgs.grim}/bin/grim -g "$geometry" "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
    ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
  '';
  screenshotRegionEdit = pkgs.writeShellScriptBin "screenshot-region-edit" ''
    #!/usr/bin/env sh
    set -eu

    dir="$HOME/Pictures/Screenshots"
    ts="$(date +"%Y-%m-%d_%H-%M-%S")"
    file="$dir/$ts.png"

    mkdir -p "$dir"
    geometry="$(${pkgs.slurp}/bin/slurp)"
    [ -n "$geometry" ] || exit 0

    ${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.swappy}/bin/swappy -f - -o "$file"
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
    ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
  '';
  waybarWeather = pkgs.writeShellScriptBin "waybar-weather" ''
    weather="$(${pkgs.curl}/bin/curl -fsS --max-time 6 'https://wttr.in/?format=%c+%f' 2>/dev/null || true)"
    if [ -n "$weather" ]; then
      echo " $weather"
      exit 0
    fi

    geo="$(${pkgs.curl}/bin/curl -fsS --max-time 6 'https://ipapi.co/json/' 2>/dev/null || true)"
    lat="$(printf '%s' "$geo" | ${pkgs.jq}/bin/jq -r '.latitude // empty')"
    lon="$(printf '%s' "$geo" | ${pkgs.jq}/bin/jq -r '.longitude // empty')"

    if [ -n "$lat" ] && [ -n "$lon" ]; then
      met="$(${pkgs.curl}/bin/curl -fsS --max-time 10 -A 'waybar-weather/1.0 (nixos-frostbite)' "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$lat&lon=$lon" 2>/dev/null || true)"
      if [ -n "$met" ]; then
        temp="$(printf '%s' "$met" | ${pkgs.jq}/bin/jq -r '.properties.timeseries[0].data.instant.details.air_temperature // empty')"
        symbol="$(printf '%s' "$met" | ${pkgs.jq}/bin/jq -r '.properties.timeseries[0].data.next_1_hours.summary.symbol_code // .properties.timeseries[0].data.next_6_hours.summary.symbol_code // empty')"

        if [ -n "$temp" ]; then
          temp_round="$(printf '%s\n' "$temp" | ${pkgs.gawk}/bin/awk '{printf "%.0f", (($1 * 9) / 5) + 32}')"
          icon=""
          case "$symbol" in
            *clearsky*|*fair*) icon="" ;;
            *partlycloudy*) icon="" ;;
            *cloudy*) icon="" ;;
            *rain*|*drizzle*) icon="󰖖" ;;
            *sleet*|*snow*) icon="" ;;
            *thunder*) icon="" ;;
          esac
          echo "$icon ''${temp_round}°F"
          exit 0
        fi
      fi
    fi

    echo " n/a"
  '';
  volumeUpNotify = pkgs.writeShellScriptBin "volume-up-notify" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.pamixer}/bin/pamixer -i 5
    volume="$(${pkgs.pamixer}/bin/pamixer --get-volume-human)"
    ${pkgs.libnotify}/bin/notify-send -a "Volume" -u low -t 1200 "Volume" "$volume"
  '';
  volumeDownNotify = pkgs.writeShellScriptBin "volume-down-notify" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.pamixer}/bin/pamixer -d 5
    volume="$(${pkgs.pamixer}/bin/pamixer --get-volume-human)"
    ${pkgs.libnotify}/bin/notify-send -a "Volume" -u low -t 1200 "Volume" "$volume"
  '';
  volumeMuteToggleNotify = pkgs.writeShellScriptBin "volume-mute-toggle-notify" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.pamixer}/bin/pamixer -t
    if ${pkgs.pamixer}/bin/pamixer --get-mute; then
      message="Muted"
    else
      message="$(${pkgs.pamixer}/bin/pamixer --get-volume-human)"
    fi
    ${pkgs.libnotify}/bin/notify-send -a "Volume" -u low -t 1200 "Volume" "$message"
  '';
  brightnessUpNotify = pkgs.writeShellScriptBin "brightness-up-notify" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.brightnessctl}/bin/brightnessctl set +5% >/dev/null
    percent="$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.gawk}/bin/awk -F, '{print $4}')"
    ${pkgs.libnotify}/bin/notify-send -a "Brightness" -u low -t 1200 "Brightness" "$percent"
  '';
  brightnessDownNotify = pkgs.writeShellScriptBin "brightness-down-notify" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.brightnessctl}/bin/brightnessctl set 5%- >/dev/null
    percent="$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.gawk}/bin/awk -F, '{print $4}')"
    ${pkgs.libnotify}/bin/notify-send -a "Brightness" -u low -t 1200 "Brightness" "$percent"
  '';
  waybarConfig = ''
    [
      {
        "layer": "top",
        "position": "top",
        "height": 28,
        "modules-left": ["sway/workspaces"],
        "modules-center": ["clock"],
        "modules-right": ["custom/weather", "pulseaudio", "backlight", "cpu", "memory", "temperature", "network", "battery", "tray", "custom/power"],
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
        "custom/power": {
          "format": "⏻",
          "tooltip": false,
          "on-click": "${rofiPowerMenu}/bin/rofi-powermenu"
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
          "format": " {temperatureF}°F",
          "format-critical": " {temperatureF}°F"
        },
        "clock": {
          "format": "{:%Y-%m-%d %H:%M}"
        },
        "network": {
          "format-wifi": " {essid}",
          "format-ethernet": " {ifname}",
          "format-disconnected": " offline"
        },
        "pulseaudio": {
          "format": " {volume}%",
          "format-muted": "󰖁 muted",
          "on-click": "pavucontrol"
        },
        "backlight": {
          "format": " {percent}%"
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
      },
      {
        "name": "bottom-dock",
        "layer": "top",
        "position": "bottom",
        "height": 40,
        "modules-center": ["wlr/taskbar"],
        "wlr/taskbar": {
          "format": "{icon}",
          "icon-size": 20,
          "spacing": 6,
          "tooltip-format": "{title}",
          "on-click": "activate",
          "on-click-middle": "close"
        }
      }
    ]
  '';
  waybarStyle = ''
    /* Gruvbox dark/orange theme */

    * {
      font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", "Font Awesome 6 Brands", monospace;
      font-size: 12px;
      color: #ebdbb2;
      background: #282828;
    }

    /* modules panels */
    #workspaces button,
    #workspaces button.active {
      background: transparent;
      border: 1px solid #d65d0e;
      padding: 2px 6px;
      margin: 0 2px;
      border-radius: 3px;
    }

    #clock {
      color: #fabd2f;
    }

    window#waybar.bottom-dock {
      min-height: 40px;
    }

    #taskbar {
      margin: 0;
      padding: 0 8px;
    }

    #taskbar button {
      border: 1px solid #d65d0e;
      border-radius: 4px;
      padding: 4px 10px;
      margin: 4px 3px;
      background: transparent;
    }

    #taskbar button.active {
      background: #3c3836;
    }

    #custom-weather,
    #pulseaudio,
    #backlight,
    #cpu,
    #memory,
    #temperature,
    #network,
    #battery,
    #tray {
      margin-left: 8px;
    }

    #custom-power {
      margin-left: 8px;
      margin-right: 8px;
    }

    /* icons */
    .icon {
      margin-right: 4px;
      color: #fe8019;
    }
  '';
  rofiTheme = builtins.toFile "rofi-theme.rasi" ''
    * {
      background-color: #282828;
      text-color: #ebdbb2;
      font: "JetBrainsMono Nerd Font 12";
      border: 2px;
      border-color: #d65d0e;
      border-radius: 6px;
    }

    window {
      background-color: #282828;
      border: 2px;
      border-color: #d65d0e;
      border-radius: 6px;
      padding: 5px;
    }

    inputbar {
      background-color: #3c3836;
      text-color: #fabd2f;
      cursor: #fabd2f;
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
      text-color: #ebdbb2;
      border-radius: 3px;
      padding: 2px;
    }
    element selected {
      background-color: #d65d0e;
      text-color: #282828;
    }

    scrollbar {
      width: 8px;
      handle-color: #d65d0e;
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
  rofiPowerMenu = pkgs.writeShellScriptBin "rofi-powermenu" ''
    #!/usr/bin/env sh
    set -eu

    options="Lock\nLogout\nSuspend\nReboot\nShutdown"
    chosen="$(printf '%b\n' "$options" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Power")"

    case "$chosen" in
      Lock)
        exec ${lockScreen}/bin/lock-screen
        ;;
      Logout)
        exec ${pkgs.sway}/bin/swaymsg exit
        ;;
      Suspend)
        ${lockScreen}/bin/lock-screen
        exec ${pkgs.systemd}/bin/systemctl suspend
        ;;
      Reboot)
        exec ${pkgs.systemd}/bin/systemctl reboot
        ;;
      Shutdown)
        exec ${pkgs.systemd}/bin/systemctl poweroff
        ;;
      *)
        exit 0
        ;;
    esac
  '';
in
{
  # Home Manager version
  home.stateVersion = "24.05";

  # Ensure Firefox is never enabled via Home Manager
  programs.firefox.enable = false;

  # Force Brave as default browser for links and HTML content
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "application/xhtml+xml" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
    };
  };

  # Install user packages
  home.packages = with pkgs; [
    rofi  # Application launcher
    thunar  # File manager
    brave  # Web browser
    alacritty  # Terminal emulator
    fastfetch # For the funny ascii system info in the terminal
    dropbox # Dropbox client
    mako # Notification daemon
    vesktop # Discord client with Vencord pre-applied
    grim
    slurp
    swappy
    wl-clipboard
    libnotify
    pavucontrol


    # theming packages
    gruvbox-dark-gtk
    gruvbox-kvantum
    gruvbox-dark-icons-gtk
    bibata-cursors
    libsForQt5.qt5ct               # Qt theme configuration tool
    libsForQt5.qtstyleplugin-kvantum
  ];

  gtk = {
    enable = true;
    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark";
    };
    iconTheme = {
      package = pkgs.gruvbox-dark-icons-gtk;
      name = "oomox-gruvbox-dark";
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
    mutableExtensionsDir = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        jnoortheen.nix-ide
        vscodevim.vim
        jdinhlife.gruvbox
      ];
      userSettings = {
        "editor.fontFamily" = "JetBrainsMono Nerd Font, 'Droid Sans Mono', monospace";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "workbench.colorTheme" = "Gruvbox Dark Hard";
      };
    };
  };

  # session environment for theming
  home.sessionVariables = {
    BROWSER = "brave";
    GTK_THEME = "gruvbox-dark";
    QT_QPA_PLATFORMTHEME = "qt5ct";       # tell Qt to use qt5ct for styling
    QT_STYLE_OVERRIDE = "kvantum";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # Qt5 configuration utility
  qt.qt5ctSettings = {
    enable = true;
    settings = {
      style = "kvantum";
      iconTheme = "oomox-gruvbox-dark";
    };
  };

  home.file.".config/Kvantum/kvantum.kvconfig" = {
    text = ''
      [General]
      theme=Gruvbox-Dark
    '';
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${lockScreen}/bin/lock-screen";
      }
      {
        timeout = 600;
        command = ''${pkgs.sway}/bin/swaymsg "output * dpms off"'';
        resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * dpms on"'';
      }
    ];
    events = {
      before-sleep = "${lockScreen}/bin/lock-screen";
      lock = "${lockScreen}/bin/lock-screen";
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
        "${modifier}+Shift+p" = "exec ${rofiPowerMenu}/bin/rofi-powermenu";
        "${modifier}+Shift+l" = "exec ${lockScreen}/bin/lock-screen";
        "${modifier}+Shift+d" = "exec vesktop";
        "${modifier}+e" = "exec thunar";  # Launch Thunar
        "${modifier}+w" = "exec brave";  # Launch Brave
        "XF86AudioRaiseVolume" = "exec ${volumeUpNotify}/bin/volume-up-notify";
        "XF86AudioLowerVolume" = "exec ${volumeDownNotify}/bin/volume-down-notify";
        "XF86AudioMute" = "exec ${volumeMuteToggleNotify}/bin/volume-mute-toggle-notify";
        "XF86AudioMicMute" = "exec ${pkgs.pamixer}/bin/pamixer --default-source -t";
        "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl pause";
        "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        "XF86MonBrightnessUp" = "exec ${brightnessUpNotify}/bin/brightness-up-notify";
        "XF86MonBrightnessDown" = "exec ${brightnessDownNotify}/bin/brightness-down-notify";
        "Print" = "exec ${screenshotFull}/bin/screenshot-full";
        "Shift+Print" = "exec ${screenshotRegion}/bin/screenshot-region";
        "Ctrl+Print" = "exec ${screenshotRegionEdit}/bin/screenshot-region-edit";
        "${modifier}+Shift+q" = "kill";  # Close window
      };

      # Bars (using Waybar as an example)
      bars = [{
        command = "${pkgs.waybar}/bin/waybar";
      }];

      startup = [
        {
          command = "${pkgs.mako}/bin/mako";
          always = true;
        }
        {
          command = "${pkgs.swaybg}/bin/swaybg -i ${wallpaperPath} -m fill";
          always = true;
        }
      ];

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
      bindswitch --reload --locked lid:on exec ${lockScreen}/bin/lock-screen
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
    extraConfig = {
      show-icons = true;
      drun-display-format = "{icon} {name}";
    };
  };

  # Mako notification theme matching Waybar/Avali UI
  services.mako = {
    enable = true;
    extraConfig = ''
      font=JetBrainsMono Nerd Font 12
      background-color=#282828
      text-color=#ebdbb2
      border-color=#d65d0e
      border-size=1
      border-radius=4
      padding=8
      margin=4
      default-timeout=2000
 "   '';
  };

  # Waybar config files
  home.file.".local/share/backgrounds/default-wallpaper.png" = {
    source = ./assets/avali-wallpaper.png;
  };

  home.file.".config/waybar/config" = {
    text = waybarConfig;
  };
  home.file.".config/waybar/style.css" = {
    text = waybarStyle;
  };
  home.file.".config/Vencord/themes/gruvbox.theme.css" = {
    text = ''
      /**
       * @name Gruvbox Dark
       * @description Gruvbox-inspired dark theme for Discord via Vencord
       * @author qu1ck51lv3r
       * @version 1.0.0
       */

      :root {
        --bg0-hard: #1d2021;
        --bg0: #282828;
        --bg1: #3c3836;
        --bg2: #504945;
        --bg3: #665c54;
        --fg0: #fbf1c7;
        --fg1: #ebdbb2;
        --fg2: #d5c4a1;
        --orange: #fe8019;
        --yellow: #fabd2f;
        --aqua: #8ec07c;
      }

      .theme-dark,
      .theme-dark .appMount-2yBXZl,
      .theme-dark .bg-1QIAus {
        --background-primary: var(--bg0) !important;
        --background-secondary: var(--bg1) !important;
        --background-secondary-alt: var(--bg2) !important;
        --background-tertiary: var(--bg0-hard) !important;
        --background-base-low: var(--bg0-hard) !important;
        --background-base-lower: var(--bg0) !important;
        --background-base-lowest: var(--bg0-hard) !important;
        --background-surface-high: var(--bg2) !important;
        --background-surface-higher: var(--bg3) !important;
        --background-surface-highest: var(--bg3) !important;
        --background-floating: var(--bg1) !important;
        --background-modifier-hover: rgba(235, 219, 178, 0.08) !important;
        --background-modifier-active: rgba(235, 219, 178, 0.14) !important;
        --background-modifier-selected: rgba(250, 189, 47, 0.16) !important;
        --channeltextarea-background: var(--bg1) !important;
        --chat-background-default: var(--bg0) !important;
        --chat-background: var(--bg0) !important;
        --input-background: var(--bg1) !important;
        --modal-background: var(--bg0) !important;
        --modal-footer-background: var(--bg1) !important;
        --home-background: var(--bg0) !important;
        --interactive-normal: var(--fg1) !important;
        --interactive-hover: var(--yellow) !important;
        --interactive-active: var(--orange) !important;
        --text-normal: var(--fg1) !important;
        --text-primary: var(--fg1) !important;
        --text-secondary: var(--fg2) !important;
        --text-muted: #a89984 !important;
        --header-primary: var(--fg0) !important;
        --header-secondary: var(--fg1) !important;
        --brand-500: var(--orange) !important;
        --brand-560: #d65d0e !important;
        --button-filled-brand-background: var(--orange) !important;
        --button-filled-brand-background-hover: #d65d0e !important;
        --button-filled-brand-text: var(--bg0) !important;
      }

      .theme-dark a {
        color: var(--aqua) !important;
      }
    '';
  };
  home.file.".config/vesktop/themes/gruvbox.theme.css" = {
    text = ''
      /**
       * @name Gruvbox Dark
       * @description Gruvbox-inspired dark theme for Discord via Vencord
       * @author qu1ck51lv3r
       * @version 1.0.0
       */

      :root {
        --bg0-hard: #1d2021;
        --bg0: #282828;
        --bg1: #3c3836;
        --bg2: #504945;
        --bg3: #665c54;
        --fg0: #fbf1c7;
        --fg1: #ebdbb2;
        --fg2: #d5c4a1;
        --orange: #fe8019;
        --yellow: #fabd2f;
        --aqua: #8ec07c;
      }

      .theme-dark,
      .theme-dark .appMount-2yBXZl,
      .theme-dark .bg-1QIAus {
        --background-primary: var(--bg0) !important;
        --background-secondary: var(--bg1) !important;
        --background-secondary-alt: var(--bg2) !important;
        --background-tertiary: var(--bg0-hard) !important;
        --background-base-low: var(--bg0-hard) !important;
        --background-base-lower: var(--bg0) !important;
        --background-base-lowest: var(--bg0-hard) !important;
        --background-surface-high: var(--bg2) !important;
        --background-surface-higher: var(--bg3) !important;
        --background-surface-highest: var(--bg3) !important;
        --background-floating: var(--bg1) !important;
        --background-modifier-hover: rgba(235, 219, 178, 0.08) !important;
        --background-modifier-active: rgba(235, 219, 178, 0.14) !important;
        --background-modifier-selected: rgba(250, 189, 47, 0.16) !important;
        --channeltextarea-background: var(--bg1) !important;
        --chat-background-default: var(--bg0) !important;
        --chat-background: var(--bg0) !important;
        --input-background: var(--bg1) !important;
        --modal-background: var(--bg0) !important;
        --modal-footer-background: var(--bg1) !important;
        --home-background: var(--bg0) !important;
        --interactive-normal: var(--fg1) !important;
        --interactive-hover: var(--yellow) !important;
        --interactive-active: var(--orange) !important;
        --text-normal: var(--fg1) !important;
        --text-primary: var(--fg1) !important;
        --text-secondary: var(--fg2) !important;
        --text-muted: #a89984 !important;
        --header-primary: var(--fg0) !important;
        --header-secondary: var(--fg1) !important;
        --brand-500: var(--orange) !important;
        --brand-560: #d65d0e !important;
        --button-filled-brand-background: var(--orange) !important;
        --button-filled-brand-background-hover: #d65d0e !important;
        --button-filled-brand-text: var(--bg0) !important;
      }

      .theme-dark a {
        color: var(--aqua) !important;
      }
    '';
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