hl.config({
    gestures = {
        workspace_swipe_distance                 = 400,
        workspace_swipe_cancel_ratio             = 0.2,
        workspace_swipe_min_speed_to_force       = 5,

        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,

        workspace_swipe_create_new               = true,
        workspace_swipe_forever                  = true,
        workspace_swipe_touch                    = false,
    },
})

hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

-- Only does anything under the scrolling layout, harmless elsewhere.
hl.gesture({ fingers = 4, direction = "horizontal", action = "scroll_move" })

hl.gesture({ fingers = 4, direction = "up", action = "special", workspace_name = "scratchpad" })

-- Held modifiers turn a swipe into a window action rather than navigation.
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down", mods = "SUPER", action = "close" })
hl.gesture({ fingers = 3, direction = "left", mods = "SUPER", scale = 1.5, action = "float" })

hl.gesture({ fingers = 2, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })
