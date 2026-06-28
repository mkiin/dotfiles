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
        deny = [
          "Bash(grep:*)"
          "Bash(find:*)"
          "Bash(/usr/bin/grep*)"
          "Bash(/bin/grep*)"
          "Bash(/usr/bin/find*)"
          "Bash(/bin/find*)"
        ];
        defaultMode = "auto";
        additionalDirectories = [ "${config.home.homeDirectory}/ghq" ];
      };
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "bash ${inputs.self}/claude/hooks/block-git-clone.sh";
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

    context = inputs.self + "/claude/CLAUDE.md";
    commandsDir = inputs.self + "/claude/commands";
    agentsDir = inputs.self + "/claude/agents";
    rulesDir = inputs.self + "/claude/rules";
  };
}
