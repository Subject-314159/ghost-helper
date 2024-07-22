local const = require("lib.const")
require("util")

local ghost_tracker = {}

local pop_current_surface = function()
    global.scan.surfaces[#global.scan.surfaces] = nil
end

local get_current_surface = function()
    return global.scan.surfaces[#global.scan.surfaces]
end

local index_surface = function()
    -- ==================================================
    -- Early exit checks
    -- ==================================================

    -- Early exit if no surface found
    if #global.scan.surfaces == 0 then
        game.print("Hmm we should never have gotten here")
        return
    end

    -- Early exit if there are still inventories to be processed
    if #global.scan.inventories > 0 then
        game.print("Hmm there are still inventories to be searched")
        return
    end

    -- ==================================================
    -- Prepare global array
    -- ==================================================

    -- Get the surface
    local surface = get_current_surface()

    -- Create scan.data index for the surface
    if not global.scan.data.surfaces then
        global.scan.data.surfaces = {}
    end
    global.scan.data.surfaces[surface.index] = {}

    -- Get the pointer & init array
    local srf = global.scan.data.surfaces[surface.index]
    srf.surface = surface
    srf.ghost_types = {}
    srf.storages = {}

    -- ==================================================
    -- Get ghosts
    -- ==================================================

    -- Set ghost tracker index
    global.scan.track.ghost_idx = 1

    -- Get all ghosts on the surface
    local gf = surface.find_entities_filtered({
        type = const.types.GHOST_ENTITY
    })

    -- Add each ghost to global array under their own type
    if gf and #gf > 0 then
        for _, g in pairs(gf) do
            -- Find the related ghost name in the array
            local exists = false
            for _, dg in pairs(srf.ghost_types) do
                if dg.ghost_name == g.ghost_name then
                    table.insert(dg.ghosts, g)
                    exists = true
                end
            end

            -- Add new entry if not found
            if not exists then

                -- Try to get the item related to the ghost (it can be that the ghost entity does not have an item 1:1 related to this)
                -- TODO: Current situation results in double ghosts for e.g. curved-rails and straight-rails
                -- This is because the array is created on unique ghost_name and not on placed_by_item
                local itm
                if game.item_prototypes[g.ghost_name] then
                    itm = g.ghost_name
                else
                    if game.entity_prototypes[g.ghost_name] then
                        local ep = game.entity_prototypes[g.ghost_name]
                        if ep.items_to_place_this then
                            itm = ep.items_to_place_this[1].name
                        end
                    end
                end

                -- Make the array
                local prop = {
                    ghost_name = g.ghost_name,
                    placed_by_item = itm,
                    ghosts = {g},
                    storage = {
                        total_count = 0,
                        inventories = {}
                    }
                }
                table.insert(srf.ghost_types, prop)
            end
        end
    else
        -- There are no ghosts on this surface, pop the surface since we don't need it and early exit 
        pop_current_surface()
        return
    end

    -- ==================================================
    -- Get inventories
    -- ==================================================

    -- Set up inventories array
    if not global.scan.inventories then
        global.scan.inventories = {}
    end

    -- Add all character inventories of that surface to the array
    for _, p in pairs(game.players) do
        if p.surface == surface and p.character then
            local inv = p.get_inventory(defines.inventory.character_main)
            table.insert(global.scan.inventories, inv)
        end
    end

    -- Get all storage entities
    local sf = surface.find_entities_filtered({
        type = const.types.INVENTORY
    })

    -- Store in storages
    srf.storages = table.deepcopy(sf)

    -- Store inventories in global
    for _, s in pairs(sf) do
        local inv = s.get_inventory(defines.inventory.chest)
        table.insert(global.scan.inventories, inv)
    end

    -- Check if there are any inventories on this surface after the scan
    -- It is possible that there are no chests and no characters on this surface
    if #global.scan.inventories == 0 then
        -- Pop the surface since we don't need to scan it anymore
        pop_current_surface()
    end
end

local scan_step = function()
    -- Get some variables to work with
    local surface = get_current_surface() -- The current surface that we are processing
    local srf = global.scan.data.surfaces[surface.index] -- The data array of this current surface

    -- Set step counter
    local action = 1

    while action <= settings.global["scan-actions-per-tick"].value do
        -- game.print("Action #" .. action .. "/" .. settings.global["scan-actions-per-tick"].value .. " on game tick " ..
        --                game.tick .. ", searching for ghost #" .. global.scan.track.ghost_idx .. "/" .. #srf.ghost_types ..
        --                " with " .. #global.scan.inventories .. " inventories remaining")
        -- Early exit if there are no more inventories to process
        if #global.scan.inventories == 0 then
            -- Pop the current surface because we're done
            pop_current_surface()
            return
        end

        -- Search the current inventory for the current ghost
        local inv = global.scan.inventories[#global.scan.inventories]
        if inv and inv.valid then
            local gt = srf.ghost_types[global.scan.track.ghost_idx]

            local cnt = inv.get_item_count(gt.placed_by_item) -- For now assume that an item always places their equivalent entity
            if cnt > 0 then
                -- The inventory contains the ghost item, add the inventory to the data array
                gt.storage.total_count = gt.storage.total_count + cnt
                table.insert(gt.storage.inventories, table.deepcopy(inv)) -- Deepcopy the inv because it will be popped afterwards
            end
        end
        -- Increase the ghost index
        global.scan.track.ghost_idx = global.scan.track.ghost_idx + 1

        -- Reset ghost index if it exceeded the array length and pop the inventory array
        if global.scan.track.ghost_idx > #srf.ghost_types then
            global.scan.track.ghost_idx = 1
            global.scan.inventories[#global.scan.inventories] = nil
        end

        -- Increase the action counter
        action = action + 1
    end
end

ghost_tracker.get_ghosts_grouped = function(player)
    -- Return the array
    return global.data
end

ghost_tracker.get_ghost_type_on_surface = function(surface_index, ghost_name)
    for i, gt in pairs(global.data.surfaces[surface_index].ghost_types) do
        if gt.ghost_name == ghost_name then
            return gt
        end
    end
end

local update_settings_surfaces = function()
    -- Update global settings surfaces if there are new surfaces
    for _, s in pairs(game.surfaces) do
        local exists = false
        for _, ss in pairs(global.settings.surfaces) do
            if ss.surface == s then
                exists = true
            end
        end
        if not exists then
            local prop = {
                scan = true,
                surface = s
            }
            table.insert(global.settings.surfaces, prop)
            game.print("[Ghost helper] New surface detected: " .. s.name)
            -- Future idea: Add mod setting to auto enable/disable scan new surfaces
        end
    end

    -- Remove global settings surfaces if they no longer exists
    for _, ss in pairs(global.settings.surfaces) do
        if ss and not ss.surface.valid then
            game.print("[Ghost helper] Surface no longer exists: " .. ss.name)
            ss = nil
        end

    end
end

ghost_tracker.tick_update = function()
    -- Main mechanic
    -- Loop through surfaces and inventories via array
    -- When done processing a surface or inventory, pop that from the array
    -- Start over when the array is empty
    if #global.scan.surfaces == 0 then
        -- There are no more surfaces to be processed

        -- Copy over the scanned data to the public data array and clear scan data array
        global.data.surfaces = {}
        if global.scan.data.surfaces and #global.scan.data.surfaces > 0 then
            for _, srf in pairs(global.scan.data.surfaces) do
                if #srf.ghost_types > 0 then
                    table.insert(global.data.surfaces, srf)
                end
            end
        end
        -- global.data = table.deepcopy(global.scan.data)
        global.scan.data = {}

        -- Update settings.surfaces and copy all active surfaces to the surfaces-to-be-scanned array
        update_settings_surfaces()
        for _, s in pairs(global.settings.surfaces) do
            if s.scan then
                table.insert(global.scan.surfaces, s.surface)
            end
        end

        -- Update the history array
        local tot = 0
        for i = #global.track.history, 2, -1 do
            local prev = global.track.history[i - 1]
            global.track.history[i] = prev
            tot = tot + prev
        end

        -- Update the average ticks
        global.track.avg_num_ticks_per_cycle = math.ceil(tot / #global.track.history)

        -- Reset the first entry
        global.track.history[1] = 0

    elseif #global.scan.inventories == 0 then
        -- There are no more inventories to be searched
        index_surface()
    else
        scan_step()
    end

    -- Increase the tick counter
    global.track.history[1] = global.track.history[1] + 1

end

ghost_tracker.init = function()
    -- global.scan is used to track the internal class progress
    -- global.scan = {
    --     track = {
    --         ghost_idx = 1
    --     },
    --     surfaces = {surface},
    --     inventories = {inv},
    --     data = {
    --         surfaces = {
    --             [surface_index] = {
    --                 surface = surface,
    --                 ghost_types = {{
    --                     ghost_name = ghost_name,
    --                     placed_by_item = entity.name or entity.items_to_place_this[1].name,
    --                     ghosts = {{ghost}, {...}},
    --                     storage = {
    --                         total_count = 1,
    --                         inventories = {{inventory}, {...}}
    --                     }
    --                 }, {...}},
    --                 storages = {{storage}, {...}}
    --             },
    --             {...}
    --         }
    --     }
    -- }

    if not global.scan then
        global.scan = {}
    end
    if not global.scan.track then
        global.scan.track = {}
    end
    if not global.scan.surfaces then
        global.scan.surfaces = {} -- The surfaces that we still have to scan
    end
    if not global.scan.inventories then
        global.scan.inventories = {} -- The inventories that we still have to scan
    end
    if not global.scan.data then
        global.scan.data = {} -- The resulting array with ghost entity data
    end

    -- Global track is used to keep track of misc stuff
    if not global.track then
        global.track = {}
    end

    if not global.track.history then
        global.track.history = {}
        for i = 1, 60, 1 do
            global.track.history[i] = 0
        end
    end

    -- global.data is the static array which can be used by external parties and a 1:1 structure copy of global.scan.data
    if not global.data then
        global.data = {}
    end

    -- global.settings is the in game mod settings
    if not global.settings then
        global.settings = {}
    end
    if not global.settings.surfaces then
        global.settings.surfaces = {}
    end

end

return ghost_tracker
