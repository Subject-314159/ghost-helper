local const = require("lib.const")
require("util")

local ghost_tracker = {}

------------------------------------------------------------------------------------------
-- Helper functions
------------------------------------------------------------------------------------------

local pop_current_surface = function()
    global.scan.surfaces[#global.scan.surfaces] = nil
end

local get_current_surface = function()
    return global.scan.surfaces[#global.scan.surfaces]
end

local get_data_surface = function(surface)
    if not global.scan.data.surfaces[surface.index] then
        global.scan.data.surfaces[surface.index] = {}
    end
    return global.scan.data.surfaces[surface.index]
end

local pop_current_chunk = function()
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)
    srf.chunk_count = (srf.chunk_count or 0) + 1
    surface.chunks[#surface.chunks] = nil
end

local get_current_chunk = function()
    local surface = get_current_surface()
    return surface.chunks[#surface.chunks]
end

------------------------------------------------------------------------------------------
-- Main scan loop
------------------------------------------------------------------------------------------

---------- Update surfaces ----------

local copy_clean_data = function()
    -- Copy over the scanned data to the public data array and clear scan data array
    global.data.surfaces = {}
    if global.scan.data.surfaces and #global.scan.data.surfaces > 0 then
        for _, srf in pairs(global.scan.data.surfaces) do
            if #srf.ghost_indexes > 0 then
                table.insert(global.data.surfaces, srf)
            else
                log("No ghosts found in scan data")
            end
        end
    end
    -- Clear scan data array
    global.scan.data = {
        surfaces = {}
    }
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

local generate_new_scan_surfaces = function()
    -- Copy all active surfaces to the surfaces-to-be-scanned array
    for _, s in pairs(global.settings.surfaces) do
        if s.scan then
            -- Generate base prop array
            local prop = {
                surface = s.surface,
                -- chunks = s.surface.get_chunks()
                chunks = {}
            }
            -- for i, chunk in ipairs(s.surface.get_chunks()) do
            --     prop.chunks[i] = chunk
            -- end
            local i = 1
            for chunk in s.surface.get_chunks() do
                prop.chunks[i] = chunk
                i = i + 1
            end
            -- Add the array to surfaces
            table.insert(global.scan.surfaces, prop)
        end
    end
end

local update_surfaces = function()
    copy_clean_data()
    update_settings_surfaces()
    generate_new_scan_surfaces()
    log("Surfaces generated:")
    log(serpent.block(global.surfaces))
end

---------- Index surfaces by step ----------

local get_item_that_places = function(ghost)
    local itm
    if game.item_prototypes[ghost.ghost_name] then
        itm = ghost.ghost_name
    else
        if game.entity_prototypes[ghost.ghost_name] then
            local ep = game.entity_prototypes[ghost.ghost_name]
            if ep.items_to_place_this then
                itm = ep.items_to_place_this[1].name
            end
        end
    end
    return itm
end

local add_scan_inventory = function(inv)
    local exists = false
    for _, i in pairs(global.scan.inventories) do
        if i == inv then
            exists = true
        end
    end
    if not exists then
        table.insert(global.scan.inventories, inv)
    end
end

local get_ghosts_on_chunk = function()
    -- Get some variables to work with
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)
    local ch = get_current_chunk()

    -- Initiate ghost_types array
    if not srf.ghost_types then
        srf.ghost_types = {}
    end

    -- Check if chunk is generated
    local pos = {ch.x, ch.y}
    local gf
    -- if surface.surface.is_chunk_generated(pos) then
    -- Find all ghosts in the chunk
    gf = surface.surface.find_entities_filtered({
        type = const.types.GHOST_ENTITY,
        area = ch.area
    })
    -- end

    -- Safe add ghosts to array
    if gf and #gf > 0 then
        for _, g in pairs(gf) do
            -- Create new array for this ghost type if not exists
            local itm = get_item_that_places(g)
            if not srf.ghost_types[itm] then
                srf.ghost_types[itm] = {
                    ghosts = {},
                    storage = {
                        total_count = 0,
                        inventories = {},
                        entities = {}
                    }
                }
            end

            -- Append ghost to array
            srf.ghost_types[itm].ghosts[g.unit_number] = g
        end
    end
end

local get_storages_on_chunk = function()
    -- Get some variables to work with
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)
    local ch = get_current_chunk()

    -- Set up inventories array
    if not global.scan.inventories then
        global.scan.inventories = {}
    end

    -- Check if chunk is generated
    local pos = {ch.x, ch.y}
    local sf
    -- if surface.surface.is_chunk_generated(pos) then
    -- Get all storage entities
    sf = surface.surface.find_entities_filtered({
        type = const.types.INVENTORY,
        area = ch.area
    })
    -- end

    -- Safe add storages to arrays
    if sf and #sf > 0 then
        for _, s in pairs(sf) do
            -- Add storage entity to surfaces storage array
            if not srf.storage_entities then
                srf.storage_entities = {}
            end
            srf.storage_entities[s.unit_number] = s

            -- Add inventory to scan array
            local inv = s.get_inventory(defines.inventory.chest)
            add_scan_inventory(inv)
        end

    end
end

local post_chunk_index = function()
    -- Prepares the data.surface array for furhter processing
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)

    -- Index all players on the surface
    for _, p in pairs(game.players) do
        if p.surface == surface and p.character then
            local inv = p.get_inventory(defines.inventory.character_main)
            add_scan_inventory(inv)
        end
    end

    -- Generate arrays for ghost.unit_numbers used
    srf.ghost_indexes = {}
    for itm, arr in pairs(srf.ghost_types) do
        table.insert(srf.ghost_indexes, itm)
    end

    -- Add the surface
    srf.surface = surface.surface
end

local index_step = function()
    -- Get some variables to work with
    local surface = get_current_surface()
    local action = 1

    while action <= settings.global["index-chunks-per-tick"].value do
        -- Early exit if there are no more chunks remaining
        if #surface.chunks == 0 then
            break
        end

        -- Scan the chunk & store data in array
        get_ghosts_on_chunk()
        get_storages_on_chunk()

        -- Pop the chunk from the array
        pop_current_chunk()

        -- Next action index
        action = action + 1
    end

    -- Post chunk scan actions
    if #surface.chunks == 0 then
        post_chunk_index()

        -- Init for next step
        global.track.ghost_idx = 1
    end

end

---------- Scan inventories by step ----------
local search_inventory_for_ghost = function()
    -- Get some variables to work with
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)

    -- Search the current inventory for the current ghost
    local inv = global.scan.inventories[#global.scan.inventories]
    if inv and inv.valid then
        local idx = srf.ghost_indexes[global.track.ghost_idx]
        local gt = srf.ghost_types[idx]

        if gt then

            -- Check if the inventory contains the ghost item
            local cnt = inv.get_item_count(idx)
            if cnt > 0 then
                -- Add the inventory to the data array
                gt.storage.total_count = gt.storage.total_count + cnt
                table.insert(gt.storage.inventories, table.deepcopy(inv)) -- Deepcopy the inv because it will be popped afterwards

                -- Add owning entities to array
                local ste = inv.entity_owner
                if ste then
                    table.insert(gt.storage.entities, ste)
                end
                local stp = inv.player_owner
                if stp and stp.character then
                    table.insert(gt.storage.entities, stp.character)
                end
            end
        end
    end

    -- Increase the ghost index
    global.track.ghost_idx = global.track.ghost_idx + 1

    -- Reset ghost index if it exceeded the array length and pop the inventory array
    if global.track.ghost_idx > #srf.ghost_indexes then
        global.track.ghost_idx = 1
        global.scan.inventories[#global.scan.inventories] = nil
    end
end
local scan_step = function()
    -- Get some variables to work with
    local action = 1

    while action <= settings.global["scan-actions-per-tick"].value do
        -- Pop the current surface when we're done
        if #global.scan.inventories == 0 then
            pop_current_surface()
            return
        end

        -- Perform the search action
        search_inventory_for_ghost()

        -- Increase the action counter
        action = action + 1
    end
end

------------------------------------------------------------------------------------------
-- Public interfaces
------------------------------------------------------------------------------------------

ghost_tracker.get_ghosts_grouped = function(player)
    -- Return the array
    return global.data
end

ghost_tracker.get_ghost_type_on_surface = function(surface_index, ghost_name)
    for itm, gt in pairs(global.data.surfaces[surface_index].ghost_types) do
        if itm == ghost_name then
            return gt
        end
    end
end

local function surface_has_chunk()
    local surface = get_current_surface()
end

ghost_tracker.tick_update = function()
    -- Early exit if disabled
    if not settings.global["gh_enable"].value then
        return
    end

    if #global.scan.surfaces == 0 then
        -- Populate the scan surfaces array with new data
        update_surfaces()

        -- Update the tick count history array
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

    elseif #global.scan.surfaces[#global.scan.surfaces].chunks > 0 then
        -- Index chunks while there are still chunks left to be indexed
        index_step()

    else
        -- Perform the scan step
        scan_step()
    end

    -- Increase the tick counter
    global.track.history[1] = global.track.history[1] + 1
end

ghost_tracker.init = function()

    -- global.scan is used to track the internal class progress
    -- global.scan = {
    --     surfaces = {{
    --         surface = surface,
    --         chunks = {{chunk}, {...}}
    --     }, {...}},
    --     inventories = {inv},
    --     data = {
    --         surfaces = {
    --             [surface_index] = {
    --                 surface = surface,
    --                 ghost_indexes = {entity.name or entity.items_to_place_this[1].name, ...}
    --                 ghost_types = {[entity.name or entity.items_to_place_this[1].name] = {
    --                     ghost_name = ghost_name,
    --                     placed_by_item = entity.name or entity.items_to_place_this[1].name,
    --                     ghosts = {
    --                         [entity_id] = {ghost},
    --                         [i] = {...}
    --                     },
    --                     storage = {
    --                         total_count = 1,
    --                         inventories = {{inventory}, {...}},
    --                         entities = {{entity}, {...}}
    --                     }
    --                 }, {...}},
    --                 storage_entities = {
    --                     [entity_id] = {entity},
    --                     [i] = {...}
    --                 }
    --             },
    --             [i] = {...}
    --         }
    --     }
    -- }
    -- if not global.scan then
    --     global.scan = {}
    -- end
    -- if not global.scan.surfaces then
    --     global.scan.surfaces = {} -- The surfaces that we still have to scan
    -- end
    -- if not global.scan.inventories then
    --     global.scan.inventories = {} -- The inventories that we still have to scan
    -- end
    -- if not global.scan.data then
    --     global.scan.data = {} -- The resulting array with ghost entity data
    -- end
    global.scan = {
        surfaces = {},
        inventories = {},
        data = {}
    }

    -- Global.track is used to track who/what/where/when
    -- global.track = {
    --     ghost_idx = 0
    -- }

    if not global.track then
        global.track = {}
    end
    if not global.track.history then
        global.track.history = {}
    end
    for i = 1, 10, 1 do
        global.track.history[i] = 0
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
