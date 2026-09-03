{
  inputs,
  pkgs,
  dotfilesDir,
  ...
}:
let
  dir = "${dotfilesDir}/images/wallpaper";
  namer = inputs.wallpaper-namer.packages.${pkgs.system}.default;
in
{
  # 手動リトライ用（wallpaper-namer <path>... / --force）。
  # GEMINI_API_KEY は手動時のみ `set -a; source /run/agenix/gemini-api-key.env` で読み込む。
  home.packages = [ namer ];

  home.sessionVariables.WALLPAPER_DIR = dir;

  systemd.user.paths.wallpaper-namer = {
    Unit.Description = "Watch wallpaper dir and name new wallpapers";
    Path.PathModified = dir;
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.wallpaper-namer = {
    Unit.Description = "Name new wallpapers with Gemini and rename to slugs";
    Service = {
      Type = "oneshot";
      Environment = "WALLPAPER_DIR=${dir}";
      EnvironmentFile = "/run/agenix/gemini-api-key.env";
      ExecStart = "${namer}/bin/wallpaper-namer";
      ExecStartPost = "${pkgs.pyprland}/bin/pypr reload";
    };
  };
}
