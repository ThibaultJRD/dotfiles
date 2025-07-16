return {
  "nvim-neotest/neotest",
  dependencies = {
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
  },
  opts = {
    adapters = {
      ["neotest-vitest"] = {},
      ["neotest-jest"] = {
        jestCommand = "npm test --",
        env = { CI = true },
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
    },
  },
}
