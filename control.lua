local const = require("lib.const")
local ghost_gui = require("scripts.ghost-gui")
local ghost_tracker = require("scripts.ghost-tracker")
local ghost_settings = require("scripts.ghost-settings")
local ghost_finder = require("scripts.ghost-finder")
local global_player = require("scripts.global-player")

---------------------------------------------------------------------------
-- Init etc
---------------------------------------------------------------------------
local init_all = function()
    global_player.init()

    ghost_tracker.init()
    ghost_gui.init()
    ghost_settings.init()
    ghost_finder.init()
end

script.on_init(function(e)
    init_all()
end)

script.on_configuration_changed(function(e)
    init_all()
end)

script.on_event(defines.events.on_tick, function()
    -- Do magic here
    ghost_tracker.tick_update()
    ghost_gui.tick_update()
    ghost_finder.tick_update()
end)

local function get_top_parent_recursive(element)
    local pp_is_gui = false
    for _, c in pairs(element.gui.children) do
        if c == element.parent then
            pp_is_gui = true
        end
    end
    if element and element.valid and element.parent and not pp_is_gui then
        return get_top_parent_recursive(element.parent)
    else
        return element.name
    end
end

script.on_event(defines.events.on_gui_click, function(e)
    if e and e.element then
        -- Get some variables to work with
        local elm = e.element
        local player = game.players[e.player_index]
        local pname = get_top_parent_recursive(e.element)

        -- Get the parent handler
        if pname == const.gui.main.FRAME then
            -- Let the class handle the event
            ghost_gui.on_click(elm, player)
        end
    end
end)

script.on_event(defines.events.on_gui_hover, function(e)
    if e and e.element then
        -- Get some variables to work with
        local elm = e.element
        local player = game.players[e.player_index]
        local pname = get_top_parent_recursive(e.element)

        -- Get the parent handler
        if pname == const.gui.main.FRAME then
            -- Let the class handle the event
            ghost_gui.on_hover(elm, player)
        end
    end
end)
script.on_event(defines.events.on_gui_leave, function(e)
    if e and e.element then
        -- Get some variables to work with
        local elm = e.element
        local player = game.players[e.player_index]
        local pname = get_top_parent_recursive(e.element)

        -- Get the parent handler
        if pname == const.gui.main.FRAME then
            -- Let the class handle the event
            ghost_gui.on_leave(elm, player)
        end
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(e)
    local player = game.players[e.player_index]
    if not player then
        return
    end
    if e.prototype_name == "gh_toggle-gui" then
        ghost_gui.toggle_gui(e.player_index)
    end
end)

script.on_event("gh_toggle-gui", function(e)
    ghost_gui.toggle_gui(e.player_index)
end)
