-- Catppuccin Mocha.

local M = {
    base     = "1e1e2e",
    mantle   = "181825",
    crust    = "11111b",
    surface0 = "313244",
    surface1 = "45475a",
    surface2 = "585b70",
    overlay0 = "6c7086",
    subtext0 = "a6adc8",
    text     = "cdd6f4",

    blue     = "89b4fa",
    lavender = "b4befe",
    mauve    = "cba6f7",
    red      = "f38ba8",
    peach    = "fab387",
    yellow   = "f9e2af",
    green    = "a6e3a1",
    teal     = "94e2d5",
}

function M.rgb(hex)
    return "rgb(" .. hex .. ")"
end

--- `alpha` is a two-digit hex string, e.g. "80".
function M.rgba(hex, alpha)
    return "rgba(" .. hex .. alpha .. ")"
end

function M.gradient(from, to, angle)
    return { colors = { M.rgb(from), M.rgb(to) }, angle = angle or 45 }
end

return M
