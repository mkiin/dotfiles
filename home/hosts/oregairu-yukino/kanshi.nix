{
  services.kanshi.settings = [
    {
      profile = {
        name = "desktop";
        outputs = [
          {
            criteria = "DP-1";
            status = "enable";
            position = "0,0";
            scale = 1.0;
            mode = "1920x1080@60Hz";
          }
          {
            criteria = "DP-2";
            status = "enable";
            position = "1920,0";
            scale = 1.0;
            mode = "2560x1440@180Hz";
          }
          {
            criteria = "DP-3";
            status = "enable";
            position = "4480,0";
            scale = 1.0;
            mode = "1920x1080@144Hz";
          }
        ];
      };
    }
  ];
}
