{
  inputs,
  myvars,
  config,
  ...
}:
{
  imports = [ inputs.nvimx.homeModules.nvimx ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.nvimx = {
    enable = true;
    configDir = ./lua;
    lockDir = ./nvimx-lock;

    lock = {
      projectDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}";
      configDirRelative = "home/base/cli/neovim/lua";
      lockDirRelative = "home/base/cli/neovim/nvimx-lock";
    };
  };
}
