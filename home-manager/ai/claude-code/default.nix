{ inputs, config, ... }:
{
  programs.claude-code = {
    enable = true;
    package = null;

    settings = {
      theme = "dark";
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
      effortLevel = "high";
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
