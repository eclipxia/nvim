return {
	"junegunn/vim-easy-align",
	-- loads only when `ga` is pressed in a sql buffer (manual alignment, e.g. `ga1<Space>`)
	keys = { { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, ft = "sql", desc = "Easy align" } },
}
