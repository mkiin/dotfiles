{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  herdr = lib.getExe inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  reviewrFocus = pkgs.writeShellApplication {
    name = "herdr-reviewr-focus";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ./plugins/reviewr-focus/toggle.sh;
  };

  reviewrFocusPlugin = tomlFormat.generate "herdr-reviewr-focus-plugin.toml" {
    id = "local.reviewr-focus";
    name = "reviewr-focus";
    version = "1.0.0";
    min_herdr_version = "0.8.2";
    platforms = [ "linux" ];
    actions = [
      {
        id = "toggle";
        title = "Toggle reviewr and focus its tab";
        contexts = [
          "pane"
          "workspace"
        ];
        command = [ "${reviewrFocus}/bin/herdr-reviewr-focus" ];
      }
    ];
  };

  settings = {
    onboarding = false;

    keys = {
      # prefix→単一文字を wezterm(LEADER+文字) に一致させる。chord は全廃。
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";

      # navigate モードは素の hjkl（prefix+ 不可のフィールド）
      # workspace 上下は矢印が押しづらいので ctrl+p/n へ。hjkl はペインが占有済み。
      navigate_workspace_up = "ctrl+p";
      navigate_workspace_down = "ctrl+n";
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";

      new_tab = "prefix+n";
      # q は wezterm=タブを閉じる。detach は tmux 定番の prefix+d へ退避し衝突回避。
      close_tab = "prefix+q";
      detach = "prefix+d";
      previous_tab = "prefix+shift+h";
      next_tab = "prefix+shift+l";

      # wezterm 基準: s=左右, v=上下。実機で向きが逆なら s/v を入替。
      split_horizontal = "prefix+s";
      split_vertical = "prefix+v";

      close_pane = "prefix+m";
      zoom = "prefix+z";
      resize_mode = "prefix+r";
      toggle_sidebar = "prefix+shift+b";

      # command は action id を取る。プラグイン間で id が衝突すると
      # ambiguous_plugin_action になるため <plugin_id>.<action_id> で修飾する。
      command = [
        {
          key = "prefix+f";
          type = "plugin_action";
          command = "herdr-file-viewer.open-file-viewer";
          description = "open file viewer";
        }
        {
          key = "prefix+g";
          type = "plugin_action";
          command = "local.reviewr-focus.toggle";
          description = "toggle reviewr";
        }
      ];
    };
  };

  # reviewr 自身の設定。herdr の config.toml とは別系統で、値が 1 つでも不正だと
  # ファイル全体が捨てられる。プラグイン本体は herdr plugin install 側の管理。
  reviewr = {
    theme = "gruvbox";
    base_branches = [ "main" ];
    default_scope = "uncommitted";
    navigator_position = "left";
    toggle_placement = "tab";
  };
in
{
  xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" settings;
  xdg.configFile."herdr/plugins/config/persiyanov.reviewr/config.toml".source =
    tomlFormat.generate "reviewr-config.toml" reviewr;
  xdg.configFile."herdr/plugins/local/reviewr-focus/herdr-plugin.toml".source = reviewrFocusPlugin;

  home.activation.linkHerdrReviewrFocus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${herdr} plugin link "${config.xdg.configHome}/herdr/plugins/local/reviewr-focus" >/dev/null
    ${herdr} server reload-config >/dev/null 2>&1 || true
  '';
}
