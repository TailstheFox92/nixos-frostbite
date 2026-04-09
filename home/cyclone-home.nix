{ config, pkgs, ... }:

let
  vrAlvrQuest3 = pkgs.writeShellScriptBin "vr-alvr-quest3" ''
    #!/usr/bin/env sh
    set -eu

    steamxr_json="$HOME/.local/share/Steam/steamapps/common/SteamVR/steamxr_linux64.json"
    if [ -f "$steamxr_json" ]; then
      export XR_RUNTIME_JSON="$steamxr_json"

      # Make SteamVR the user-level default OpenXR runtime.
      runtime_dir="$HOME/.config/openxr/1"
      mkdir -p "$runtime_dir"
      ln -sfn "$steamxr_json" "$runtime_dir/active_runtime.json"
    fi

    export LIBVA_DRIVER_NAME=radeonsi
    export LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export PRESSURE_VESSEL_GRAPHICS_PROVIDER=/run/opengl-driver
    export PRESSURE_VESSEL_FILESYSTEMS_RO="''${PRESSURE_VESSEL_FILESYSTEMS_RO:+$PRESSURE_VESSEL_FILESYSTEMS_RO:}/run/opengl-driver:/run/opengl-driver-32"
    export QT_QPA_PLATFORM=xcb
    export SDL_VIDEODRIVER=x11
    export GDK_BACKEND=x11

    session_file="$HOME/.config/alvr/session.json"
    if [ -f "$session_file" ]; then
      # Stable profile: H264 + no foveated + hardware encoding enabled.
      ${pkgs.gnused}/bin/sed -i \
        -e 's/"force_sw_encoding"[[:space:]]*:[[:space:]]*true/"force_sw_encoding": false/g' \
        -e 's/"force_software_encoding"[[:space:]]*:[[:space:]]*true/"force_software_encoding": false/g' \
        -e 's/"use_separate_hand_trackers"[[:space:]]*:[[:space:]]*true/"use_separate_hand_trackers": false/g' \
        -e 's/"variant"[[:space:]]*:[[:space:]]*"HEVC"/"variant": "H264"/g' \
        -e 's/"variant"[[:space:]]*:[[:space:]]*"AV1"/"variant": "H264"/g' \
        "$session_file"
    fi

    # Ensure ALVR dashboard is running for client discovery/pairing.
    if ! ${pkgs.procps}/bin/pgrep -x alvr_dashboard >/dev/null 2>&1; then
      ${pkgs.alvr}/bin/alvr_dashboard >/dev/null 2>&1 &
      sleep 2
    fi

    # Launch only ALVR. Start SteamVR manually from the ALVR dashboard when ready.
    exit 0
  '';

  unityAlcom = pkgs.writeShellScriptBin "unity-alcom" ''
    #!/usr/bin/env sh
    set -eu

    editor="''${UNITY_EDITOR_PATH:-$HOME/Unity/Hub/Editor/2022.3.22f1/Editor/Unity}"
    if [ ! -x "$editor" ]; then
      editor="$(ls -1d "$HOME"/Unity/Hub/Editor/*/Editor/Unity 2>/dev/null | sort -V | tail -n 1)"
    fi

    if [ -z "''${editor:-}" ] || [ ! -x "$editor" ]; then
      echo "unity-alcom: Unity editor not found. Install Unity via Unity Hub first." >&2
      exit 1
    fi

    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
      pkgs.zlib
      pkgs.icu
      pkgs.openssl
      pkgs.curl
      (pkgs.lib.getLib pkgs.libxml2_13)
      pkgs.libxml2
      pkgs.libGL
      pkgs.libdrm
      pkgs.mesa
      pkgs.vulkan-loader
      pkgs.systemd
      pkgs.alsa-lib
      pkgs.pulseaudio
      pkgs.gtk3
      pkgs.gdk-pixbuf
      pkgs.pango
      pkgs.cairo
      pkgs.atk
      pkgs.at-spi2-atk
      pkgs.fontconfig
      pkgs.freetype
      pkgs.dbus
      pkgs.glib
      pkgs.nss
      pkgs.nspr
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.libx11
      pkgs.libxext
      pkgs.libxcursor
      pkgs.libxi
      pkgs.libxinerama
      pkgs.libxrandr
      pkgs.libxrender
    ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec "$editor" "$@"
  '';
in

{
  imports = [
    ./modules/desktop-hyprland.nix
    ./modules/vscode-catppuccin.nix
    ./modules/zsh.nix
  ];

  home.stateVersion = "24.05";

  programs.firefox.enable = false;

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
    };
  };

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings.user = {
      name = "Gabriel Fernandez";
      email = "gfernandez@mailfence.com";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = [ "~/.ssh/id_ed25519" ];
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "application/xhtml+xml" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "inode/directory" = [ "Thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "Thunar.desktop" ];
      "application/zip" = [ "xarchiver.desktop" ];
      "application/x-zip-compressed" = [ "xarchiver.desktop" ];
      "application/x-7z-compressed" = [ "xarchiver.desktop" ];
      "application/x-rar" = [ "xarchiver.desktop" ];
      "application/vnd.rar" = [ "xarchiver.desktop" ];
      "application/x-tar" = [ "xarchiver.desktop" ];
      "application/x-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-bzip-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-xz-compressed-tar" = [ "xarchiver.desktop" ];
      "application/gzip" = [ "xarchiver.desktop" ];
      "application/x-gzip" = [ "xarchiver.desktop" ];
      "application/bzip2" = [ "xarchiver.desktop" ];
      "application/x-bzip2" = [ "xarchiver.desktop" ];
      "application/x-xz" = [ "xarchiver.desktop" ];
      "application/zstd" = [ "xarchiver.desktop" ];
      "application/x-zstd" = [ "xarchiver.desktop" ];
      "application/java-archive" = [ "xarchiver.desktop" ];
    };
  };

  home.packages = with pkgs; [
    rofi
    thunar
    thunar-volman
    thunar-archive-plugin
    tumbler
    ffmpegthumbnailer
    webp-pixbuf-loader
    brave
    firefox
    alacritty
    mousepad
    neovim
    fastfetch
    maestral
    swaynotificationcenter
    vesktop
    grim
    slurp
    swappy
    wl-clipboard
    libnotify
    pavucontrol
    blueman
    waybar
    pamixer
    playerctl
    brightnessctl
    alvr #If unity-alcom version fails, paste that exact output and I’ll patch the wrapper in one pass.
    
    
    wayvr
    vrAlvrQuest3
    unityAlcom
    prismlauncher
    steam-run
    blender
    unityhub
    alcom
    vrc-get

    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0
      dotnetCorePackages.sdk_10_0
    ])
    icu
    nuget
    ilspycmd
    zip
    unzip

    catppuccin-gtk
    catppuccin-qt5ct
    papirus-icon-theme
    bibata-cursors
    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
    theme = {
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "lavender" ];
        size = "standard";
      };
      name = "catppuccin-mocha-lavender-standard";
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

  systemd.user.services.maestral = {
    Unit = {
      Description = "Maestral service";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/Dropbox"
        "${pkgs.maestral}/bin/maestral config set path ${config.home.homeDirectory}/Dropbox"
        "${pkgs.maestral}/bin/maestral autostart -Y"
      ];
      ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
    };
  };

  home.sessionVariables = {
    BROWSER = "brave";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
    FILE_MANAGER = "thunar";
    GTK_THEME = "catppuccin-mocha-lavender-standard";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    RADV_PERFTEST = "gpl";
    LIBVA_DRIVER_NAME = "radeonsi";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    XR_RUNTIME_JSON = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/steamxr_linux64.json";
    PRISMLAUNCHER_JAVA_PATHS = "${pkgs.jdk21}/bin/java:${pkgs.jdk17}/bin/java:${pkgs.jdk8}/bin/java";
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Fusion";
    qt5ctSettings = {
      Appearance = {
        style = "Fusion";
        icon_theme = "Papirus-Dark";
        custom_palette = true;
        color_scheme_path = "catppuccin-mocha-lavender.conf";
      };
    };

    qt6ctSettings = {
      Appearance = {
        style = "Fusion";
        icon_theme = "Papirus-Dark";
        custom_palette = true;
        color_scheme_path = "catppuccin-mocha-lavender.conf";
      };
    };
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
            "1": "38;5;183"
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
}
