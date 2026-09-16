{ vars, ... }:
{
  home = {
    inherit (vars) username;
    stateVersion = "25.11";
  };
}
