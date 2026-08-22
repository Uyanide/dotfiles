-- All three layouts. SUPER+SHIFT+L switches the active workspace between them;
-- the keymap is shared, see layout-actions.lua.

hl.config({
    dwindle = {
        -- Required for SUPER+J (togglesplit) to mean anything.
        preserve_split         = true,

        smart_split            = false,
        force_split            = 2, -- new window lands right/bottom

        smart_resizing         = true,
        use_active_for_splits  = true,
        precise_mouse_move     = true,

        default_split_ratio    = 1.0,
        -- 2560px stays "wide" through several splits, so stack sooner.
        split_width_multiplier = 1.35,

        special_scale_factor   = 1.0,
    },

    master = {
        mfact                         = 0.58,
        orientation                   = "left",

        -- New windows join the stack instead of stealing the master slot.
        new_status                    = "slave",
        new_on_active                 = "after",
        new_on_top                    = false,

        allow_small_split             = true,
        smart_resizing                = true,
        drop_at_cursor                = true,
        always_keep_position          = false,
        focus_master_on_close         = false,

        slave_count_for_center_master = 2,
        center_master_fallback        = "left",
        special_scale_factor          = 1.0,
    },

    scrolling = {
        column_width             = 0.5,
        explicit_column_widths   = "0.3, 0.5, 0.7, 1.0",

        fullscreen_on_one_column = true,
        focus_fit_method         = 1,
        follow_focus             = true,
        follow_min_visible       = 0.4,

        -- Let focus fall off the ends onto the other monitor.
        wrap_focus               = false,
        wrap_swapcol             = true,

        direction                = "right",
    },
})
