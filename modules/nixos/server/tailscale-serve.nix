{
  config,
  lib,
  pkgs,
  ...
}:

let
  serve = config.services.tailscale.serve;
  tailscale = lib.getExe config.services.tailscale.package;

  mkServeCommand =
    name: service:
    "${tailscale} ${
      lib.escapeShellArgs [
        "serve"
        "--yes"
        "--service=svc:${name}"
        "--https=443"
        service.endpoints."tcp:443"
      ]
    }";
in
{
  config = lib.mkIf (serve.enable && serve.configFile == null) {
    # The standard JSON format derives the incoming protocol from the target.
    # The CLI lets Serve terminate HTTPS before forwarding to an HTTP target.
    systemd.services.tailscale-serve.serviceConfig.ExecStart = lib.mkForce (
      pkgs.writeShellScript "tailscale-serve-apply" ''
        set -e
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkServeCommand serve.services)}
      ''
    );
  };
}
