--[[
Author: Uyanide pywang0608@foxmail.com
Date: 2025-06-14 20:23:25
LastEditTime: 2025-08-01 15:34:21
Discription:
--]]
return {
  {
    "catppuccin/nvim",
    opts = {
      flavor = "mocha",
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
