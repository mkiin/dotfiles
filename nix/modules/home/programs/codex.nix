{ inputs, dotfilesDir, ... }:
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects.${dotfilesDir}.trust_level = "trusted";
    };

    context = inputs.self + "/codex/AGENTS.md";
  };
}
