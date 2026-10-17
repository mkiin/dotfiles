{
  inputs,
  myvars,
  config,
  ...
}:
{
  imports = [ inputs.nvimx.homeModules.nvimx ];

  programs.nvimx = {
    enable = true;
    configDir = ./neovim;
    lockDir = ./neovim/nvimx-lock;

    lock = {
      projectDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}";
      configDirRelative = "home/base/terminal/neovim";
      lockDirRelative = "home/base/terminal/neovim/nvimx-lock";
    };
  };
}
