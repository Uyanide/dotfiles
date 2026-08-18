local c = require("hyprland/theme")

hl.config({
    general = {
        gaps_in                           = 3,
        gaps_out                          = 6,
        gaps_workspaces                   = 40,

        border_size                       = 2,
        col                               = {
            active_border   = c.gradient(c.blue, c.mauve, 45),
            inactive_border = c.rgba(c.surface0, "cc"),
        },

        resize_on_border                  = true,
        extend_border_grab_area           = 12, -- 2px borders are hard to hit
        hover_icon_on_border              = true,

        no_focus_fallback                 = true,
        allow_tearing                     = true, -- gates the `immediate` rule

        layout                            = "dwindle",

        snap                              = {
            enabled      = true,
            window_gap   = 8,
            monitor_gap  = 8,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding           = 14,
        rounding_power     = 2,

        active_opacity     = 1.0,
        inactive_opacity   = 0.96,
        fullscreen_opacity = 1.0,

        dim_inactive       = false,
        dim_special        = 0.3,

        shadow             = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            offset         = { 0, 4 },
            color          = c.rgba("000000", "44"),
            color_inactive = c.rgba("000000", "22"),
        },

        blur               = {
            enabled                   = true,
            size                      = 6,
            passes                    = 3,
            new_optimizations         = true,
            xray                      = true,
            ignore_opacity            = true,
            noise                     = 0.012,
            contrast                  = 1.0,
            brightness                = 1.0,
            vibrancy                  = 0.17,
            vibrancy_darkness         = 0.0,

            special                   = false,
            popups                    = true,
            popups_ignorealpha        = 0.6,

            -- Keeps the fcitx5 candidate window readable over bright content.
            input_methods             = true,
            input_methods_ignorealpha = 0.8,
        },
    },

    group = {
        auto_group           = false,
        insert_after_current = true,
        focus_removed_window = true,
        merge_groups_on_drag = true,

        col                  = {
            border_active          = c.gradient(c.blue, c.mauve, 45),
            border_inactive        = c.rgba(c.surface0, "cc"),
            border_locked_active   = c.gradient(c.peach, c.red, 45),
            border_locked_inactive = c.rgba(c.surface0, "cc"),
        },

        groupbar             = {
            enabled             = true,
            font_family         = "Noto Sans",
            font_size           = 11,
            height              = 18,
            indicator_height    = 3,
            indicator_gap       = 2,
            gradients           = false,
            render_titles       = true,
            scrolling           = true,
            middle_click_close  = true,
            stacked             = false,
            keep_upper_gap      = true,
            rounding            = 6,
            gaps_in             = 2,
            gaps_out            = 2,

            col                 = {
                active          = c.rgb(c.blue),
                inactive        = c.rgba(c.surface0, "dd"),
                locked_active   = c.rgb(c.peach),
                locked_inactive = c.rgba(c.surface0, "dd"),
            },
            text_color          = c.rgb(c.crust),
            text_color_inactive = c.rgb(c.text),
        },
    },

    cursor = {
        warp_on_change_workspace = 1,
        warp_on_toggle_special   = 1,
        persistent_warps         = true,

        hide_on_key_press        = true,
        inactive_timeout         = 0,

        default_monitor          = "DP-1",
    },

    binds = {
        workspace_back_and_forth          = true,
        allow_workspace_cycles            = true,
        hide_special_on_workspace_change  = true,
        movefocus_cycles_fullscreen       = false,
        window_direction_monitor_fallback = true,
        scroll_event_delay                = 0,
        drag_threshold                    = 10,
    },

    misc = {
        font_family                  = "Noto Sans",

        -- Backdrop behind windows; no wallpaper daemon is started here.
        disable_hyprland_logo        = true,
        disable_splash_rendering     = true,
        force_default_wallpaper      = 0,
        background_color             = c.rgb(c.base),

        vrr                          = 2, -- fullscreen only; 3 also gates on content type

        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,

        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,

        enable_swallow               = false,
        middle_click_paste           = false,

        focus_on_activate            = true,
        initial_workspace_tracking   = 0,
        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        close_special_on_empty       = true,
    },

    xwayland = {
        -- The panel runs at 1.25; without this XWayland apps render blurry.
        force_zero_scaling = true,
    },
})
