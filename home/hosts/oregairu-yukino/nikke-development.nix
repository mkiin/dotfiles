{
  config,
  lib,
  pkgs,
  ...
}:
let
  repo = "/home/mkiin/ghq/github.com/mkiin/NIKKEAutoScript";
  prompt = pkgs.writeText "nikke-development-prompt" ''
    Continue the user's authorized NIKKE commission-claim work until 2026-11-03 20:00 Asia/Tokyo.
    Work only in ${repo} on branch linux-dispatch. The game is running, and 14 commissions
    were dispatched around 07:45; the first should finish around 09:15.
    Inspect the current game and script state. When completed commissions are available,
    run scripts/linux_dispatch/claim.py once, inspect the result, and fix any failure with
    the smallest necessary change. Run the relevant check and commit local code changes.
    Do not push, create timers for game claims, dispatch missions, buy items, or change game settings.
    If nothing is ready or the script already works, make no code change. Report what happened.
  '';
  run = pkgs.writeShellScript "nikke-development" ''
    exec ${lib.getExe config.programs.codex.package} exec \
      -C ${repo} -s danger-full-access - < ${prompt}
  '';
in
{
  systemd.user.services.nikke-development = {
    Unit.Description = "Improve NIKKE commission claim automation";
    Service = {
      Type = "oneshot";
      ExecStart = run;
      WorkingDirectory = repo;
      TimeoutStartSec = "45min";
    };
  };

  systemd.user.timers.nikke-development = {
    Unit.Description = "Check NIKKE commission automation until 20:00 today";
    Timer.OnCalendar = "2026-11-03 09,11,13,15,17,19:15:00";
    Install.WantedBy = [ "timers.target" ];
  };
}
