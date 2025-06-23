return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true,
        ignored = true,
        sources = {
          files = {
            hidden = true,
          },
        },
        win = {
          list = {
            keys = {
              ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
            },
          },
        },
      },
    },
  },
}
