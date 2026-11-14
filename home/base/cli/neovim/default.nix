{
  inputs,
  myvars,
  config,
  pkgs,
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
    configDir = ./.;
    lockDir = ./nvimx-lock;
    extraWrapperArgs = [
      "--set"
      "NVIM_CONFIG_SOURCE"
      "${config.home.homeDirectory}/${myvars.dotfilesdir}/home/base/cli/neovim"
    ];
    extraPackages = with pkgs; [
      git
      ripgrep
      fd
    ];

    lock = {
      projectDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}";
      configDirRelative = "home/base/cli/neovim";
      lockDirRelative = "home/base/cli/neovim/nvimx-lock";
    };
  };
}
