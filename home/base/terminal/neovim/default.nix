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
    configDir = ./lua;
    lockDir = ./nvimx-lock;

    lock = {
      projectDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}";
      configDirRelative = "home/base/terminal/neovim/lua";
      lockDirRelative = "home/base/terminal/neovim/nvimx-lock";
    };
  };
}
