{ ... }:
{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;
    mutableUserDebug = false;

    extensions = [
      "kanagawa-themes"
      "colored-zed-icons-theme"
      "oxc"
      "dockerfile"
      "just"
      "kdl"
      "nix"
      "nu"
      "terraform"
      "toml"
      "lua"
      "luau"
      "windows-batch"
      "tsgo"
    ];

    userSettings = {
      format_on_save = "on";
      prettier.allowed = false;

      autosave = "on_focus_change";

      search.regex = false;
      use_smartcase_search = true;

      inlay_hints.show_type_hints = false;

      terminal = {
        default_height = 280;

        shell.with_arguments = {
          program = "zsh";
          args = [ ];
        };
      };

      git.inline_blame.show_commit_summary = true;

      auto_update = false;
      cli_default_open_behavior = "existing_window";

      agent.play_sound_when_agent_done = "when_hidden";

      agent_servers = {
        opencode.type = "registry";
        codex-acp.type = "registry";
      };

      edit_predictions.allow_data_collection = "no";

      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };
  };
}
