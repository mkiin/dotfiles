{
  pkgs,
  inputs,
  ...
}:
let
  agentPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    # Agents
    agentPackages.codex
  ];
}
