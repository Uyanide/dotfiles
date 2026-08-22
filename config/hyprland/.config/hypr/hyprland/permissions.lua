hl.config({
    ecosystem = {
        enforce_permissions = true,
    },
})

hl.permission({ binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/hyprpm", type = "plugin", mode = "allow" })

-- Prompts are drawn by hyprland-qtutils, which is not installed, so anything
-- not granted here fails rather than asking.
hl.permission({ binary = "/usr/(bin|local/bin)/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/hyprshot", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/hyprpicker", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/wf-recorder", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/wl-mirror", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/sunshine", type = "screencopy", mode = "allow" })
