local mod = "SUPER"
local L = require("hyprland/layout-actions")

-- Applications

hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"), { description = "Terminal" })
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), { description = "Terminal" })
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("kitty-floating"), { description = "Floating terminal" })
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty-floating"), { description = "Floating terminal" })

hl.bind(mod .. " + C", hl.dsp.exec_cmd("code"), { description = "Editor" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager (GTK)" })
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("dolphin --new-window"), { description = "File manager" })
hl.bind(mod .. " + W", hl.dsp.exec_cmd("zen || zen-browser"), { description = "Browser" })

hl.bind(mod .. " + B", hl.dsp.exec_cmd("pkill -x -n btop || kitty-floating -e btop"), { description = "System monitor" })
hl.bind(mod .. " + O", hl.dsp.exec_cmd("pkill -x -n pwvucontrol || pwvucontrol"), { description = "Audio mixer" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("pkill -x wlogout || wlogout"), { description = "Session menu" })

-- Launcher. URLs are quoted: `?` is a glob to the `sh -c` exec_cmd runs.

hl.bind("ALT + space", hl.dsp.exec_cmd("vicinae toggle"), { description = "Launcher" })
hl.bind(mod .. " + D", hl.dsp.exec_cmd("vicinae 'vicinae://launch/system/run?toggle=true'"), { description = "Run command" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("vicinae 'vicinae://launch/clipboard/history?toggle=true'"), { description = "Clipboard history" })
hl.bind(mod .. " + period", hl.dsp.exec_cmd("vicinae 'vicinae://launch/core/search-emojis?toggle=true'"), { description = "Emoji picker" })

-- Screenshots and colour

hl.bind("Print", hl.dsp.exec_cmd("screenshot-script full"), { description = "Screenshot: screen" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("screenshot-script area"), { description = "Screenshot: region" })
hl.bind(mod .. " + CTRL + SHIFT + S", hl.dsp.exec_cmd("screenshot-script window"), { description = "Screenshot: window" })
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick colour" })

-- Utilities

hl.bind(mod .. " + N", hl.dsp.exec_cmd("sunset"), { description = "Night light" })
hl.bind(mod .. " + SHIFT + K", hl.dsp.exec_cmd("pkill -x waybar; waybar"), { description = "Restart the bar" })
hl.bind(mod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload config" })

-- hypridle has no runtime toggle, and probing for it would mean a blocking
-- popen, which must not happen in a bind callback.
local idle_inhibited = false
hl.bind(mod .. " + I", function()
    idle_inhibited = not idle_inhibited
    if idle_inhibited then
        hl.exec_cmd("pkill -x hypridle")
    else
        hl.exec_cmd("hypridle")
    end
    hl.notification.create({
        text = idle_inhibited and "Idle inhibited" or "Idle timers active",
        timeout = 1500,
    })
end, { description = "Toggle idle inhibit" })

-- Media and brightness. BRIGHTNESSCTL_DEVICE comes from set_display.

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd('brightnessctl -d "${BRIGHTNESSCTL_DEVICE:-intel_backlight}" -e4 -n2 set 5%+'),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd('brightnessctl -d "${BRIGHTNESSCTL_DEVICE:-intel_backlight}" -e4 -n2 set 5%-'),
    { locked = true, repeating = true })

-- Window management

hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Force kill window" })

for key, dir in pairs({ Left = "l", Right = "r", Up = "u", Down = "d" }) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir, group_aware = true }))
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.focus({ monitor = dir }))
    hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ monitor = dir, follow = true }))
end

hl.bind(mod .. " + ALT + space", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(mod .. " + P", hl.dsp.window.pin(), { description = "Pin window" })
hl.bind(mod .. " + Y", hl.dsp.window.center(), { description = "Centre window" })

hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen" })

-- The client believes it is fullscreen, the layout does not. Stops
-- Chromium-likes dropping into presentation mode.
hl.bind(mod .. " + ALT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }),
    { description = "Fake fullscreen" })

hl.bind("ALT + Tab", function()
    L.cycle_next()
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Next window" })
hl.bind("ALT + SHIFT + Tab", function()
    L.cycle_prev()
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Previous window" })

hl.bind(mod .. " + SHIFT + Tab", function()
    local w = hl.get_active_window()
    hl.dispatch(hl.dsp.focus({ window = (w and w.floating) and "tiled" or "floating" }))
end, { description = "Floating <-> tiled focus" })

-- Tabbed groups

hl.bind(mod .. " + SHIFT + M", hl.dsp.group.toggle(), { description = "Toggle tabbed group" })
hl.bind(mod .. " + CTRL + Tab", hl.dsp.group.next(), { description = "Next tab" })
hl.bind(mod .. " + CTRL + SHIFT + Tab", hl.dsp.group.prev(), { description = "Previous tab" })

-- Layout-aware

hl.bind(mod .. " + minus", L.narrow, { repeating = true, description = "Narrower" })
hl.bind(mod .. " + plus", L.widen, { repeating = true, description = "Wider" })
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + plus", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

hl.bind(mod .. " + R", L.cycle_width, { description = "Cycle preset width" })
hl.bind(mod .. " + J", L.tweak, { description = "Split / orientation / expand" })
hl.bind(mod .. " + U", L.promote, { description = "Promote window" })

hl.bind(mod .. " + ALT + Left", L.consume_prev, { description = "Consume/expel left" })
hl.bind(mod .. " + ALT + Right", L.consume_next, { description = "Consume/expel right" })
hl.bind(mod .. " + SHIFT + comma", L.consume, { description = "Consume window" })
hl.bind(mod .. " + SHIFT + period", L.expel, { description = "Expel window" })

-- Workspaces

for i = 1, 10 do
    local key = tostring(i % 10) -- workspace 10 sits on the 0 key
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

hl.bind(mod .. " + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + Page_Up", hl.dsp.focus({ workspace = "-1" }))
-- hl.bind(mod .. " + Down", hl.dsp.focus({ workspace = "+1" }))
-- hl.bind(mod .. " + Up", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "+1", follow = true }))
hl.bind(mod .. " + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "-1", follow = true }))
-- hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ workspace = "+1", follow = true }))
-- hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ workspace = "-1", follow = true }))

-- Scroll through only the workspaces that exist.
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Last workspace" })

hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Scratchpad" })
hl.bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }),
    { description = "Send to scratchpad" })

-- Mouse

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse:274", hl.dsp.window.close(), { description = "Close window" })

-- Cycles dwindle -> master -> scrolling, notifying which. No submap: a modal
-- state with no on-screen indicator traps the keyboard.
hl.bind(mod .. " + SHIFT + L", L.next(), { description = "Cycle layout" })

-- Session

hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock" })

-- The delay is deliberate: driving dpms straight from a keybind is documented
-- as undefined behaviour.
hl.bind(mod .. " + SHIFT + P", function()
    hl.exec_cmd("loginctl lock-session")
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "disable" }))
    end, { timeout = 800, type = "oneshot" })
end, { description = "Lock and blank screens" })

-- hyprshutdown rather than hl.dsp.exit(), so the session tears down in order.
hl.bind(mod .. " + K", hl.dsp.exec_cmd("hyprshutdown"), { description = "Exit Hyprland" })
