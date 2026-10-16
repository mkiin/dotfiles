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
        "noctalia/bitwarden"
        "noctalia/mpvpaper"
        "noctalia/screen_recorder"
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
      ];
    };

    plugin_settings."noctalia/screen_recorder" = {
      video_source = "focused";
      frame_rate = 30;
      audio_codec = "aac";
    };

    plugin_settings."noctalia/mpvpaper" = {
      video_directory = videoDir;
      picker_placement = "floating";
    };
  };
}
