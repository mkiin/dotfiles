{ myvars, ... }:
{
  security.polkit.enable = true;
  # security with GNOME Keyring
  services.gnome = {
    gnome-keyring.enable = true;
    gcr-ssh-agent.enable = false;
  };

  # seahorse is a GUI App for GNOME Keyring.
  # Pitfall: never use seahorse's "New -> Default keyring". pam_gnome_keyring
  # hardcodes the keyring name "login" (unlocks/syncs only login.keyring),
  # while Secret Service apps (gh, browsers) use the keyring named in
  # ~/.local/share/keyrings/default. Creating a separate "Default keyring"
  # forks secrets into a second container whose password never syncs with the
  # login password, causing "Unlock Login Keyring" prompt desyncs.
  # Keep everything in "login" and leave the `default` pointer unset (or
  # pointing at "login").
  programs.seahorse.enable = true;

  programs.ssh.startAgent = true;

  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.passwd.enableGnomeKeyring = true;
  security.pam.services.hyprlock = { };

  # programs.gnupg.agent = {
  #   enable = true;
  #   pinentryPackage = pkgs.pinentry-qt;
  #   enableSSHSupport = false;
  #   settings.default-cache-ttl = 4 * 60 * 60; # 4 hours
  # };
  #
  security.sudo.extraRules = [
    {
      users = [ "${myvars.username}" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
