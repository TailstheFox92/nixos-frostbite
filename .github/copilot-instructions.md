# Copilot instructions for `nixos-frostbite`

## Big picture architecture
- This repo is a single-host NixOS flake for host `Frostbite` (`flake.nix`).
- System-level configuration lives in `nixos/configuration.nix` (boot, networking, display manager, PipeWire, fonts, system packages).
- User/session configuration lives in `home/home.nix` via Home Manager imported from `flake.nix` under `home-manager.users.qu1ck51lv3r`.
- `nixos/hardware-configuration.nix` is hardware-generated and should be treated as machine-specific.

## Data flow and boundaries
- `flake.nix` composes modules in this order: `nixos/configuration.nix` + Home Manager module + inline HM wiring.
- Home Manager uses global pkgs (`home-manager.useGlobalPkgs = true`), so package references should stay on `pkgs` in both modules.
- UI stack boundary:
  - Sway enablement and core compositor deps are in `nixos/configuration.nix` (`programs.sway`).
  - Sway behavior, Waybar config text, Rofi theme, Mako style, and user apps are in `home/home.nix`.

## Project-specific patterns
- Keep generated config payloads embedded as Nix strings in `home/home.nix` (`waybarConfig`, `waybarStyle`, Rofi theme) and written via `home.file`.
- Local helper scripts are created with `pkgs.writeShellScriptBin` (examples: `waybar-weather`, `rofi-debug-launcher`) and referenced by absolute Nix store paths.
- Prefer declarative user services in Home Manager (`systemd.user.services.maestral`) over ad-hoc startup scripts.
- Theming is intentionally Gruvbox-centered across GTK/Qt/cursor/Waybar/Mako; preserve consistency when changing UI settings.
- Keep comments concise and practical; this repo uses explanatory inline comments heavily.

## Critical workflows
- Validate evaluation before rebuilding:
  - `nix flake check`
  - `nix eval .#nixosConfigurations.Frostbite.config.system.stateVersion`
- Apply system + Home Manager changes (primary workflow):
  - `sudo nixos-rebuild switch --flake .#Frostbite`
- Fast iteration for Home Manager-only edits (optional):
  - `home-manager switch --flake .#qu1ck51lv3r@Frostbite`

## Editing guidance for agents
- Make the smallest possible change in the correct layer:
  - System/boot/services/display manager => `nixos/configuration.nix`
  - User apps/shell/Waybar/Sway keybinds/themes => `home/home.nix`
- Do not rename host/user identifiers (`Frostbite`, `qu1ck51lv3r`) unless explicitly requested.
- Preserve existing module style (`with pkgs; [ ... ]`, attrset layout, and current comment style).
- When adding desktop components, ensure dependencies are declared in Nix (avoid imperative installs).
