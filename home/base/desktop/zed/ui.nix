{ lib, ... }:
{
  programs.zed-editor.userSettings = {
    theme = "Kanagawa Wave";

    auto_signature_help = true;
    code_lens = "on";
    completion_menu_item_kind = "symbol";
    completions.lsp_fetch_timeout_ms = 2000;

    diagnostics.inline.enabled = true;
    document_folding_ranges = "off";
    inlay_hints.enabled = true;

    semantic_tokens = "combined";
    soft_wrap = "editor_width";
    vertical_scroll_margin = 10.0;
    which_key.enabled = true;

    tabs = {
      file_icons = true;
      git_status = true;
    };

    title_bar = {
      show_branch_status_icon = true;
      show_menus = false;
      show_user_menu = true;
    };

    project_panel = {
      dock = "left";
      default_width = 280;
      entry_spacing = "standard";
    };

    ui_font_family = lib.mkDefault "LXGW WenKai Screen";
    ui_font_size = lib.mkDefault 20.0;

    buffer_font_family = lib.mkDefault "Maple Mono NF CN";
    buffer_font_size = lib.mkDefault 18.0;

    agent_ui_font_size = lib.mkDefault 16.0;
    agent_buffer_font_size = lib.mkDefault 15.0;
  };
}
