{ inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects."/home/mkiin/dotfiles".trust_level = "trusted";
    };

    context = inputs.self + "/codex/AGENTS.md";
  };
}
