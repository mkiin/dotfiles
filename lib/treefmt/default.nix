{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nixfmt-rfc-style (Nix 整形)
    statix.enable = true; # Nix lint (statix fix)
    shfmt.enable = true; # sh / zsh
    prettier.enable = true; # json / md / css
    taplo.enable = true; # toml
    stylua.enable = true; # lua
  };
}
