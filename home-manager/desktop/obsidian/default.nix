{ homeDirectory, username, ... }:
{
  # vault 一覧は obsidian.json にしか無く、GUI の "Open folder as vault" が唯一の登録手段。
  # Obsidian は起動時の書き戻しに失敗しても "Ignored" で継続するため read-only symlink で足りる。
  # 副作用として GUI 側での vault 追加・削除は永続化されない(ここが単一情報源)。
  xdg.configFile."obsidian/obsidian.json".text = builtins.toJSON {
    vaults."0b51d2e4a1c37f96" = {
      path = "${homeDirectory}/ghq/github.com/${username}/obsidian-store";
      ts = 1753833600000;
      open = true;
    };
  };
}
