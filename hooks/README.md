# pacman hooks

## 99-sync-user-packages.hook

pacman / yay で install / remove / upgrade が走るたびに
`scripts/sync-packages.sh` を自動実行し、`packages/*.txt` を最新化する。

### デプロイ

```bash
sudo install -m 644 -o root -g root \
  hooks/99-sync-user-packages.hook \
  /etc/pacman.d/hooks/99-sync-user-packages.hook
```

### 動作確認

```bash
sudo pacman -S --needed tree    # 何でもいい install
ls -la packages/pacman.txt      # timestamp が更新されていれば OK
```

### 無効化

```bash
sudo rm /etc/pacman.d/hooks/99-sync-user-packages.hook
```
