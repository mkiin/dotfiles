{
  inputs,
  myvars,
  config,
  pkgs,
  lib,
  ...
}:
let
  nvim = config.programs.nvimx;
  luaLibrary = pkgs.symlinkJoin {
    name = "neovim-lua-library";
    paths = map (path: "${path}/lua") (
      [
        "${nvim.package}/share/nvim/runtime"
        "${nvim.env.farm}/lazy.nvim"
      ]
      ++ lib.attrValues nvim.env.pluginDrvs
    );
  };
in
{
  imports = [ inputs.nvimx.homeModules.nvimx ];

  # Both editors read the same locked runtime and plugin definitions through LuaLS.
  xdg.dataFile."nvim/lua-library".source = luaLibrary;

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
      "${config.home.homeDirectory}/${myvars.dotfilesdir}/home/base/core/neovim"
    ];
    extraPackages = with pkgs; [
      git
      ripgrep
      fd
    ];

    lock = {
      projectDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}";
      configDirRelative = "home/base/core/neovim";
      lockDirRelative = "home/base/core/neovim/nvimx-lock";
    };
  };
}
