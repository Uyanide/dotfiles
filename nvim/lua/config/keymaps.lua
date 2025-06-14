-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local km = vim.keymap

local map = vim.keymap.set

-- split windows horizontally and vertically
map("n", "<leader>sv", "<C-w>v")
map("n", "<leader>sh", "<C-w>s")

-- no highlight
map("n", "<leader>nh", ":nohl<CR>")

map("i", "jk", "<ESC>")
