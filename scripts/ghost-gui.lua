-- local mod_gui = require("mod-gui")
local const = require("lib.const")
local util = require("lib.util")
local helper = require("scripts.ghost-tracker")
local finder = require("scripts.ghost-finder")
local timer = require("scripts.timer")
local global_player = require("scripts.global-player")

local gutil = require("scripts.gui.util")
local gui_main = require("scripts.gui.main")
local gui_settings = require("scripts.gui.settings")

local ghost_gui = {}

---------------------------------------------------------------------------
-- MAIN WINDOW - interfaces
---------------------------------------------------------------------------

local toggle_settings_gui = function(player_index)
    -- Get the player or early exit
    local player = game.players[player_index]
    if not player then
        return
    end


    -- Toggle the gui
    if gutil.get_settings_gui(player) then
        -- Destroy the gui because it is open
        gui_settings.destroy(player)

    else
        -- Show the gui because it is closed
        gui_settings.build(player)
    end
end

ghost_gui.toggle_main_gui = function(player_index)
    -- Get the player or early exit
    local player = game.players[player_index]
    if not player then
        return
    end

    -- Toggle the gui
    if gutil.get_main_gui(player) then
        -- Destroy the gui because it is open
        gui_main.destroy(player)
    else
        -- Show the gui because it is closed
        gui_main.build(player)
    end
end

---------------------------------------------------------------------------
-- GUI INTERACTION
---------------------------------------------------------------------------

local get_switch_bool = function(element)
    if element.switch_state == "right" then
        return true
    else
        return false
    end
end

local start_crafting = function(player, recipe, count)
    player.begin_crafting({
        recipe = recipe,
        count = count
    })
end

local process_gui_action = function(element, player, action)

    -- Get the global player
    local gp = global_player.get(player)

    -- Define which element was clicked
    if element.name == "ghost_item" then
    elseif element.name == "ghost_count" then
        if action == "click" then
            if element.number > 0 then
                -- Get the ghosts and start new tracking
                local gt = helper.get_ghost_type_on_surface(element.tags.surface_index, element.tags.entity)
                -- gp.track_entities = gt.ghosts
                finder.set_new_entities_to_track(player, gt.ghosts)
            else
                player.print("Ok this is awkward.. There are no ghosts of selected ghost type")
            end
        end
    elseif element.name == "storage" then
        if action == "click" then
            if element.number > 0 then
                -- Get the storages and start new tracking
                local gt = helper.get_ghost_type_on_surface(element.tags.surface_index, element.tags.entity)
                -- gp.track_entities = gt.storage.entities
                finder.set_new_entities_to_track(player, gt.storage.entities)
            else
                player.print("No items of this ghost type in storage")
            end
        end
    elseif element.name == "craft_1" or element.name == "craft_5" or element.name == "craft_max" then
        if action == "click" then
            start_crafting(player, element.tags.entity, element.number)
        end
    elseif element.name == "gh_settings" then
        toggle_settings_gui(player.index)
    elseif element.name == "slider" then
        if action == "changed" then
            -- Update the mod setting according to new slider value
            if element.tags.setting then
                local val = element.slider_value * (element.tags.max / 20)
                settings.global[element.tags.setting] = {
                    value = val
                }
            end
        end
    elseif element.name == "auto_add_new_surfaces" then
        if action == "changed" then
            -- Update mod settings
            settings.global["gh_scan-new-surfaces"] = {
                value = get_switch_bool(element)
            }
        end
    elseif element.name == "enable_srf" then
        if action == "changed" then
            -- Search for the surface setting
            for _, ss in pairs(global.settings.surfaces) do
                if ss.surface.name == element.caption then
                    -- Update the setting according to the switch
                    ss.scan = element.state -- get_switch_bool(element)
                    break
                end
            end
        end
    elseif element.name == "expand_surface" and action == "click" then
        -- Get variables
        local expanded = false
        if element.sprite == "utility/collapse" then
            expanded = true
        end
        local pp = element.parent.parent
        local idx = pp.tags.surface_index
        if not idx then
            return
        end

        if not gp.surface_collapsed then
            gp.surface_collapsed = {}
        end
        gp.surface_collapsed[idx] = expanded
    end
end

---------------------------------------------------------------------------
-- PUBLIC INTERFACES
---------------------------------------------------------------------------

ghost_gui.on_click = function(element, player)
    process_gui_action(element, player, "click")
end

ghost_gui.on_hover = function(element, player)
    process_gui_action(element, player, "hover")
end

ghost_gui.on_leave = function(element, player)
    process_gui_action(element, player, "leave")
end

ghost_gui.on_change = function(element, player)
    process_gui_action(element, player, "changed")
end

ghost_gui.tick_update = function()
    if global.players then
        for i, p in pairs(global.players) do
            local player = game.players[i]
            gui_main.update(player)
            gui_settings.update(player)
        end
    end
end

ghost_gui.init = function()
    -- Destroy any open GUIs
    if game then
        for _, p in pairs(game.players) do
            gui_main.destroy(p)

            -- Legacy destroy old frame
            if p.gui.left["gh_main-frame"] then
                p.gui.left["gh_main-frame"].destroy()
            end
        end
    end

end

return ghost_gui
