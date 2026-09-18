return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		-- 編集中(insert)は生テキスト・閲覧時のみ装飾。カーソル行だけ生に戻して編集しやすく
		anti_conceal = { enabled = true },
		-- サイン列は使わないのでカーソル移動時のガタつきを避けて無効化
		sign = { enabled = false },
		code = {
			-- 背景のみ付ける控えめ表示("full"=言語ラベル付き全幅 / "none"=装飾なし)
			style = "normal",
			left_pad = 1,
		},
	},
}
