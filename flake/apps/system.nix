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

      isAgentCheck = ''
        def is-ai-agent [] {
          [
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
          ] | any {|name| $env | get --optional $name | default "" | is-not-empty }
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
              ${isAgentCheck}
              ${resolveHost}

              def main [name?: string] {
                let host = resolve-host $name
                let quoted_host = $host | to json --raw
                let target = $".#nixosConfigurations.($quoted_host).config.system.build.toplevel"

                print $"Building NixOS configuration: ($host)"

                if (is-ai-agent) {
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
              ${isAgentCheck}
              ${resolveHost}

              def main [name?: string] {
                let host = resolve-host $name
                let target = $".#($host)"
                let quoted_host = $host | to json --raw
                let build_target = $".#nixosConfigurations.($quoted_host).config.system.build.toplevel"

                let builder = if (is-ai-agent) {
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
