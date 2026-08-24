hl.monitor({
    output   = "eDP-1",
    mode     = "2560x1600@60",
    position = "0x0",
    scale    = 1.25
})

hl.monitor({
    output   = "eDP-2",
    mode     = "2560x1600@60",
    position = "0x0",
    scale    = 1.25
})

hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@180",
    position = "2048x0",
    scale    = 1
})

hl.workspace_rule({ workspace = 1, monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = 2, monitor = "eDP-1", persistent = false })
