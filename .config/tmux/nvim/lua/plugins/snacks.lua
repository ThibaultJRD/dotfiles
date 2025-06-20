return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        files = {
          hidden = false,
          ignored = false,
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
