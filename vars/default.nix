let
  username = "mkiin";
in
{
  inherit username;
  userfullname = "mkiin";
  useremail = "blckcaties@gmail.com";
  linuxhomedir = "/home/${username}";
  darwinhomedir = "/Users/${username}";
  dotfilesdir = "ghq/github.com/mkiin/dotfiles";

  sshPublicKeys.iphone13-termius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE4VbL5bvm7c7QffgB6DnypzQJIfqQbPJrREf5CYmiW iphone13-termius";

  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMx2dRGve60InCdio56Go1Rm+B7vVcHZb9UlQoHeO4K mkiin@oregairu-yukino"
  ];
}
