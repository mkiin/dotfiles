{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./cli
    ./editor
    ./ai
  ];

  news.display = "silent";
}
