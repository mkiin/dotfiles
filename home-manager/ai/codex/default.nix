{
  inputs,
  homeDirectory,
  username,
  ...
}:
let
  dotfilesDir = "${homeDirectory}/ghq/github.com/${username}/dotfiles";
in
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects.${dotfilesDir}.trust_level = "trusted";
    };

    context = inputs.self + "/home-manager/ai/codex/files/AGENTS.md";
  };
}
