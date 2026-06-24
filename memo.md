- calendarは私指定のものを使うこと
- custom/ - pacmanのアイコンがなぜかarchlinuxになっている。
- aurのアイコンがpacmanになっている
- miseのアイコンがレンダリングされていない。何を使うかわからん。
- networkはアイコン単体にしますか。wifiの強度変化は採用
- temeratureのアイコンが表示されていません。BlackNodeのものを採用する

Q3. swayncでいきます

Q4. (%R)はいらない

Q5. calendarは後に触る

A. でいきます

↓　理想
1 2 3 4
5 6 7 8
9 A B C


↓現実
1 4 7 A
2 5 8 B
3 6 9 C


# Nixのコマンド備忘録

## home-manager・flake

### nix flake show

### nix run nixpkgs#home-manager -- build --flake .#casyos

コマンド解説

*nix run nixpkgs#とは*
`home-manager`コマンドをローカルにインストールせず、その場だけで Nix Storeから取り出して実行する方法
-> npxのようなもの？
-> `home-manager -- build --flake .#casyos`

*`--buildとは`*
`home-manager`のサブコマンド
`--`で`home-manager`への引数がここから始まるよという区切りを伝えている。

### nix run nixpkgs#home-manager -- switch --flake .#cachyos -b hm-pre-migration

*`hm-pre-migration`とは*
このオプションにより衝突したファイルを`.hm-pre-migration`にリネームしバックアップしてくれる


