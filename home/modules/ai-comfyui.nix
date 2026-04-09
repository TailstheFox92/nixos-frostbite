{ config, pkgs, ... }:

let
  comfyRoot = "${config.home.homeDirectory}/AI/ComfyUI";
  comfyVenv = "${comfyRoot}/.venv";
  comfyDataRoot = "${config.home.homeDirectory}/.local/share/comfyui";
  comfyRuntimeLibs = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.bzip2
    pkgs.xz
    pkgs.zstd
    pkgs.rocmPackages.rocm-runtime
  ];

  comfyBootstrap = pkgs.writeShellScriptBin "comfyui-bootstrap" ''
    #!/usr/bin/env sh
    set -eu

    repo_dir="${comfyRoot}"
    venv_dir="${comfyVenv}"
    data_dir="${comfyDataRoot}"

    mkdir -p "$data_dir/models" "$data_dir/output" "$data_dir/input" "$data_dir/temp"

    if [ ! -d "$repo_dir/.git" ]; then
      ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git "$repo_dir"
    fi

    if [ ! -x "$venv_dir/bin/python" ]; then
      ${pkgs.python312}/bin/python -m venv "$venv_dir"
    fi

    if [ ! -f "$venv_dir/.bootstrap-complete" ] || [ "''${1:-}" = "--force" ]; then
      req_file="$repo_dir/requirements.txt"
      req_without_torch="$venv_dir/requirements-no-torch.txt"

      ${pkgs.gnugrep}/bin/grep -E -v '^(torch|torchvision|torchaudio)([<>=].*)?$' "$req_file" > "$req_without_torch"

      "$venv_dir/bin/pip" install --upgrade pip wheel setuptools
      "$venv_dir/bin/pip" install -r "$req_without_torch"

      # Prefer ROCm PyTorch wheels on Cyclone; if unavailable, fall back to CPU wheels.
      if ! "$venv_dir/bin/pip" install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.3; then
        "$venv_dir/bin/pip" install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
      fi

      : > "$venv_dir/.bootstrap-complete"
    fi

    echo "ComfyUI bootstrap complete: $repo_dir"
  '';

  comfyRun = pkgs.writeShellScriptBin "comfyui-run" ''
    #!/usr/bin/env sh
    set -eu

    repo_dir="${comfyRoot}"
    venv_dir="${comfyVenv}"

    if [ ! -x "$venv_dir/bin/python" ] || [ ! -f "$repo_dir/main.py" ]; then
      echo "ComfyUI is not bootstrapped yet. Run comfyui-bootstrap first." >&2
      exit 1
    fi

    export HIP_VISIBLE_DEVICES="''${HIP_VISIBLE_DEVICES:-0}"
    export HF_HOME="${comfyDataRoot}/cache/huggingface"
    export XDG_CACHE_HOME="${comfyDataRoot}/cache"
    export LD_LIBRARY_PATH="${comfyRuntimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec "$venv_dir/bin/python" "$repo_dir/main.py" --listen 127.0.0.1 --port 8188
  '';

  comfyUpdate = pkgs.writeShellScriptBin "comfyui-update" ''
    #!/usr/bin/env sh
    set -eu

    repo_dir="${comfyRoot}"
    venv_dir="${comfyVenv}"

    if [ ! -d "$repo_dir/.git" ]; then
      echo "ComfyUI repo is not initialized. Run comfyui-bootstrap first." >&2
      exit 1
    fi

    ${pkgs.git}/bin/git -C "$repo_dir" pull --ff-only
    "$venv_dir/bin/pip" install -r "$repo_dir/requirements.txt"

    echo "ComfyUI updated."
  '';

  comfyGpuCheck = pkgs.writeShellScriptBin "comfyui-gpu-check" ''
    #!/usr/bin/env sh
    set -eu

    venv_dir="${comfyVenv}"

    echo "== ROCm devices =="
    ${pkgs.rocmPackages.rocminfo}/bin/rocminfo | ${pkgs.gnugrep}/bin/grep -E 'Name:|Marketing Name' || true

    if [ -x "$venv_dir/bin/python" ]; then
      echo
      echo "== PyTorch backend =="
      export LD_LIBRARY_PATH="${comfyRuntimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      "$venv_dir/bin/python" - <<'PY'
import torch
print(f"torch={torch.__version__}")
print(f"cuda_available={torch.cuda.is_available()}")
print(f"hip={getattr(torch.version, 'hip', None)}")
if torch.cuda.is_available():
    print(f"gpu_name={torch.cuda.get_device_name(0)}")
PY
    else
      echo "Virtual environment not initialized yet. Run comfyui-bootstrap first."
    fi
  '';

  comfyStatus = pkgs.writeShellScriptBin "comfyui-status" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.systemd}/bin/systemctl --user status comfyui --no-pager
  '';

  comfyLogs = pkgs.writeShellScriptBin "comfyui-logs" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.systemd}/bin/journalctl --user -u comfyui -n "''${1:-200}" --no-pager
  '';

  comfyOpen = pkgs.writeShellScriptBin "comfyui-open" ''
    #!/usr/bin/env sh
    set -eu

    ${pkgs.xdg-utils}/bin/xdg-open http://127.0.0.1:8188
  '';
in
{
  home.packages = with pkgs; [
    python312
    git
    comfyBootstrap
    comfyRun
    comfyUpdate
    comfyGpuCheck
    comfyStatus
    comfyLogs
    comfyOpen
  ];

  home.sessionVariables = {
    COMFYUI_HOME = comfyRoot;
    COMFYUI_DATA_DIR = comfyDataRoot;
    HF_HOME = "${comfyDataRoot}/cache/huggingface";
  };

  systemd.user.services.comfyui = {
    Unit = {
      Description = "ComfyUI local image generation service";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      ConditionPathExists = "${comfyRoot}/main.py";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = config.home.homeDirectory;
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "HF_HOME=${comfyDataRoot}/cache/huggingface"
        "XDG_CACHE_HOME=${comfyDataRoot}/cache"
        "LD_LIBRARY_PATH=${comfyRuntimeLibs}"
      ];
      ExecStart = "${comfyRun}/bin/comfyui-run";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
