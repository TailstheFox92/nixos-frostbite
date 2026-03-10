{ pkgs, lib, ... }:

let
  vscodeRasi = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "rasi";
      publisher = "dlasagno";
      version = "1.0.0";
      sha256 = "sha256-s60alej3cNAbSJxsRlIRE2Qha6oAsmcOBbWoqp+w6fk=";
    }
  ];
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit
        ms-dotnettools.vscode-dotnet-runtime
        ms-dotnettools.vscodeintellicode-csharp
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        jnoortheen.nix-ide
        vscodevim.vim
        jdinhlife.gruvbox
      ] ++ vscodeRasi;
    };
  };

  home.activation.vscodeUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    code_user_dir="$HOME/.config/Code/User"
    mkdir -p "$code_user_dir"
    cat > "$code_user_dir/settings.json" <<'EOF'
{
  "editor.fontFamily": "JetBrainsMono Nerd Font, Droid Sans Mono, monospace",
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
  "workbench.colorTheme": "Gruvbox Dark Medium"
}
EOF
  '';
}