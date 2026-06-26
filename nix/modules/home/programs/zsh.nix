{ config, dotfilesDir, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/mise/shims"
  ];

  xdg.configFile."zsh/functions.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nix/home/programs/zsh/functions.zsh";

  programs.zsh = {
    enable         = true;
    defaultKeymap  = "emacs";
    autocd         = true;
    enableCompletion = true;

    history = {
      size        = 100000;
      save        = 100000;
      path        = "${config.xdg.dataHome}/zsh/history";
      extended    = true;
      share       = true;
      ignoreDups  = true;
      ignoreSpace = true;
      append      = true;
    };

    shellAliases = {
      ".."   = "cd ..";
      "..."  = "cd ../..";
      "...." = "cd ../../..";
      cls    = "clear";
      sz     = "source ~/.zshrc";
      ls     = "eza --icons=always";
      ll     = "eza -alF --icons=always --git";
      la     = "eza -a --icons=always";
      l      = "eza -F --icons=always";
      tree   = "eza --tree --icons=always";
      gs     = "git status";
      ga     = "git add";
      gc     = "git commit";
      gp     = "git push";
      gl     = "git log --oneline --graph";
      gd     = "git diff";
      gco    = "git checkout";
      gb     = "git branch";
      "c."   = "code .";
      cr     = "code -r .";
      vim    = "nvim";
      lg     = "lazygit";
      pn     = "pnpm";
      nvc    = "cd ~/.config/nvim";
    };

    initContent = ''
      setopt HIST_REDUCE_BLANKS
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu select

      export USER_ID=$(id -u)
      export GROUP_ID=$(id -g)

      eval "$(mise activate zsh)"
      eval "$(zoxide init zsh --cmd cd)"
      source <(fzf --zsh)

      ABBR_QUIET=1
      eval "$(sheldon source)"

      source "${config.xdg.configHome}/zsh/functions.zsh"

      abbr ..="cd .."
      abbr ...="cd ../.."
      abbr ....="cd ../../.."
      abbr cls="clear"
      abbr sz="source ~/.zshrc"
      abbr l="eza -F --icons=always"
      abbr tree="eza --tree --icons=always"
      abbr gs="git status"
      abbr ga="git add"
      abbr gc="git commit"
      abbr gp="git push"
      abbr gl="git log --oneline --graph"
      abbr gd="git diff"
      abbr gco="git checkout"
      abbr gb="git branch"
      abbr lg="lazygit"
      abbr pn="pnpm"
      abbr nvc="cd ~/.config/nvim"
      abbr ai="claude"
      abbr aid="claude --dangerously-skip-permissions"
      abbr aia="claude --enable-auto-mode"
    '';
  };
}
