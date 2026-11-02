return {
  "ChmaraX/herdr-nvim",
  opts = {
    -- hunk-diff covers review comments and <leader>cx covers references.
    -- The sidebar daemon calls setup() itself, so this spec must stay to keep its default keymaps off.
    keymaps = false,
  },
}
