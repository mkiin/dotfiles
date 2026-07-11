{ lnk, ... }:
{
  xdg.configFile = {
    "rofi/config.rasi".source = lnk ./config.rasi;
    "rofi/themes/app-launcher.rasi".source = lnk ./app-launcher.rasi;
    "rofi/themes/capture.rasi".source = lnk ./capture.rasi;
    "rofi/launch.sh".source = lnk ./launch.sh;
  };
}
