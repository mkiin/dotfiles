{ inputs, ... }:
let
  inherit (inputs)
    superpowers-skill
    cloudflare-skills
    anthropic-skills
    ;
  local-skills = inputs.self + "/agents/skills";
in
{
  programs.agent-skills = {
    enable = true;

    sources = {
      # Local: 自作スキル (cm, write-sentence)
      local = {
        path = local-skills;
        subdir = ".";
        filter.maxDepth = 1;
      };
      # External: superpowers (obra/superpowers)
      superpowers = {
        path = superpowers-skill;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      # External: Cloudflare 公式スキル (cloudflare/skills)
      cloudflare = {
        path = cloudflare-skills;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      # External: Anthropic 公式スキル (anthropics/skills) — frontend-design のみ使用
      anthropic = {
        path = anthropic-skills;
        subdir = "skills";
        filter.maxDepth = 1;
      };
    };

    # local と superpowers は全 skill を有効化
    skills.enableAll = [ "local" "superpowers" ];

    # cloudflare は使う8個、anthropic は frontend-design のみ個別に有効化
    skills.enable = [
      "agents-sdk"
      "cloudflare"
      "cloudflare-email-service"
      "durable-objects"
      "sandbox-sdk"
      "web-perf"
      "workers-best-practices"
      "wrangler"
      "frontend-design"
    ];

    targets.claude = { enable = true; structure = "link"; dest = ".claude/skills"; };
    targets.codex  = { enable = true; structure = "link"; dest = ".codex/skills"; };
  };
}
