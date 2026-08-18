-- Layout messages are layout-specific: "splitratio" means nothing to master,
-- "mfact" nothing to scrolling. These resolve one key to the right action.

local M = {}

--- Layout of the active workspace; per-workspace rules win over the default.
function M.current()
    local ws = hl.get_active_workspace()
    if ws and ws.tiled_layout and ws.tiled_layout ~= "" then
        return ws.tiled_layout
    end
    return hl.get_config("general.layout") or "dwindle"
end

--- `map` is keyed by layout name, `map.default` covers anything unlisted.
--- Values are functions so no dispatcher is built until the bind fires.
local function by_layout(map)
    return function()
        local pick = map[M.current()] or map.default
        if pick then
            hl.dispatch(pick())
        end
    end
end

M.by_layout = by_layout

M.widen = by_layout({
    dwindle   = function() return hl.dsp.layout("splitratio +0.05") end,
    master    = function() return hl.dsp.layout("mfact +0.05") end,
    scrolling = function() return hl.dsp.layout("colresize +0.05") end,
})

M.narrow = by_layout({
    dwindle   = function() return hl.dsp.layout("splitratio -0.05") end,
    master    = function() return hl.dsp.layout("mfact -0.05") end,
    scrolling = function() return hl.dsp.layout("colresize -0.05") end,
})

--- Cycle preset widths under scrolling, elsewhere snap back to an even split.
M.cycle_width = by_layout({
    dwindle   = function() return hl.dsp.layout("splitratio 1.0 exact") end,
    master    = function() return hl.dsp.layout("mfact exact 0.58") end,
    scrolling = function() return hl.dsp.layout("colresize +conf") end,
})

--- Root of the tree, the master slot, or a column of its own.
M.promote = by_layout({
    dwindle   = function() return hl.dsp.layout("movetoroot") end,
    master    = function() return hl.dsp.layout("swapwithmaster master") end,
    scrolling = function() return hl.dsp.layout("promote") end,
})

--- Flip the split, rotate the master area, or fill the free space.
M.tweak = by_layout({
    dwindle   = function() return hl.dsp.layout("togglesplit") end,
    master    = function() return hl.dsp.layout("orientationnext") end,
    scrolling = function() return hl.dsp.layout("fit expand") end,
})

M.cycle_next = by_layout({
    master  = function() return hl.dsp.layout("cyclenext") end,
    default = function() return hl.dsp.window.cycle_next() end,
})

M.cycle_prev = by_layout({
    master  = function() return hl.dsp.layout("cycleprev") end,
    default = function() return hl.dsp.window.cycle_next({ next = false }) end,
})

--- Scrolling consumes into columns; elsewhere the analogue is a tabbed group.
M.consume_prev = by_layout({
    scrolling = function() return hl.dsp.layout("consume_or_expel prev") end,
    default   = function() return hl.dsp.window.move({ into_or_create_group = "l" }) end,
})

M.consume_next = by_layout({
    scrolling = function() return hl.dsp.layout("consume_or_expel next") end,
    default   = function() return hl.dsp.window.move({ into_or_create_group = "r" }) end,
})

M.consume = by_layout({
    scrolling = function() return hl.dsp.layout("consume") end,
    default   = function() return hl.dsp.window.move({ into_or_create_group = "l" }) end,
})

M.expel = by_layout({
    scrolling = function() return hl.dsp.layout("expel") end,
    default   = function() return hl.dsp.window.move({ out_of_group = true }) end,
})

local LAYOUTS = { "dwindle", "master", "scrolling" }

--- Re-point the active workspace at another layout. Returns a bind callback.
function M.set(name)
    return function()
        local ws = hl.get_active_workspace()
        if not ws then
            return
        end
        hl.workspace_rule({ workspace = tostring(ws.id), layout = name })
        hl.notification.create({ text = "Layout: " .. name, timeout = 1500 })
    end
end

function M.next()
    return function()
        local now = M.current()
        local at = 1
        for i, name in ipairs(LAYOUTS) do
            if name == now then
                at = i
                break
            end
        end
        M.set(LAYOUTS[(at % #LAYOUTS) + 1])()
    end
end

return M
