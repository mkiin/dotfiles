{
  config,
  myvars,
  pkgs,
  ...
}:
let
  videoDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/wallpaper/videos";
in
{
  home.packages = with pkgs; [
    gpu-screen-recorder
    mpvpaper
    mpv
    socat
  ];

  programs.noctalia.settings = {
    plugins = {
      enabled = [
        "mkiin/wallpaper-picker"
        "noctalia/bitwarden"
        "noctalia/screen_recorder"
        "tranzem/media-lyrics"
      ];
      auto_update = "all";
      source = [
        {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = true;
        }
        {
          name = "community";
          kind = "git";
          location = "https://github.com/noctalia-dev/community-plugins";
          enabled = true;
        }
        {
          name = "mkiin";
          kind = "git";
          location = "https://github.com/mkiin/noctalia-plugins";
          enabled = true;
        }
      ];
    };

    plugin_settings."noctalia/screen_recorder" = {
      video_source = "focused";
      frame_rate = 30;
      audio_codec = "aac";
    };

    plugin_settings."mkiin/wallpaper-picker" = {
      video_directory = videoDir;
    };
  };
}
