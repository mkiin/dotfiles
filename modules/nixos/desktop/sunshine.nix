{
  config,
  lib,
  hostVars,
  ...
}:
{
  options.modules.desktop.sunshine.enable =
    lib.mkEnableOption "Sunshine game streaming over Tailscale";

  config = lib.mkIf config.modules.desktop.sunshine.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = false;
      settings = {
        capture = "wlr";
        origin_web_ui_allowed = "pc";
        output_name = lib.mkIf (hostVars.primaryOutput != null) (lib.mkDefault hostVars.primaryOutput);
      };
    };

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        47984
        47989
        48010
      ];
      allowedUDPPorts = [
        47998
        47999
        48000
        48002
        48010
      ];
    };
  };
}
