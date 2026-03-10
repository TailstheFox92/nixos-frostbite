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
  waybarConfig = builtins.replaceStrings
    [ "@WAYBAR_WEATHER@" "@ROFI_POWER_MENU@" ]
    [ "${waybarWeather}/bin/waybar-weather" "${rofiPowerMenu}/bin/rofi-powermenu" ]
    (builtins.readFile ./config/waybar/config);
  waybarStyle = builtins.readFile ./config/waybar/style.css;
  rofiTheme = ./config/rofi/theme.rasi;
  gruvboxDiscordTheme = builtins.readFile ./config/discord/gruvbox.theme.css;
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
    tumbler  # Thumbnail service used by Thunar previews
    ffmpegthumbnailer  # Video thumbnails
    webp-pixbuf-loader  # WEBP thumbnail support for GTK/GdkPixbuf apps
    brave  # Web browser
    alacritty  # Terminal emulator
    fastfetch # For the funny ascii system info in the terminal
    dropbox # Dropbox client
    swaynotificationcenter # Notification daemon + control center
    vesktop # Discord client with Vencord pre-applied
    grim
    slurp
    swappy
    wl-clipboard
    libnotify
    pavucontrol
    blueman


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

  # Start Dropbox automatically in the user session
  systemd.user.services.dropbox = {
    Unit = {
      Description = "Dropbox service";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox start -i";
      ExecStop = "${pkgs.dropbox}/bin/dropbox stop";
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
        "${modifier}+Shift+b" = "exec blueman-manager";  # Launch Blueman Manager
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
          command = "${pkgs.swaybg}/bin/swaybg -i ${wallpaperPath} -m fill";
          always = true;
        }
        {
          command = "${pkgs.sway}/bin/swaymsg workspace number 1";
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
      client.focused #d65d0e #d65d0e #282828 #fe8019 #d65d0e
      client.focused_inactive #504945 #504945 #ebdbb2 #7c6f64 #504945
      client.unfocused #3c3836 #3c3836 #a89984 #665c54 #3c3836
      client.urgent #fb4934 #fb4934 #282828 #fb4934 #fb4934
      assign [app_id="code"] workspace number 1
      assign [class="Code"] workspace number 1
      assign [app_id="brave-browser"] workspace number 2
      assign [class="Brave-browser"] workspace number 2
      assign [app_id="vesktop"] workspace number 3
      assign [class="Vesktop"] workspace number 3
      assign [class="discord"] workspace number 3
      for_window [app_id="brave-browser" window_type="dialog"] floating enable
      for_window [class="Brave-browser" window_type="dialog"] floating enable
      for_window [class="Steam" window_type="dialog"] floating enable
      for_window [class="Steam" title="^Friends List$"] floating enable
      for_window [class="Steam" title="^Properties - .*$"] floating enable
      for_window [class="Steam" title="^.* - Properties$"] floating enable
      for_window [class="Steam" title="^.*Properties.*$"] floating enable
      for_window [app_id="thunar"] floating enable
      for_window [class="Thunar"] floating enable
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

  # SwayNC notification center themed to match Waybar/Avali UI
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      "control-center-layer" = "top";
      "control-center-width" = 420;
      "control-center-height" = 720;
      "notification-window-width" = 420;
      "notification-icon-size" = 48;
      timeout = 6;
      "timeout-low" = 3;
      "timeout-critical" = 0;
      "fit-to-screen" = true;
      "cssPriority" = "application";
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
      }

      .notification-row,
      .notification-group,
      .control-center .notification-row {
        margin: 4px 8px;
      }

      .notification,
      .notification-content,
      .control-center,
      .widget-title,
      .widget-dnd,
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #282828;
        color: #ebdbb2;
        border: 1px solid #d65d0e;
        border-radius: 4px;
      }

      .control-center {
        padding: 8px;
      }

      .notification {
        padding: 6px;
      }

      .notification .summary,
      .notification .time,
      .notification .body,
      .widget-title > label {
        color: #ebdbb2;
      }

      .notification.critical,
      .notification.critical .notification-content {
        border-color: #fb4934;
      }

      .close-button {
        background: #3c3836;
        color: #fabd2f;
        border: 1px solid #d65d0e;
        border-radius: 4px;
      }

      .widget-dnd > switch {
        background: #3c3836;
        border: 1px solid #d65d0e;
        border-radius: 12px;
      }

      .widget-dnd > switch:checked {
        background: #d65d0e;
      }

      .widget-buttons-grid > flowbox > flowboxchild > button:hover,
      .close-button:hover {
        background: #3c3836;
      }
    '';
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
    text = gruvboxDiscordTheme;
  };
  home.file.".config/vesktop/themes/gruvbox.theme.css" = {
    text = gruvboxDiscordTheme;
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