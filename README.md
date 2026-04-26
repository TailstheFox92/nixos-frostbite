# nixos-frostbite

Multi-host NixOS flake with Home Manager profiles.

## Hosts

- `Frostbite` (existing machine)
- `Cyclone` (AMD desktop, user `gfernandez`, Hyprland + Catppuccin Mocha)

## Quick validation

Run from repo root:

```bash
nix flake check path:.
nix eval .#nixosConfigurations.Cyclone.config.system.stateVersion
```

## Install Cyclone from NixOS boot disk

These steps are for a fresh install from the NixOS ISO/live environment.

### 1) Mount your target root/boot partitions

If you are reusing existing partitions, just mount them (no repartitioning required).

Example (adjust for your labels/devices):

```bash
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
findmnt /mnt /mnt/boot
```

### 2) Get this flake onto the live system

```bash
git clone <your-repo-url> nixos-frostbite
cd nixos-frostbite
```

If this repo is already on a USB drive, you can copy it instead of cloning.

### 3) Generate hardware config and replace the Cyclone sample file

This is the key step when reusing partitions: NixOS will detect the currently mounted filesystems and write the correct UUID/device references.

```bash
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix ./nixos/cyclone-hardware-configuration.nix
```

Optional review before install:

```bash
cat ./nixos/cyclone-hardware-configuration.nix
```

### 4) Optional sanity check before install

```bash
nix flake check path:.
```

### 5) Install using the Cyclone flake output

```bash
sudo nixos-install --flake .#Cyclone
```

### 6) Reboot

```bash
sudo reboot
```

## Post-install updates (on Cyclone)

After booting into the installed system:

```bash
cd ~/nixos-frostbite
sudo nixos-rebuild switch --flake .#Cyclone
```

If you only changed Home Manager content and want faster iteration:

```bash
home-manager switch --flake .#gfernandez@Cyclone
```

## Cyclone AppImage support

Cyclone enables NixOS AppImage support declaratively via `programs.appimage` and includes `appimage-run`.

After rebuild, you can run AppImages with:

```bash
appimage-run /path/to/YourApp.AppImage
```

If an AppImage has become part of your permanent toolchain, you can manage it through Nix by packaging it with `pkgs.appimageTools.wrapType2` in a Nix module/overlay and adding that package to your config.

## Cyclone VR (ALVR + Quest 3)

Cyclone is configured declaratively with:

- `programs.alvr.enable = true` and firewall rules via `openFirewall`
- Network tuning for lower-latency wireless streaming
- `android-tools` for optional ADB/wired workflows
- User helpers: `alvr`, `wlx-overlay-s`, and `vr-alvr-quest3`

After rebuild:

1. Open ALVR dashboard once and pair your Quest 3 client.
2. Launch SteamVR with:

```bash
vr-alvr-quest3
```

3. Install/run VRChat from Steam in VR mode.

Notes:

- Fine-grained ALVR encoder/bitrate/headset settings are currently not exposed as stable NixOS module options (`programs.alvr` exposes `enable`, `openFirewall`, `package`).
- Keep the PC on Ethernet and Quest 3 on 5/6 GHz Wi-Fi for best streaming performance.

## Cyclone local image generation (ComfyUI + ROCm)

Cyclone includes a declarative ComfyUI user service and helper commands.

### Apply configuration

```bash
cd ~/nixos-frostbite
sudo nixos-rebuild switch --flake .#Cyclone
home-manager switch --flake .#gfernandez@Cyclone
```

### Service lifecycle

```bash
comfyui-bootstrap
systemctl --user daemon-reload
systemctl --user enable --now comfyui
comfyui-status
comfyui-logs
```

ComfyUI listens on `http://127.0.0.1:8188`.

### Helper commands

```bash
comfyui-bootstrap     # clone + venv + requirements (+ ROCm torch attempt)
comfyui-run           # run ComfyUI manually in foreground
comfyui-update        # git pull + refresh python dependencies
comfyui-gpu-check     # rocminfo + torch backend visibility check
comfyui-open          # open local UI URL
```

### Data and cache paths

- Repo: `~/AI/ComfyUI`
- Data root: `~/.local/share/comfyui`
- Hugging Face cache: `~/.local/share/comfyui/cache/huggingface`

### Troubleshooting

If ROCm acceleration is unavailable, the service still runs with CPU fallback. Use:

```bash
comfyui-gpu-check
journalctl --user -u comfyui -n 200 --no-pager
```

If bootstrap dependencies changed, rerun:

```bash
comfyui-bootstrap --force
```
