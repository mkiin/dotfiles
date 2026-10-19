# niri + Kanshi

Greeterからniriを起動する。標準のniri-sessionがsystemdのユーザーセッションを開始し、終了時に関連サービスを停止する。Kanshiはniri.serviceに連動する。Home Managerのsystemd.enable=falseはユニットの重複インストールを避ける指定で、NixOS側の統合は有効。

Noctaliaはspawn-at-startupから一度だけ起動する。クラッシュ時の自動再起動はない。アイドル管理とロックもNoctaliaを使用し、900秒でロック、1800秒で消灯、3600秒でロック後サスペンドする。従来のplayerctlによる再生中判定は廃止し、NoctaliaとWaylandのidle inhibitionに従う。

systemd統合ではjournalctl --user -u niri -u kanshiでログを確認でき、サービスの再起動と終了を管理できる。起動順序とWAYLAND_DISPLAYなどの環境変数を正しく渡す必要があるため、独自起動スクリプトを追加せず標準セッションを使う。

出力は各ホストのkanshi.nixだけで管理する。Yuiのdock構成は実機情報取得後に追加する。niri msg outputsでconnector、モード、シリアルを確認する。Yukinoは既存の60/180/144Hzを仮採用している。

実機ではOverview、感度、モニター抜き差し、ロックと復帰、画面共有、X11アプリ、NVIDIAの出力を検証する。nixos-rebuild switchはこの変更作業では実行しない。

時間は各home/hosts/<host>/default.nixのmodules.desktop.noctalia.idleで秒単位で設定する（lockTimeout / screenOffTimeout / suspendTimeout）。

上下操作はJ=下、K=上。Mod+J/Kはウィンドウフォーカス、Mod+Shift+J/Kはウィンドウ移動、Mod+Ctrl+J/KはWorkspaceフォーカス、Mod+Shift+Down/UpはWorkspace間のColumn移動。高さ変更はMod+Shift+Minus/Equal、幅変更はMod+Minus/Equal。

左右操作はH=左、L=右。Mod+Shift+H/LはColumnの並べ替え、Mod+Ctrl+H/Lはモニターフォーカス、Mod+Shift+Left/Rightはモニター間のColumn移動。
