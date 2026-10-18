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
    agentPackages.codex
  ];

  programs.opencode = {
    enable = true;
    package = agentPackages.opencode;

    settings = {
      model = "opencode/deepseek-v4.1-flash-free";
      permission = "allow";
      plugin = [
        "${inputs.ponytail-skill}/.opencode/plugins/ponytail.mjs"
      ];
    };
    tui = {
      theme = "system";
    };
  };
}
