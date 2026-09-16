{ homeDirectory, username, ... }:
{
  xdg.configFile."obsidian/obsidian.json".text = builtins.toJSON {
    vaults."0b51d2e4a1c37f96" = {
      path = "${homeDirectory}/ghq/github.com/${username}/obsidian-store";
      ts = 1753833600000;
      open = true;
    };
  };
}
