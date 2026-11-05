hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

hl.curve("parra", { type = "bezier", points = { { 0.333, 1.0 }, { 0.667, 1.0 } } })

for _, leaf in ipairs({ "workspaces", "workspacesIn", "workspacesOut" }) do
    hl.animation({ leaf = leaf, enabled = true, speed = 3, bezier = "parra", style = "slidevertical" })
end

-- hl.on("hyprland.start", function()
--     hl.exec_cmd("parra daemon")
-- end)
