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
