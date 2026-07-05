{ inputs, pkgs, ... }:
let
  inherit (inputs)
    superpowers-skill
    cloudflare-skills
    anthropic-skills
    ;
  local-skills = inputs.self + "/home-manager/ai/agent-skills/files/skills";

  # herdr の SKILL.md はリポジトリ直下にあり skills/<名前>/SKILL.md 構造でないため包み直す
  herdr-skill = pkgs.runCommand "herdr-skill" { } ''
    mkdir -p $out/herdr
    cp ${inputs.herdr}/SKILL.md $out/herdr/SKILL.md
  '';
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
      # External: herdr operate skill（HERDR_ENV=1 のときだけ herdr を CLI 操作）
      herdr = {
        path = herdr-skill;
        subdir = ".";
        filter.maxDepth = 1;
      };
    };

    # local と superpowers は全 skill を有効化
    skills.enableAll = [
      "local"
      "superpowers"
    ];

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
      "herdr"
    ];

    targets.claude = {
      enable = true;
      structure = "link";
      dest = ".claude/skills";
    };
    targets.codex = {
      enable = true;
      structure = "link";
      dest = ".codex/skills";
    };
  };
}
