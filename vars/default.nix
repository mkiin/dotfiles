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

  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF71Mzulg4F9wwvfYVlf6r5HcWGFAwyt1ghl1N2p3oQ7 root@oregairu-yukino"
  ];
}
