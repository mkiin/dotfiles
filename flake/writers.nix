{
  perSystem =
    { pkgs, lib, ... }:
    let
      nu = lib.getExe pkgs.nushell;
      nuCheck = pkgs.writeShellScript "nu-check" ''
        exec ${nu} --no-config-file --command "nu-check" --debug '$1'"
      '';
    in
    {
      _module.args.writeNu = name: body: pkgs.writers.writeNu name { check = nuCheck; } body;
    };
}
