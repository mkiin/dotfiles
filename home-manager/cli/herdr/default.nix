{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;

    keys = {
      # prefix→単一文字を wezterm(LEADER+文字) に一致させる。chord は全廃。
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";

      # navigate モードは素の hjkl（prefix+ 不可のフィールド）
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
          command = "persiyanov.reviewr.toggle";
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
    default_scope = "last-turn";
    navigator_position = "left";
    toggle_placement = "zoomed";
  };
in
{
  xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" settings;
  xdg.configFile."herdr/plugins/config/persiyanov.reviewr/config.toml".source =
    tomlFormat.generate "reviewr-config.toml" reviewr;
}
