{ inputs, ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = inputs.self + "/agents/skills";
      subdir = ".";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "local" ];

    targets.claude = { enable = true; structure = "link"; };
    targets.codex  = { enable = true; structure = "link"; };
  };
}
