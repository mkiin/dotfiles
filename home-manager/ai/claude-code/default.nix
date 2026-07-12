{
  inputs,
  config,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    settings = {
      theme = "dark";
      # settings.json は nix store の read-only symlink になり /effort が EROFS で失敗するため、
      # effort はここで宣言する（既定モデルが Fable なので実質 Fable の effort になる）
      effortLevel = "medium";
      env = {
        ENABLE_BACKGROUND_TASKS = "1";
        FORCE_AUTO_BACKGROUND_TASKS = "1";
        DISABLE_MICROCOMPACT = "1";
        DISABLE_INTERLEAVED_THINKING = "1";
        DISABLE_ERROR_REPORTING = "1";
        CLAUDE_CODE_NO_FLICKER = "1";
      };
      permissions = {
        deny = [ ];
        defaultMode = "auto";
        additionalDirectories = [ "${config.home.homeDirectory}/ghq" ];
      };
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "bash ${inputs.self}/home-manager/ai/claude-code/files/hooks/block-git-clone.sh";
            }
          ];
        }
      ];
      includeCoAuthoredBy = false;
      alwaysThinkingEnabled = true;
      autoMemoryEnabled = false;
      useAutoModeDuringPlan = true;
      awaySummaryEnabled = false;
      skipAutoPermissionPrompt = true;
      skipDangerousModePermissionPrompt = true;
      skipWorkflowUsageWarning = true;
    };

    context = inputs.self + "/home-manager/ai/claude-code/files/CLAUDE.md";
    commandsDir = inputs.self + "/home-manager/ai/claude-code/files/commands";
    agentsDir = inputs.self + "/home-manager/ai/claude-code/files/agents";
    rulesDir = inputs.self + "/home-manager/ai/claude-code/files/rules";
  };
}
