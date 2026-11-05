{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      test = pkgs.writeShellScript "test-block-device" ''
        if [ "$1" = -b ] && [ "$2" = /dev/mock ]; then exit 0; fi
        exec ${pkgs.coreutils}/bin/test "$@"
      '';
      lsblk = pkgs.writeShellScript "lsblk" ''
        case "$*" in
          *MOUNTPOINTS*) printf '%s\n' "$MOCK_MOUNTS" ;;
          *PKNAME*) printf '%s\n' "$MOCK_PARENT" ;;
          *) exit 2 ;;
        esac
      '';
      findmnt = pkgs.writeShellScript "findmnt" ''
        if [ -z "$MOCK_SOURCE" ]; then exit 1; fi
        printf '%s\n' "$MOCK_SOURCE"
      '';
      tests = pkgs.writeText "installer-tests" ''
        use std/assert
        assert equal ("input" | checked ${pkgs.coreutils}/bin/cat) "input"
        assert (try { checked ${pkgs.coreutils}/bin/false; false } catch { true })

        $env.MOCK_MOUNTS = ""
        $env.MOCK_SOURCE = ""
        $env.MOCK_PARENT = "mock"
        check-disk /dev/mock false
        assert (try { check-disk /dev/null false; false } catch { true })
        for mounted in ["/home" "[SWAP]"] {
          $env.MOCK_MOUNTS = $mounted
          assert (try { check-disk /dev/mock false; false } catch { true })
        }
        $env.MOCK_MOUNTS = ""
        $env.MOCK_SOURCE = "/dev/mock1"
        assert (try { check-disk /dev/mock false; false } catch { true })
        check-disk /dev/mock true
        $env.MOCK_PARENT = "other"
        assert (try { check-disk /dev/mock true; false } catch { true })
        $env.MOCK_SOURCE = ""
        assert (try { check-disk /dev/mock true; false } catch { true })

        checked ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C "" -f identity
        let key = checked ${pkgs.openssh}/bin/ssh-keygen -y -f identity | str trim
        for content in ["first value" "replacement value"] {
          $content | checked ${pkgs.age}/bin/age --recipient $key --output secret.age
          assert equal (checked ${pkgs.age}/bin/age --decrypt --identity identity secret.age) $content
        }
        mkdir fixture/hosts/oregairu-yukino fixture/secrets
        cp ${../hosts/oregairu-yukino/disko.nix} fixture/hosts/oregairu-yukino/disko.nix
        checked ${pkgs.coreutils}/bin/chmod u+w fixture/hosts/oregairu-yukino/disko.nix
        configure-host fixture oregairu-yukino /dev/disk/by-id/mock $key | ignore
        let keys = checked ${pkgs.nix}/bin/nix-instantiate --eval --strict --json fixture/secrets/host-keys.nix | from json
        assert equal $keys.oregairu-yukino $key
        assert equal ($keys | columns | sort) [oregairu-yui oregairu-yukino]
        let device = checked ${pkgs.nix}/bin/nix-instantiate --eval --strict --json --expr "(import ./fixture/hosts/oregairu-yukino/disko.nix).disko.devices.disk.system.device" | from json
        assert equal $device /dev/disk/by-id/mock
        assert (try { configure-host fixture oregairu-yukino /dev/sda $key; false } catch { true })
        assert (try { configure-host fixture oregairu-yukino /dev/disk/by-id/mock "invalid-key"; false } catch { true })
        print "PASS: disk guards, resume checks, age round-trip, generated Nix configuration"
      '';
    in
    {
      checks.installer = pkgs.runCommand "installer-checks" { } ''
        export NIX_REMOTE=dummy:// NIX_STATE_DIR="$TMPDIR/nix-state"
        for host in oregairu-yukino oregairu-yui; do
          ${config.apps.install.program} "$host" --dry-run > /dev/null
          ${config.apps.reinstall.program} "$host" --dry-run > /dev/null
        done
        if ${config.apps.install.program} unknown-host --dry-run; then exit 1; fi
        if ${config.apps.reinstall.program} unknown-host --dry-run; then exit 1; fi
        if ${config.apps.install.program} oregairu-yui --unknown; then exit 1; fi
        if ${config.apps.reinstall.program} oregairu-yui --prepare recovery.age; then exit 1; fi

        substitute ${config.apps.install.program} install-script \
          --replace-fail '${pkgs.coreutils}/bin/test' '${test}' \
          --replace-fail '${pkgs.util-linux}/bin/lsblk' '${lsblk}' \
          --replace-fail '${pkgs.util-linux}/bin/findmnt' '${findmnt}'
        ${lib.getExe pkgs.nushell} --no-config-file --commands "source install-script; source ${tests}"
        touch $out
      '';
    };
}
