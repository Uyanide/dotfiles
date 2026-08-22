-- Windows use springs so they settle with weight; everything else uses short
-- asymmetric beziers, entering with deceleration and leaving faster.

hl.curve("standard", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.curve("decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1.0 } } })
hl.curve("accel", { type = "bezier", points = { { 0.3, 0.0 }, { 0.8, 0.15 } } })
hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })

-- Stiffness sets the speed, dampening how much it overshoots.
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 300, dampening = 26 })
hl.curve("smooth", { type = "spring", mass = 1, stiffness = 190, dampening = 24 })
hl.curve("lively", { type = "spring", mass = 1, stiffness = 250, dampening = 19 })

-- Unset leaves inherit from their parent.
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "standard" })

hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "snappy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "lively", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.2, bezier = "accel", style = "popin 94%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "smooth" })

hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.2, bezier = "accel", style = "slide" })

hl.animation({ leaf = "fade", enabled = true, speed = 2.6, bezier = "standard" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.2, bezier = "decel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.8, bezier = "accel" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2.5, bezier = "standard" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.2, bezier = "decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "accel" })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 1.8, bezier = "decel" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 1.4, bezier = "accel" })

hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "standard" })

-- `borderangle` with style "loop" is left unset on purpose: it renders
-- continuously at the refresh rate even when idle, which costs battery.

hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "standard", style = "slidefadevert 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, spring = "smooth", style = "slidevert" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "decel" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 4, bezier = "decel" })
