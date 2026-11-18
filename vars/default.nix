let
  username = "mkiin";
in
{
  inherit username;
  networking = import ./networking.nix;
  sshPublicKeys = import ./ssh-keys.nix;
  userfullname = "mkiin";
  useremail = "blckcaties@gmail.com";
  linuxhomedir = "/home/${username}";
  darwinhomedir = "/Users/${username}";
  dotfilesdir = "ghq/github.com/mkiin/dotfiles";
}
