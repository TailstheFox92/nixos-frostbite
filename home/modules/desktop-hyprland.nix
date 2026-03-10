{ config, pkgs, ... }:

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
        exec ${pkgs.hyprland}/bin/hyprctl dispatch exit
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
  waybarConfig = builtins.replaceStrings
    [ "@WAYBAR_WEATHER@" "@ROFI_POWER_MENU@" ]
    [ "${waybarWeather}/bin/waybar-weather" "${rofiPowerMenu}/bin/rofi-powermenu" ]
    (builtins.readFile ../config/waybar/cyclone-config);
  waybarStyle = builtins.readFile ../config/waybar/cyclone-style.css;
  rofiTheme = ../config/rofi/catppuccin-mocha.rasi;
  catppuccinDiscordTheme = builtins.readFile ../config/discord/catppuccin-mocha.theme.css;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      "$mod" = "SUPER";

      monitor = [ ",preferred,auto,1" ];

      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Ice"
      ];

      exec-once = [
        "${pkgs.waybar}/bin/waybar"
        "${pkgs.swaybg}/bin/swaybg -i ${wallpaperPath} -m fill"
      ];

      input = {
        kb_layout = "us";
      };

      general = {
        gaps_in = 5;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgb(cba6f7)";
        "col.inactive_border" = "rgb(45475a)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
      };

      animations = {
        enabled = false;
      };

      bind = [
        "$mod, Return, exec, alacritty"
        "$mod, D, exec, ${rofiDebugLauncher}/bin/rofi-debug-launcher"
        "$mod SHIFT, P, exec, ${rofiPowerMenu}/bin/rofi-powermenu"
        "$mod SHIFT, L, exec, ${lockScreen}/bin/lock-screen"
        "$mod SHIFT, D, exec, vesktop"
        "$mod, E, exec, thunar"
        "$mod, W, exec, brave"
        "$mod SHIFT, B, exec, blueman-manager"
        "$mod SHIFT, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        ", XF86AudioRaiseVolume, exec, ${volumeUpNotify}/bin/volume-up-notify"
        ", XF86AudioLowerVolume, exec, ${volumeDownNotify}/bin/volume-down-notify"
        ", XF86AudioMute, exec, ${volumeMuteToggleNotify}/bin/volume-mute-toggle-notify"
        ", XF86AudioMicMute, exec, ${pkgs.pamixer}/bin/pamixer --default-source -t"
        ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
        ", XF86AudioPause, exec, ${pkgs.playerctl}/bin/playerctl pause"
        ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
        ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
        ", XF86MonBrightnessUp, exec, ${brightnessUpNotify}/bin/brightness-up-notify"
        ", XF86MonBrightnessDown, exec, ${brightnessDownNotify}/bin/brightness-down-notify"
        ", Print, exec, ${screenshotFull}/bin/screenshot-full"
        "SHIFT, Print, exec, ${screenshotRegion}/bin/screenshot-region"
        "CTRL, Print, exec, ${screenshotRegionEdit}/bin/screenshot-region-edit"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      windowrulev2 = [
        "workspace 1, class:^(code)$"
        "workspace 1, class:^(Code)$"
        "workspace 2, class:^(Brave-browser)$"
        "workspace 3, class:^(vesktop)$"
        "workspace 3, class:^(discord)$"
        "float, class:^(thunar)$"
        "float, class:^(Steam)$"
      ];
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 12.0;
      };

      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };

      window.opacity = 0.92;
    };
  };

  programs.rofi = {
    enable = true;
    theme = rofiTheme;
    extraConfig = {
      show-icons = true;
      drun-display-format = "{icon} {name}";
    };
  };

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

      .notification,
      .notification-content,
      .control-center,
      .widget-title,
      .widget-dnd,
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #1e1e2e;
        color: #cdd6f4;
        border: 1px solid #cba6f7;
        border-radius: 6px;
      }

      .notification.critical,
      .notification.critical .notification-content {
        border-color: #f38ba8;
      }

      .close-button {
        background: #313244;
        color: #f9e2af;
        border: 1px solid #cba6f7;
        border-radius: 6px;
      }

      .widget-dnd > switch:checked {
        background: #cba6f7;
      }
    '';
  };

  home.file.".local/share/backgrounds/default-wallpaper.png" = {
    source = ../assets/avali-wallpaper.png;
  };

  home.file.".config/waybar/config" = {
    text = waybarConfig;
  };
  home.file.".config/waybar/style.css" = {
    text = waybarStyle;
  };
  home.file.".config/Vencord/themes/catppuccin-mocha.theme.css" = {
    text = catppuccinDiscordTheme;
  };
  home.file.".config/vesktop/themes/catppuccin-mocha.theme.css" = {
    text = catppuccinDiscordTheme;
  };
}
