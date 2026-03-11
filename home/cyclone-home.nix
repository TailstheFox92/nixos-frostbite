{ pkgs, ... }:

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
    };
  };

  home.packages = with pkgs; [
    rofi
    thunar
    thunar-dropbox-plugin
    tumbler
    ffmpegthumbnailer
    webp-pixbuf-loader
    brave
    alacritty
    mousepad
    neovim
    fastfetch
    dropbox
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
