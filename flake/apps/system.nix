{
  perSystem =
    {
      pkgs,
      lib,
      writeNu,
      ...
    }:
    let
      nom = lib.getExe pkgs.nix-output-monitor;

      nixBuildFlags = " --accept-flake-config --print-build-logs --show-trace";

      isNonInteractive = ''
        def is-non-interactive [] {
          let github_actions = (
            $env
            | get --optional GITHUB_ACTIONS
            | default ""
            | str lowercase
          ) == "true"

          let ai_agent = [
            CLAUDE_CODE
            CLAUDECODE
            CODEX_SANDBOX
            CODEX_THREAD_ID
            GEMINI_CLI
            OPENCODE
            AUGMENT_AGENT
            GOOSE_PROVIDER
            CURSOR_AGENT
            AI_AGENT
          ] | any {|name|
            $env
            | get --optional $name
            | default ""
            | is-not-empty
          }

          $github_actions or $ai_agent
        }
      '';
      resolveHost = ''
        def resolve-host [name: any] {
          if $name == null {
            sys host | get hostname
          } else {
            $name
          }
        }
      '';
    in
    {
      apps = {
        build = {
          type = "app";
          program = toString (
            writeNu "nixos-build" ''
              ${isNonInteractive}
              ${resolveHost}

              def main [name?: string] {
                let host = resolve-host $name
                let quoted_host = $host | to json --raw
                let target = $".#nixosConfigurations.($quoted_host).config.system.build.toplevel"

                print $"Building NixOS configuration: ($host)"

                if (is-non-interactive) {
                  exec nix build $target ${nixBuildFlags}
                } else {
                  exec ${nom} build $target ${nixBuildFlags}
                }
              }
            ''
          );
        };
        switch = {
          type = "app";
          program = toString (
            writeNu "nixos-switch" ''
              ${isNonInteractive}
              ${resolveHost}

              def main [name?: string] {
                let host = resolve-host $name
                let target = $".#($host)"
                let quoted_host = $host | to json --raw
                let build_target = $".#nixosConfigurations.($quoted_host).config.system.build.toplevel"

                let builder = if (is-non-interactive) {
                  "nix"
                } else {
                  "${nom}"
                }

                print $"Building NixOS configuration: ($host)"

                ^$builder build $build_target ${nixBuildFlags}

                let status = $env.LAST_EXIT_CODE
                if $status != 0 {
                  exit $status
                }

                print $"Switching to NixOS configuration: ($host)"

                exec sudo nixos-rebuild switch --flake $target
              }
            ''
          );
        };
      };
    };
}
