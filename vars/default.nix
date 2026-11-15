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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMx2dRGve60InCdio56Go1Rm+B7vVcHZb9UlQoHeO4K mkiin@oregairu-yukino"
  ];

  secondaryAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/Z0T5864TMfjJFgKKNzD7IuheDAOo4fMJ1Yd8ZIF/T mkiin@recovery"
  ];
}
