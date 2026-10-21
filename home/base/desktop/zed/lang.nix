{ pkgs, ... }:

let
  oxcLanguage = {
    formatter.language_server.name = "oxfmt";

    language_servers = [
      "typescript-ls"
      "oxlint"
      "oxfmt"
      "!vtsls"
      "!typescript-language-server"
      "!eslint"
    ];
  };
in
{
  programs.zed-editor.userSettings = {
    languages = {
      TypeScript = oxcLanguage;
      TSX = oxcLanguage;
      JavaScript = oxcLanguage;
      JSX = oxcLanguage;

      Rust = {
        hard_tabs = false;
        formatter.language_server.name = "rust-analyzer";
        language_servers = [
          "rust-analyzer"
          "!rustc"
        ];
      };

      C = {
        formatter.language_server.name = "clangd";
        language_servers = [ "clangd" ];
      };

      "C++" = {
        formatter.language_server.name = "clangd";
        language_servers = [ "clangd" ];
      };

      Lua.formatter.external = {
        command = "stylua";
        arguments = [
          "--stdin-filepath"
          "{buffer_path}"
          "-"
        ];
      };

      Luau = {
        formatter.external = {
          command = "stylua";
          arguments = [
            "--stdin-filepath"
            "{buffer_path}"
            "-"
          ];
        };

        language_servers = [ "luau-lsp" ];
      };

      "Shell Script" = {
        formatter.external = {
          command = "shfmt";
          arguments = [
            "--filename"
            "{buffer_path}"
          ];
        };

        language_servers = [ "bash-language-server" ];
      };

      JSON.formatter.language_server.name = "oxfmt";
      JSONC.formatter.language_server.name = "oxfmt";

      Nix = {
        formatter.external = {
          command = "nixfmt";
          arguments = [ ];
        };

        language_servers = [ "nixd" ];
      };

      Python = {
        formatter.language_server.name = "ruff";

        language_servers = [
          "ty"
          "ruff"
          "!basedpyright"
          "!pyrefly"
          "!pyright"
          "!pylsp"
        ];
      };
    };

    lsp = {
      luau-lsp.settings.binary.path = "${pkgs.luau-lsp}/bin/luau-lsp";

      oxlint.binary = {
        path = "${pkgs.oxlint}/bin/oxlint";
        arguments = [ "--lsp" ];
      };

      oxfmt.binary = {
        path = "${pkgs.oxfmt}/bin/oxfmt";
        arguments = [ "--lsp" ];
      };

      oxlint.initialization_options.settings = {
        run = "onType";
        fixKind = "safe_fix";
        disableNestedConfig = false;
        unusedDisableDirectives = "deny";
      };

      rust-analyzer.initialization_options.check.command = "clippy";
    };
  };
}
