{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gpu-screen-recorder
    slurp
  ];

  programs.noctalia.settings = {
    plugins = {
      enabled = [
        "noctalia/bitwarden"
        "mkiin/screen_recorder"
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
          name = "mkiin-screen-recorder";
          kind = "git";
          location = "ssh://git@github.com/mkiin/screen-recorder.git";
          enabled = true;
        }
      ];
    };

    plugin_settings."mkiin/screen_recorder" = {
      video_source = "focused";
      replay_enabled = true;
      frame_rate = 30;
      audio_codec = "aac";
    };
  };
}
