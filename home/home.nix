{ pkgs, ... }:

let
  lfPreview = pkgs.writeShellScriptBin "lf-preview" ''
    file="$1"
    width="$2"
    height="$3"

    [ -z "$file" ] && exit 1

    mime=$(${pkgs.file}/bin/file --mime-type -Lb "$file")

    case "$mime" in
      image/*)
        exec ${pkgs.chafa}/bin/chafa --size="''${width}x''${height}" --symbols=block --animate=off "$file"
        ;;
      text/*|*/xml|application/json|application/x-shellscript)
        exec ${pkgs.bat}/bin/bat --style=plain --color=always --line-range=:300 "$file"
        ;;
      application/pdf)
        exec ${pkgs."poppler-utils"}/bin/pdftotext -q -l 20 "$file" -
        ;;
      application/vnd.openxmlformats-officedocument.wordprocessingml.document|application/msword|application/vnd.oasis.opendocument.text)
        exec ${pkgs.pandoc}/bin/pandoc -t plain "$file"
        ;;
      *)
        exec ${pkgs.file}/bin/file -Lb "$file"
        ;;
    esac
  '';
in
{
  imports = [
    ./modules/desktop-sway.nix
    ./modules/vscode.nix
    ./modules/zsh.nix
  ];

  # Home Manager version
  home.stateVersion = "24.05";

  # Ensure Firefox is never enabled via Home Manager
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
      "image/png" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/bmp" = [ "imv.desktop" ];
      "image/tiff" = [ "imv.desktop" ];
      "image/avif" = [ "imv.desktop" ];
      "inode/directory" = [ "Thunar.desktop" ];
      "application/x-gnome-saved-search" = [ "Thunar.desktop" ];
    };
  };

  # Install user packages
  home.packages = with pkgs; [
    rofi  # Application launcher
    lf  # Terminal file manager
    lfPreview  # Preview helper for lf
    chafa  # Terminal image preview renderer
    bat  # Syntax-highlighted text preview
    pkgs."poppler-utils"  # PDF text preview tool (pdftotext)
    pandoc  # Office document text preview
    thunar  # File manager
    thunar-volman  # Automount and removable media management for Thunar
    thunar-archive-plugin  # Archive create/extract integration inside Thunar
    thunar-dropbox-plugin  # Thunar context-menu integration for Dropbox
    tumbler  # Thumbnail service used by Thunar previews
    ffmpegthumbnailer  # Video thumbnails
    webp-pixbuf-loader  # WEBP thumbnail support for GTK/GdkPixbuf apps
    imv  # Minimal image viewer
    brave  # Web browser
    ruffle # Flash content runtime (Adobe Flash replacement)
    alacritty  # Terminal emulator
    mousepad  # Lightweight GUI text editor
    neovim  # Terminal-based text editor
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

    # C# / .NET development tools
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0
      dotnetCorePackages.sdk_10_0
    ])
    icu
    nuget
    ilspycmd
    zip
    unzip


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

  # session environment for theming
  home.sessionVariables = {
    BROWSER = "brave";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
    FILE_MANAGER = "thunar";
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

  home.file.".config/lf/lfrc" = {
    text = ''
      set icons true
      set preview true
      set drawbox true
      set hidden true
      set number true
      set relativenumber true
      set previewer ${lfPreview}/bin/lf-preview

      cmd open ''${{
        case "$(xdg-mime query filetype "$f")" in
          inode/directory) lf "$f" ;;
          *) xdg-open "$f" >/dev/null 2>&1 ;;
        esac
      }}

      map <enter> open
      map gh cd ~
      map gd cd ~/Downloads
      map gp cd ~/Projects
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
}
