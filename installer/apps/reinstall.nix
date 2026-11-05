{ ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      writeNu,
      config,
      ...
    }:
    let
      core = command: lib.getExe' pkgs.coreutils command;
    in
    {
      apps.reinstall = {
        type = "app";
        program = toString (
          writeNu "reinstall-nixos-host" ''
            def --wrapped checked [program: string, ...args: string] {
              do --capture-errors { ^$program ...$args }
            }

            def main [host?: string, --prepare: path, --dry-run, --resume] {
              if $prepare != null {
                if $host != null or $dry_run or $resume { error make {msg: "--prepareは単独で指定してください。"} }
                let output = $prepare | path expand
                if ($output | path exists) { error make {msg: "復旧ファイルは上書きしません。別の保存先を指定してください。"} }
                checked ${core "test"} -t 0
                if (checked ${core "id"} -u | str trim) != "0" {
                  exec /run/wrappers/bin/sudo (path self) --prepare $output
                }
                let secrets = [user-password rclone-r2.conf] | each {|name|
                  let file = $env.PWD | path join secrets $"($name).age"
                  {name: $name, value: (checked ${lib.getExe pkgs.age} --decrypt --identity /etc/ssh/ssh_host_ed25519_key $file)}
                } | transpose --header-row --as-record
                let encrypted = $secrets | to json | checked ${lib.getExe pkgs.age} --passphrase --armor
                $encrypted | save $output
                try {
                  print "保存した復旧ファイルを確認します。パスフレーズをもう一度入力してください。"
                  let restored = checked ${lib.getExe pkgs.age} --decrypt $output | from json
                  if $restored != $secrets { error make {msg: "復旧ファイルの確認に失敗しました。"} }
                } catch {|error|
                  checked ${core "rm"} -f $output
                  error make {msg: $error.msg}
                }
                checked ${core "chmod"} 644 $output
                checked ${core "chown"} --reference ($output | path dirname) $output
                print $"復旧ファイルを保存しました: ($output)"
                print "この暗号化ファイルをcommit・pushすると、ISOから使えます。"
                return
              }
              if $host == null { error make {msg: "ホスト名を指定してください。"} }
              let flags = if $resume { [--resume] } else { [] }
              let recovery = '${../../secrets}/recovery.age'
              if $dry_run { exec ${config.apps.install.program} $host --dry-run --recovery $recovery ...$flags }
              checked ${config.apps.install.program} $host --dry-run --recovery $recovery | ignore
              if not ($recovery | path exists) {
                error make {msg: "復旧ファイルがありません。先にYuiで --prepare ./secrets/recovery.age を実行し、commit・pushしてください。"}
              }
              checked ${core "test"} -t 0
              if (checked ${core "id"} -u | str trim) != "0" {
                exec /run/wrappers/bin/sudo (path self) $host ...$flags
              }
              let work = checked ${core "mktemp"} -d /run/dotfiles-recovery.XXXXXX | str trim
              try {
                let file = $work | path join secrets.json
                checked ${core "touch"} $file
                checked ${core "chmod"} 600 $file
                checked ${lib.getExe pkgs.age} --decrypt $recovery | save --force $file
                checked ${config.apps.install.program} $host --recovery $file ...$flags
              } catch {|error|
                checked ${core "rm"} -rf $work
                error make {msg: $error.msg}
              }
              checked ${core "rm"} -rf $work
            }
          ''
        );
      };
    };
}
