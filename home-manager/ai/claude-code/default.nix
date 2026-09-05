{
  inputs,
  config,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    enableMcpIntegration = true;

    settings = {
      theme = "dark";
      # settings.json は nix store の read-only symlink になり /effort が EROFS で失敗するため、
      # effort はここで宣言する（既定モデルが Fable なので実質 Fable の effort になる）
      effortLevel = "medium";
      env = {
        ENABLE_BACKGROUND_TASKS = "1";
        FORCE_AUTO_BACKGROUND_TASKS = "1";
        DISABLE_COMPACT = "1";
        DISABLE_INTERLEAVED_THINKING = "1";
        DISABLE_ERROR_REPORTING = "1";
        CLAUDE_CODE_NO_FLICKER = "1";
        CLAUDE_CODE_THRIFTY_SONIC = "0";
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
            {
              type = "command";
              command = "bash ${inputs.self}/home-manager/ai/claude-code/files/hooks/block-file-tool-bypass.sh";
            }
          ];
        }
      ];
      # セーフティ分類器に引っかかった際、Opus 4.8 へ黙って移らずダイアログで選ばせる
      switchModelsOnFlag = false;
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

  xdg.mimeApps.defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
}
