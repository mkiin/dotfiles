{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    inputs.mcp-servers-nix.homeManagerModules.default
    ./cli
    ./editor
    ./ai
  ];

  news.display = "silent";
}
