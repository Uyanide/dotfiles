local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.initial_cols = 96
config.initial_rows = 32

config.font_size = 12
config.font = wezterm.font("Maple Mono NF CN")
config.color_scheme = "Catppuccin Mocha"

config.hide_tab_bar_if_only_one_tab = true

config.window_background_opacity = 0.95

config.default_prog = { "/usr/bin/fish" }

config.window_close_confirmation = "NeverPrompt"

return config
