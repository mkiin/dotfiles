{ ... }:

let
  browser = [ "zen-beta.desktop" ];
  editor = [ "nvim.desktop" ];
  imageViewer = [ "imv-dir.desktop" ];
  mediaPlayer = [ "mpv.desktop" ];
  fileManager = [ "yazi.desktop" ];
in
{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Browser
      "text/html" = browser;
      "application/xhtml+xml" = browser;
      "application/pdf" = browser;

      # URL scheme handlers
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;

      # Application-specific schemes
      "x-scheme-handler/obsidian" = [ "obsidian.desktop" ];
      "x-scheme-handler/steam" = [ "steam.desktop" ];

      # Text
      "text/plain" = editor;

      # Images
      "image/*" = imageViewer;
      "image/gif" = imageViewer;
      "image/jpeg" = imageViewer;
      "image/png" = imageViewer;
      "image/webp" = imageViewer;

      # Media
      "audio/*" = mediaPlayer;
      "video/*" = mediaPlayer;

      # Directory
      "inode/directory" = fileManager;
    };
  };
}
