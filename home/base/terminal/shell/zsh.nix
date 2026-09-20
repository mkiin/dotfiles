{ config, ... }:
{
  xdg.configFile."zsh/functions.zsh".source = ./functions.zsh;
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    autocd = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.dataHome}/zsh/history";
      extended = true;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      append = true;
    };

    setOptions = [
      "EXTENDED_HISTORY"
      "RM_STAR_WAIT"
      "AUTO_PUSHD"
      "HIST_REDUCE_BLANKS"
      "PUSHD_IGNORE_DUPS"
    ];

    autosuggestion.enable = true;

    zsh-abbr = {
      enable = true;
      abbreviations = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";

        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline --graph";
        gd = "git diff";
        gco = "git checkout";
        gb = "git branch";

        clr = "clear";
        src = "source $ZDOTDIR/.zshrc";
        lg = "lazygit";
        ff = "fastfetch";
        pn = "pnpm";
        nk = "nikke kill";
        vim = "nvim";
        zd = "zeditor";

        cla = "claude";
        claa = "claude --enable-auto-mode";

        cod = "codex";
        coda = "codex --full-auto";
        codx = "codex --dangerously-bypass-approvals-and-sandbox";
      };
    };

    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu select


      source "${config.xdg.configHome}/zsh/functions.zsh"
      export USER_ID=$(id -u)
      export GROUP_ID=$(id -g)
    '';
  };
}
