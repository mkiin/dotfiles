{ myvars, ... }:
{
  imports = [ ../base/core ];

  home.homeDirectory = "/home/${myvars.username}";
}
