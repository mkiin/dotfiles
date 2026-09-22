{ lib, ... }:
{
  scanPaths =
    dir:
    let
      entries = builtins.readDir dir;
    in
    map (name: dir + "/${name}") (
      builtins.attrNames (
        lib.filterAttrs (
          name: type:
          if type == "directory" then
            builtins.pathExists (dir + "/${name}/default.nix")
          else
            name != "default.nix" && lib.hasSuffix ".nix" name
        ) entries
      )
    );
}
