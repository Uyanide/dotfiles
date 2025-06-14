return {
  {
    "catppuccin/nvim",
    opts = {
      flavor = "mocah",
      transparent_background = true,
      styles = {
        functions = { "bold" },
        keywords = { "bold" },
      },
    },
  },
  -- {
  --   "olimorris/onedarkpro.nvim",
  --   priority = 1000, -- Ensure it loads first
  --   config = function()
  --     require("onedarkpro").setup({
  --       options = {
  --         transparency = true,
  --       },
  --       styles = {
  --         comments = "italic",
  --         keywords = "bold",
  --       },
  --     })
  --     require("onedarkpro").load()
  --   end,
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

-- return {
--   {
--     "folke/tokyonight.nvim",
--     lazy = true,
--     opts = {
--       style = "moon",
--     },
--   },
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "tokyonight",
--     },
--   },
-- }
