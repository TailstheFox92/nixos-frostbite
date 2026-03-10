{ ... }:

{
  # Zsh configuration with fastfetch and quality-of-life features
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    };
    initContent = ''
      # Show system info on terminal open
      fastfetch

      # Set a nice prompt
      PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '

      # History settings
      HISTSIZE=5000
      SAVEHIST=5000
      HISTFILE=~/.zsh_history
      setopt inc_append_history
      setopt share_history
      setopt hist_ignore_dups
      setopt hist_reduce_blanks

      # Enable mouse support in terminal
      bindkey -v
    '';
  };
}