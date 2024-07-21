local mod_gui = require("mod-gui")
local const = require("lib.const")
local helper = require("scripts.ghost-tracker")

local ghost_gui = {}

local init_player = function(player)
    if not global.players then
        global.players = {}
    end
    if not global.players[player.index] then
        global.players[player.index] = {}
    end
end

local get_global_player = function(player)
    init_player(player)
    return global.players[player.index]
end

local get_main_gui = function(player)
    local gui = player.gui.left[const.gui.main.FRAME]
    return gui
end

local update_gui_content = function(player)
    -- Get the player's gui or early exit if not open
    local gui = get_main_gui(player)
    if not gui then
        return
    end

    -- Get the information to work with
    local data = helper.get_ghosts_grouped(player)
    local tb_str = "" -- TEMP

    -- Remove surface frames in the gui if there are no entries in the data array for it
    for _, frm in pairs(gui.pane.main_frame.children) do
        local exists = false
        for idx, srf in pairs(data.surfaces) do
            if frm.name == const.gui.main.surface.PREFIX .. srf.surface.index then
                exists = true
            end
        end
        if frm.name ~= "no_ghosts" and not exists then
            frm.destroy()
        end
    end

    -- Loop through data surfaces and update ghost info
    for idx, srf in pairs(data.surfaces) do
        -- Add surface frames in the gui if there is none yet
        local exists = false
        local srf_frm
        for _, frm in pairs(gui.pane.main_frame.children) do
            if frm.name == const.gui.main.surface.PREFIX .. srf.surface.index then
                srf_frm = frm
                exists = true
            end
        end
        if not exists then
            local srf_frm = gui.pane.main_frame.add {
                type = "frame",
                name = const.gui.main.surface.PREFIX .. srf.surface.index,
                style = "surface_frame",
                direction = "vertical"
            }
            srf_frm.add {
                type = "label",
                name = const.gui.main.surface.label.PREFIX .. srf.surface.index,
                caption = "Ghosts on " .. srf.surface.name,
                style = "surface_name_label"
            }
        end

        if srf_frm then

            -- Loop through labels and remove ones no longer applicable
            for _, lbl in pairs(srf_frm.children) do
                local exists = false
                for _, gt in pairs(srf.ghost_types) do
                    if lbl.name == const.gui.main.surface.ghost_frame.PREFIX .. gt.ghost_name then
                        exists = true
                    end
                end
                if lbl.name ~= const.gui.main.surface.label.PREFIX .. srf.surface.index and not exists then
                    lbl.destroy()
                end
            end

            -- Loop through ghost types on this surface and show label
            for _, gt in pairs(srf.ghost_types) do
                local exists = false
                local fr
                for _, frm in pairs(srf_frm.children) do
                    if frm.name == const.gui.main.surface.ghost_frame.PREFIX .. gt.ghost_name then
                        fr = frm
                        exists = true
                    end
                end
                if not exists then
                    local tag = {
                        surface_index = srf.surface.index,
                        entity = gt.ghost_name
                    }
                    -- Create the container frame
                    fr = srf_frm.add {
                        type = "frame",
                        name = const.gui.main.surface.ghost_frame.PREFIX .. gt.ghost_name, -- Ghost Frame
                        direction = "vertical",
                        style = "ghost_frame"
                    }

                    local ifr = fr.add {
                        type = "frame",
                        name = "inner", -- Ghost Frame inner
                        direction = "vertical"
                    }

                    -- TEMP
                    -- ifr.add {
                    --     type = "label",
                    --     name = "lbl"
                    -- }

                    -- Create the table
                    local bt = ifr.add {
                        type = "table",
                        name = "bt", -- Button Table
                        column_count = 6,
                        style = "filter_slot_table"
                    }

                    bt.add { -- The icon of the actual ghost entity
                        type = "sprite-button",
                        name = "ghost_item",
                        sprite = ("item/" .. gt.placed_by_item),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        tags = tag
                    }
                    bt.add { -- The ghost button with the nr of ghosts
                        type = "sprite-button",
                        name = "ghost_count",
                        sprite = ("icon-ghost"),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        tags = tag
                    }
                    bt.add { -- The storage button
                        type = "sprite-button",
                        name = "storage",
                        sprite = ("icon-storage"),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        tags = tag
                    }
                    bt.add { -- The craft x1 button
                        type = "sprite-button",
                        name = "craft_1",
                        sprite = ("icon-craft"),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        number = 1,
                        tags = tag
                    }
                    bt.add { -- The craft x5 button
                        type = "sprite-button",
                        name = "craft_5",
                        sprite = ("icon-craft"),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        number = 5,
                        tags = tag
                    }
                    bt.add { -- The craft max button
                        type = "sprite-button",
                        name = "craft_max",
                        sprite = ("icon-craft"),
                        style = "recipe_slot_button",
                        raise_hover_events = true,
                        tags = tag
                    }

                end

                -- Update the buttons in the frame (but only if the numbers changed)
                local tbl = fr.inner.bt
                if not tbl then
                    game.print("Oops, no table found for " .. gt.ghost_name)
                end

                -- Do some calculations
                local delta = #gt.ghosts - gt.storage.total_count
                local craftable = player.get_craftable_count(gt.placed_by_item) or 0
                local threshold = math.min(delta, craftable)

                -- Set background tint
                if delta > 0 then
                    if (delta - craftable) > 0 and fr.inner.style ~= "ghost_frame_red" then
                        fr.inner.style = "ghost_frame_red"
                    elseif (delta - craftable) <= 0 and fr.inner.style ~= "ghost_frame_orange" then
                        fr.inner.style = "ghost_frame_orange"
                    end
                elseif delta <= 0 and fr.inner.style ~= "ghost_frame_green" then
                    fr.inner.style = "ghost_frame_green"
                end

                -- fr.inner.style.padding = 6

                -- Update badge numbers
                if tbl.ghost_count.number ~= #gt.ghosts then
                    tbl.ghost_count.number = #gt.ghosts
                end
                if tbl.storage.number ~= gt.storage.total_count then
                    tbl.storage.number = gt.storage.total_count
                end

                -- Update the crafting buttons

                -- Craft one button
                if threshold > 1 then
                    tbl.craft_1.visible = true
                else
                    tbl.craft_1.visible = false
                end

                -- Craft five button
                if threshold > 5 then
                    tbl.craft_5.visible = true
                else
                    tbl.craft_5.visible = false
                end

                -- Craft max button
                if threshold >= 1 then
                    tbl.craft_max.visible = true
                    if tbl.craft_max.number ~= threshold then
                        tbl.craft_max.number = threshold
                    end
                else
                    tbl.craft_max.visible = false
                end

                -- TEMP
                -- if fr and fr.inner then
                --     fr.inner.lbl.caption = gt.ghost_name .. " [ghosts:" .. #gt.ghosts .. "/storage:" ..
                --                                gt.storage.total_count .. "]"
                -- end
            end
        end
    end

    local cnt = 0

    if #data.surfaces == 0 then
        gui.pane.main_frame.no_ghosts.visible = true
    else
        gui.pane.main_frame.no_ghosts.visible = false
    end
end

local build_gui = function(player)

    -- Make the main frame
    local gui = player.gui.left.add {
        type = "frame",
        name = const.gui.main.FRAME,
        caption = {const.gui.main.CAPTION},
        direction = "vertical"
    }

    gui.add {
        type = "scroll-pane",
        name = "pane",
        horizontal_scroll_policy = "never",
        -- vertical_scroll_policy = "auto-and-reserve-space",
        vertical_scroll_policy = "auto",
        style = "main_pane"
    }

    gui.pane.add {
        type = "flow",
        name = "main_frame",
        direction = "vertical",
        style = "main_frame"
    }
    gui.pane.main_frame.add {
        type = "label",
        name = "no_ghosts",
        caption = "No ghosts found in enabled surfaces"
    }

    -- Store reference to gui in global
    local global_player = get_global_player(player)
    global_player.gui = gui

    -- Decorate the main frame
    update_gui_content(player)

end

local destroy_gui = function(player)
    local gui = get_main_gui(player)
    if gui then
        gui.destroy()
    end
end

ghost_gui.toggle_gui = function(player_index)
    -- Get the player or early exit
    local player = game.players[player_index]
    if not player then
        return
    end

    -- Toggle the gui
    if get_main_gui(player) then
        -- Destroy the gui because it is open
        destroy_gui(player)
    else
        -- Show the gui because it is closed
        build_gui(player)
    end
end

local start_crafting = function(player, recipe, count)
    player.begin_crafting({
        recipe = recipe,
        count = count
    })
end

local ping = function(player, entity)

    player.print(entity.name .. ' at [gps=' .. (entity.position.x) .. ',' .. (entity.position.y) .. ',' ..
                     entity.surface.name .. ']')
end

local process_gui_action = function(element, player, action)
    -- Define which element was clicked
    if element.name == "ghost_item" then
    elseif element.name == "ghost_count" then
        if action == "click" then
            if element.number > 0 then
                local gt = helper.get_ghost_type_on_surface(element.tags.surface_index, element.tags.entity)
                if gt then
                    player.print("Locations of ghost " .. gt.ghost_name)
                    for _, g in pairs(gt.ghosts) do
                        ping(player, g)
                    end
                else
                    game.print(
                        "Hmm for some reason we display a ghost button but there are no ghosts of this type on this surface")
                end
            else
                player.print("Ok this is awkward.. There are no ghosts of selected ghost type")
            end
        end
    elseif element.name == "storage" then
        if action == "click" then
            if element.number > 0 then
                local gt = helper.get_ghost_type_on_surface(element.tags.surface_index, element.tags.entity)
                if gt then
                    player.print("Locations of storage containing " .. gt.ghost_name)
                    for _, inv in pairs(gt.storage.inventories) do
                        local ent
                        if inv.entity_owner then
                            ent = inv.entity_owner
                        elseif inv.player_owner then
                            ent = inv.player_owner
                        end
                        if ent then
                            ping(player, ent)
                        else
                            player.print("Unknown entity")
                        end
                    end
                else
                    game.print(
                        "Hmm for some reason we display a ghost button but there are no ghosts of this type on this surface")
                end
            else
                player.print("No items of this ghost type in storage")
            end
        end
    elseif element.name == "craft_1" or element.name == "craft_5" or element.name == "craft_max" then
        if action == "click" then
            start_crafting(player, element.tags.entity, element.number)
        end
    end
end

ghost_gui.on_click = function(element, player)
    process_gui_action(element, player, "click")
end

ghost_gui.on_hover = function(element, player)
    process_gui_action(element, player, "hover")
end

ghost_gui.on_leave = function(element, player)
    process_gui_action(element, player, "leave")
end

ghost_gui.tick_update = function()
    if global.players then
        for i, p in pairs(global.players) do
            local player = game.players[i]
            update_gui_content(player)
        end
    end
end

ghost_gui.init = function()
    -- Destroy any open GUIs
    if game then
        for _, p in pairs(game.players) do
            destroy_gui(p)
        end
    end

    -- Init player array
    if game then
        for _, p in pairs(game.players) do
            init_player(p)
        end
    end

end

return ghost_gui
