return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        files = {
          hidden = true,
          ignored = true,
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
