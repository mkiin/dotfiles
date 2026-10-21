{
  pkgs,
  inputs,
  ...
}:
let
  agentPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  programs.agent-skills = {
    enable = true;
    sources.ponytail = {
      input = "ponytail-skill";
      subdir = "skills";
    };
    skills.enableAll = [ "ponytail" ];
    targets.agents = {
      enable = true;
      dest = "$HOME/.agents/skills";
      structure = "copy-tree";
    };
  };

  programs.codex = {
    enable = true;
    package = agentPackages.codex;
    mutableSettings = true;
    settings = {
      sandbox_mode = "danger-full-access";
      approval_policy = "never";
      tui.auto_recap = false;
    };
  };

  programs.opencode = {
    enable = true;
    package = agentPackages.opencode;

    settings = {
      model = "opencode/deepseek-v4.1-flash-free";
      permission = "allow";
    };
    tui = {
      theme = "system";
    };
  };
}
