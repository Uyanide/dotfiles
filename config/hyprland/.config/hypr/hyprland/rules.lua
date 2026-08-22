local c = require("hyprland/theme")

-- Most apps ask to be maximized on launch, which is rarely wanted when tiling.
hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland drag surfaces appear as empty floating windows; focusing them
-- breaks the drag.
hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Blurring XWayland makes their client-drawn shadows look wrong.
hl.window_rule({ name = "no-blur-xwayland", match = { xwayland = true }, no_blur = true })

hl.window_rule({ name = "no-shadow-tiled", match = { float = false }, no_shadow = true })

-- Dialogs

local dialogs = {
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Choose wallpaper)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Library)(.*)$",
    "^(File Upload)(.*)$",
}
for _, title in ipairs(dialogs) do
    hl.window_rule({ match = { title = title }, float = true, center = true })
end

hl.window_rule({ name = "float-modals", match = { modal = true }, float = true, center = true })

-- Picture-in-Picture

local pip = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
hl.window_rule({
    name              = "pip",
    match             = { title = pip },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = { "monitor_w*0.22", "monitor_h*0.22" },
    move              = { "monitor_w-window_w-24", "monitor_h-window_h-24" },
    no_shadow         = false,
})

-- Floating by default

local floaters = {
    "^(blueberry\\.py)$",
    "^(blueman-manager)$",
    "^(org\\.pulseaudio\\.pavucontrol)$",
    "^(com\\.saivert\\.pwvucontrol)$",
    "^(Waydroid)$",
    "^(waydroid.*)$",
    "^(org\\.kde\\.kcalc)$",
    "^(org\\.kde\\.kalk)$",
    "^(org\\.gnome\\.NautilusPreviewer)$",
    "^(coin)$",
    "^(wallreel)$",
    "^(be\\.alexandervanhee\\.gradia)$",
    "^(nm-connection-editor)$",
    "^(org\\.gnome\\.Calculator)$",
    "^(xdg-desktop-portal-gtk)$",
}
for _, class in ipairs(floaters) do
    hl.window_rule({ match = { class = class }, float = true, center = true })
end

-- QQ's image viewer has no useful class, only a title.
hl.window_rule({ match = { title = "^(图片查看器)(.*)$" }, float = true, center = true })

-- Terminals

hl.window_rule({
    name   = "floating-terminal",
    match  = { class = "^(kitty-floating)$" },
    float  = true,
    size   = { "monitor_w*0.5", "monitor_h*0.5" },
    center = true,
})
hl.window_rule({ match = { class = "^(com\\.mitchellh\\.ghostty)$" }, float = true, center = true })

hl.window_rule({ match = { class = "^(kitty)$" }, scrolling_width = 0.5 })
hl.window_rule({ match = { class = "^(scrcpy)$" }, scrolling_width = 0.3 })

-- Media, games, tearing

hl.window_rule({ name = "opaque-video", match = { content = "video" }, opaque = true, no_blur = true })
hl.window_rule({
    name      = "opaque-game",
    match     = { content = "game" },
    opaque    = true,
    no_blur   = true,
    no_dim    = true,
    immediate = true,
})

hl.window_rule({ match = { class = "^(steam_app.*)$" }, immediate = true })
hl.window_rule({ match = { title = "^(.*\\.exe)$" }, immediate = true })

-- Steam's notification toasts are windows, and they steal focus.
hl.window_rule({
    name             = "steam-toasts",
    match            = { class = "^(steam)$", title = "^(notificationtoasts_\\d+_desktop)$" },
    float            = true,
    no_initial_focus = true,
    no_shadow        = true,
})

hl.window_rule({ match = { class = "^(org\\.mozilla\\.[Tt]hunderbird)$" }, no_screen_share = true })

hl.window_rule({ match = { pin = true }, border_color = c.gradient(c.teal, c.green, 45) })

-- Smart gaps: a lone tiled or fullscreen window drops its gaps and border.
-- Rounding is kept.
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })

hl.workspace_rule({ workspace = "special:scratchpad", gaps_out = 40, gaps_in = 6 })

-- Layer rules

hl.layer_rule({ name = "blur-bar", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.4 })
hl.layer_rule({ name = "blur-launcher", match = { namespace = "^vicinae$" }, blur = true, ignore_alpha = 0.4 })
hl.layer_rule({ name = "blur-logout", match = { namespace = "^logout_dialog$" }, blur = true })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.6 })

-- The colour picker must see the screen exactly as it is.
hl.layer_rule({ name = "no-anim-picker", match = { namespace = "^hyprpicker$" }, no_anim = true })
hl.layer_rule({ name = "no-anim-selection", match = { namespace = "^selection$" }, no_anim = true })
