{ pkgs, lib, config, lnk, ... }:
{
  programs.neovim = {
    enable = true;
    withPython3 = false;
    withRuby = false;
    extraPackages = with pkgs; [
      typescript-go
      lua-language-server
      nixd
      oxfmt
      bash-language-server
      shellcheck
      shfmt
      tree-sitter
    ];
  };

  xdg.configFile."nvim/init.lua".enable = lib.mkForce false;
  xdg.configFile."nvim".source = lnk ./config;

  home.activation.restoreNeovimPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    LAZY_DIR="$HOME/.local/share/nvim/lazy"
    LAZY_LOCK="${config.xdg.configHome}/nvim/lazy-lock.json"
    LAZY_LOCK_TIMESTAMP="$LAZY_DIR/.lazy-lock-timestamp"

    if [[ ! -f "$LAZY_LOCK_TIMESTAMP" ]] || [[ "$LAZY_LOCK" -nt "$LAZY_LOCK_TIMESTAMP" ]]; then
      if [[ -d "$LAZY_DIR/lazy.nvim" ]]; then
        echo "Restoring Neovim plugins..."
        ${lib.getExe pkgs.neovim} --headless "+Lazy! restore" +qa 2>/dev/null || true
      fi
      mkdir -p "$LAZY_DIR"
      touch "$LAZY_LOCK_TIMESTAMP"
    fi
  '';
}
