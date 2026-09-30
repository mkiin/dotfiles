{ ... }:
{
  programs.noctalia.settings = {
    plugins = {
      enabled = [
        "noctalia/bitwarden"
        "noctalia/screen_recorder"
        "theblackdon/theme-switcher"
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
  };
}
