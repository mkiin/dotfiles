{
  perSystem =
    {
      pkgs,
      lib,
      writeNu,
      ...
    }:
    let
      # nixos-anywhere 1.13 disables host-key checking on its installer SSH
      # connections. Carry each one inside SSH to the pinned Live environment.
      liveProxy = pkgs.writeShellScript "live-ssh-proxy" ''
        exec ${lib.getExe' pkgs.openssh "ssh"} -T \
          -o BatchMode=yes -o StrictHostKeyChecking=yes -o ControlPath=none \
          -o ForwardAgent=no -W 127.0.0.1:22 "root@$LIVE_HOST"
      '';
      installer = pkgs.writeShellApplication {
        name = "install-from-live";
        runtimeInputs = with pkgs; [
          age
          coreutils
          diffutils
          gawk
          jq
          nix
          nixos-anywhere
          openssh
          util-linux
        ];
        runtimeEnv.LIVE_SSH_PROXY = "${liveProxy}";
        text = builtins.readFile ./remote-install.sh;
      };
    in
    {
      apps.remote-install = {
        type = "app";
        program = toString (
          writeNu "remote-install" ''
            def main [] { help main }

            # Generate a fresh production host key on yukino.
            def "main prepare" [host: string] {
              exec ${lib.getExe installer} prepare $host
            }

            # Erase the specified disk and install from the running Minimal ISO.
            def "main apply" [host: string, live: string, --erase: string, --recovery-key: path] {
              if ($erase == null) or ($recovery_key == null) {
                error make {msg: "Specify --erase /dev/disk/by-id/<SSD> and --recovery-key <USB private key>."}
              }
              exec ${lib.getExe installer} apply $host $live $erase $recovery_key
            }
          ''
        );
      };

      apps.remote-switch = {
        type = "app";
        program = toString (
          writeNu "remote-switch" ''
            # Build on yukino and activate over SSH as root on the named host.
            def main [host: string, --target: string] {
              let address = $target | default $host
              if ($host !~ '^[a-zA-Z0-9][a-zA-Z0-9-]*$') or ($address !~ '^[a-zA-Z0-9][a-zA-Z0-9.-]*$') {
                error make {msg: "Use a hostname for the flake host and an SSH alias, DNS name or IPv4 address for --target."}
              }
              let pin = $'~/.ssh/dotfiles-hosts/($host)'
              if not ($pin | path expand | path exists) {
                error make {msg: $"Missing production host pin: ($pin)"}
              }
              let options = [
                "-o" "StrictHostKeyChecking=yes" "-o" $"HostKeyAlias=($host)"
                "-o" $"UserKnownHostsFile=($pin)" "-o" "GlobalKnownHostsFile=/dev/null"
                "-o" "HostKeyAlgorithms=ssh-ed25519" "-o" "UpdateHostKeys=no"
                "-o" "ControlPath=none" "-o" "ForwardAgent=no"
              ]
              let remote = $"root@($address)"
              let result = ^${lib.getExe' pkgs.openssh "ssh"} ...$options $remote hostname | complete
              if ($result.exit_code != 0) or (($result.stdout | str trim) != $host) {
                error make {msg: $"Could not verify root@($address) as ($host). ($result.stderr)"}
              }
              let configured = ^${lib.getExe pkgs.nix} eval --raw $".#nixosConfigurations.($host).config.networking.hostName" | complete
              if ($configured.exit_code != 0) or ($configured.stdout != $host) {
                error make {msg: $"The flake does not define the expected hostname ($host). ($configured.stderr)"}
              }
              $env.NIX_SSHOPTS = ($options | str join " ")
              exec ${lib.getExe' pkgs.nixos-rebuild-ng "nixos-rebuild"} switch --flake $".#($host)" --target-host $remote
            }
          ''
        );
      };
    };
}
