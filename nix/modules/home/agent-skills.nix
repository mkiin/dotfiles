{ inputs, ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = inputs.self + "/agents/skills";
      subdir = ".";
      filter.maxDepth = 1;
    };

    sources.superpowers = {
      path = inputs.superpowers-skill;
      subdir = "skills";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "local" "superpowers" ];

    targets.claude = { enable = true; structure = "link"; dest = ".claude/skills"; };
    targets.codex  = { enable = true; structure = "link"; dest = ".codex/skills"; };
  };
}
