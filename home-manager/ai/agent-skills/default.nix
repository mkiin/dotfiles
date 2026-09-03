{ inputs, ... }:
let
  inherit (inputs)
    superpowers-skill
    cloudflare-skills
    anthropic-skills
    archify-skill
    ;
  local-skills = inputs.self + "/home-manager/ai/agent-skills/files/skills";
in
{
  # 更新は flake input で固定するので、archify 自身の更新通知 GET は無効化する。
  home.sessionVariables.ARCHIFY_UPDATE_CHECK_DISABLED = "1";

  programs.agent-skills = {
    enable = true;

    sources = {
      # Local: 自作スキル (cm, japanese-tech-writing, cognitive-rhythm-writing)
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
        path = inputs.herdr;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      # External: archify（SKILL.md はリポジトリ直下の archify/ にあるので subdir はルート）
      archify = {
        path = archify-skill;
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
      "sandbox-stable"
      "web-perf"
      "workers-best-practices"
      "wrangler"
      "frontend-design"
      "herdr"
      "archify"
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
