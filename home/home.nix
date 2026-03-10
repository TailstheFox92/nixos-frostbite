{ pkgs, ... }:

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
}
