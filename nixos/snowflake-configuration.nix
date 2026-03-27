{ config, pkgs, ... }:

let
  foundryDomain = "foundry.home.arpa";
  foundryDataDir = "/var/lib/foundryvtt/data";
  foundryBackupDir = "/var/lib/foundryvtt/backups";
in

{
  imports = [
    # Replace with hardware generated from the Snowflake test laptop.
    ./snowflake-hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basic host identity and networking.
  networking.hostName = "Snowflake";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Remote management from Cyclone.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.gfernandez = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      # Paste your Cyclone SSH public key here.
      # Example: "ssh-ed25519 AAAA... gfernandez@Cyclone"
    ];
  };

  # Foundry runtime via container with persistent data mounted from host.
  virtualisation.oci-containers = {
    backend = "podman";
    containers.foundryvtt = {
      image = "felddy/foundryvtt:release";
      autoStart = true;
      ports = [ "127.0.0.1:30000:30000/tcp" ];
      volumes = [ "${foundryDataDir}:/data" ];
      environment = {
        FOUNDRY_HOSTNAME = foundryDomain;
        FOUNDRY_PORT = "30000";
        FOUNDRY_PROXY_SSL = "false";
      };
      environmentFiles = [ "/etc/foundry/foundry.env" ];
    };
  };

  # Reverse proxy for browser access and websocket forwarding.
  services.nginx = {
    enable = true;
    virtualHosts.${foundryDomain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:30000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${foundryDataDir} 0750 root root -"
    "d ${foundryBackupDir} 0750 root root -"
  ];

  # Daily compressed local backup for worlds/modules/assets in /data.
  systemd.services.foundry-backup = {
    description = "Create local FoundryVTT data backup";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -eu
      backup_file="${foundryBackupDir}/foundry-$(date +%F-%H%M).tar.gz"
      ${pkgs.gnutar}/bin/tar -C "${foundryDataDir}" -czf "$backup_file" .
      ${pkgs.findutils}/bin/find "${foundryBackupDir}" -type f -name 'foundry-*.tar.gz' -mtime +14 -delete
    '';
  };

  systemd.timers.foundry-backup = {
    description = "Run daily FoundryVTT backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  environment.etc."foundry/foundry.env.example".text = ''
    # Copy to /etc/foundry/foundry.env and keep it out of git.
    # Required by felddy/foundryvtt image.
    FOUNDRY_USERNAME=your_foundry_account_email
    FOUNDRY_PASSWORD=your_foundry_account_password
    FOUNDRY_ADMIN_KEY=replace-with-strong-admin-key
  '';

  networking.firewall.allowedTCPPorts = [ 22 80 ];

  environment.systemPackages = with pkgs; [
    git
    podman
  ];

  nix = {
    package = pkgs.nix;
    extraOptions = "experimental-features = nix-command flakes";
  };

  system.stateVersion = "24.05";
}