{ lib, ... }:
{
  programs.noctalia.settings.bar.capsule.end = lib.mkBefore [ "battery" ];
}
