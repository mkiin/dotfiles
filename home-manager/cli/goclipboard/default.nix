{ pkgs, ... }:

{
  home.packages = [
    (pkgs.buildGoModule {
      pname = "gocopy";
      version = "0.1.4";
      src = pkgs.fetchFromGitHub {
        owner = "atotto";
        repo  = "clipboard";
        rev   = "v0.1.4";
        hash  = "sha256-ZZ7U5X0gWOu8zcjZcWbcpzGOGdycwq0TjTFh/eZHjXk=";
      };
      subPackages = [ "cmd/gocopy" "cmd/gopaste" ];
      vendorHash = null;
    })
  ];
}
