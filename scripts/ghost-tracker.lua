local const = require("lib.const")
local util = require("lib.util")
local timer = require("scripts.timer")
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

local get_current_chunk = function()
    local surface = get_current_surface()
    -- return surface.chunks[#surface.chunks]
    return surface.chunks()
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
            end
        end
    end
    -- Clear scan data array
    global.scan.data = {
        surfaces = {}
    }
end

local ignore_surface = function(name)
    for _, srf in pairs(const.settings.ignore.SURFACES) do
        if srf == name then
            return true
        end
    end

    for _, pre in pairs(const.settings.ignore.SURFACE_PREFIXES) do
        if name:sub(1, #pre) == pre then
            return true
        end
    end

    return false
end

local update_settings_surfaces = function()

    -- Reset track total chunks to scan
    global.track.total_chunks = 1

    -- Update global settings surfaces if there are new surfaces
    for _, s in pairs(game.surfaces) do
        local exists = false
        for _, ss in pairs(global.settings.surfaces) do
            if ss.surface == s then
                exists = true
                break
            end
        end
        if not exists and not ignore_surface(s.name) then
            local scan = settings.global["gh_scan-new-surfaces"].value
            local prop = {
                scan = scan,
                expand = true,
                surface = s,
                num_chunks = 0
                -- num_ghosts = 0,
                -- num_inventories = 0
            }
            table.insert(global.settings.surfaces, prop)
            local option
            if scan then
                option = "auto scanning for ghosts & chests"
            else
                option = "not included in auto scan"
            end
            game.print("[Ghost helper] New surface detected: " .. s.name .. ", " .. option)
            -- Future idea: Add mod setting to auto enable/disable scan new surfaces
        end
    end

    -- Validate existing surfaces
    for i, ss in pairs(global.settings.surfaces) do
        if not ss.surface.valid or ignore_surface(ss.surface.name) then
            -- Remove global settings surfaces if they no longer exists
            local name = ss.surface.name or "<unknown>"
            game.print("[Ghost helper] Surface no longer valid for tracking: " .. name)
            global.settings.surfaces[i] = nil
        elseif ss.scan then
            -- Sum total number of chunks to be scanned
            global.track.total_chunks = global.track.total_chunks + (ss.num_chunks or 0)
        end
    end
    -- util.silent("Total chunks to scan: " .. global.track.total_chunks)

end

local generate_new_scan_surfaces = function()
    -- Copy all active surfaces to the surfaces-to-be-scanned array
    for _, s in pairs(global.settings.surfaces) do
        if s.scan and s.surface.valid then
            -- Generate base prop array
            local prop = {
                surface = s.surface,
                chunks = s.surface.get_chunks(),
                has_chunks = true,
                chunks_indexed = 0
                -- chunks = {}
            }
            -- local i = 1
            -- for chunk in s.surface.get_chunks() do
            --     prop.chunks[i] = chunk
            --     i = i + 1
            -- end
            -- Add the array to surfaces
            table.insert(global.scan.surfaces, prop)
        end
    end
end

local update_surfaces = function()
    copy_clean_data()
    update_settings_surfaces()
    generate_new_scan_surfaces()
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
    -- local exists = false
    -- for _, i in pairs(global.scan.inventories) do
    --     if i == inv then
    --         exists = true
    --     end
    -- end
    -- if not exists then
    --     table.insert(global.scan.inventories, inv)
    -- end

    -- Passed inventory MUST be owned by an entity
    local ent = inv.entity_owner
    if not ent then
        return
    end

    global.scan.inventories[ent.unit_number] = inv
end

local get_ghosts_on_chunk = function(ch)
    -- Get some variables to work with
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)
    -- local ch = get_current_chunk()

    -- Initiate ghost_types array
    if not srf.ghost_types then
        srf.ghost_types = {}
    end

    -- Check if chunk is generated
    local pos = {ch.x, ch.y}
    local gf
    if surface.surface.is_chunk_generated(pos) then
        -- Find all ghosts in the chunk
        gf = surface.surface.find_entities_filtered({
            type = const.types.GHOST_ENTITY,
            area = ch.area
        })
    end

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

local get_storages_on_chunk = function(ch)
    -- Get some variables to work with
    local surface = get_current_surface()
    local srf = get_data_surface(surface.surface)
    -- local ch = get_current_chunk()

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

    -- Copy over statistics to settings
    for _, s in pairs(global.settings.surfaces) do
        if s.surface == surface.surface then
            -- Chunks scanned
            s.num_chunks = surface.chunks_indexed
        end
    end

    -- Index all players on the surface
    for _, p in pairs(game.players) do
        if p.surface == surface.surface and p.character then
            -- local inv = p.get_inventory(defines.inventory.character_main)
            local inv = p.character.get_inventory(defines.inventory.character_main)
            add_scan_inventory(inv)
        end
    end

    -- Generate arrays for ghost.unit_numbers used
    srf.ghost_indexes = {}
    for itm, arr in pairs(srf.ghost_types) do
        table.insert(srf.ghost_indexes, itm)
    end

    -- Generate arrays for scan.inventory.unit_numbers used
    global.scan.inventory_indexes = {}
    for itm, arr in pairs(global.scan.inventories) do
        table.insert(global.scan.inventory_indexes, itm)
    end

    -- Add the surface
    srf.surface = surface.surface

    -- Empty the inventory array if there are no ghosts
    if util.arr_cnt(srf.ghost_types) == 0 then
        global.scan.inventories = {}
        global.scan.inventory_indexes = {}
        return
    end

end

local index_step = function()
    -- Get some variables to work with
    local surface = get_current_surface()
    -- local ch = get_current_chunk()
    local ch
    local action = 1

    while action <= settings.global["gh_index-chunks-per-tick"].value do
        -- Get next chunk
        ch = get_current_chunk()

        -- Early exit if there are no more chunks remaining
        if not ch then
            surface.has_chunks = false
            break
        end

        -- Scan the chunk & store data in array
        get_ghosts_on_chunk(ch)
        get_storages_on_chunk(ch)

        -- Increase indexes
        surface.chunks_indexed = (surface.chunks_indexed or 0) + 1
        global.track.chunks_indexed = (global.track.chunks_indexed or 0) + 1
        action = action + 1

    end

    -- Post chunk scan actions
    -- if #surface.chunks == 0 then
    if not surface.has_chunks then
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
    -- if #global.scan.inventories > 0 then
    -- local inv = global.scan.inventories[#global.scan.inventories]
    if #global.scan.inventory_indexes > 0 then
        local iidx = global.scan.inventory_indexes[#global.scan.inventory_indexes]
        local inv = global.scan.inventories[iidx]
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
    end

    -- Increase the ghost index
    global.track.ghost_idx = global.track.ghost_idx + 1

    -- Reset ghost index if it exceeded the array length and pop the inventory array
    if global.track.ghost_idx > #srf.ghost_indexes then
        global.track.ghost_idx = 1
        global.scan.inventory_indexes[#global.scan.inventory_indexes] = nil
    end
end
local scan_step = function()
    -- Get some variables to work with
    local action = 1

    while action <= settings.global["gh_scan-actions-per-tick"].value do
        -- Pop the current surface when we're done
        if #global.scan.inventory_indexes == 0 then
            pop_current_surface()
            return
        end

        -- Perform the search action
        search_inventory_for_ghost()

        -- Increase the indexes
        global.track.searches_performed = (global.track.searches_performed or 0) + 1
        action = action + 1
    end
end

------------------------------------------------------------------------------------------
-- Public interfaces
------------------------------------------------------------------------------------------

----- Progress -----
ghost_tracker.get_total_chunks = function()
    return global.track.total_chunks or 1
end

ghost_tracker.get_chunks_indexed = function()
    return global.track.chunks_indexed or 0
end

ghost_tracker.get_total_entities = function()
    local num_ghosts = 0
    local num_chests = 0
    local num_searches = 0
    for i, srf in pairs(global.data.surfaces) do
        -- Count current ghosts on this surface
        local srf_ghosts = 0
        for itm, gt in pairs(srf.ghost_types) do
            -- srf_ghosts = srf_ghosts + util.arr_cnt(gt.ghosts)
            srf_ghosts = srf_ghosts + 1
            -- util.silent("Surface: " .. srf.surface.name .. ", itm: " .. itm .. ", ghost cnt: " .. srf_ghosts)
        end
        num_ghosts = num_ghosts + srf_ghosts

        -- If there are no ghosts on this surface then we also don't need to count the inventories because the surface won't be scanned
        -- local srf_chests = 1
        -- if srf_ghosts > 0 and srf.storage_entities then
        --     srf_chests = srf_chests + util.arr_cnt(srf.storage_entities)
        -- end
        local srf_chests = util.arr_cnt(srf.storage_entities)
        num_chests = num_chests + srf_chests

        local srf_searches = (srf_ghosts * srf_chests)
        num_searches = num_searches + srf_searches
    end

    return num_searches, num_ghosts, num_chests
end

ghost_tracker.get_num_searches_performed = function()
    return global.track.searches_performed or 0
end

ghost_tracker.get_progress = function()
    -- Returns the progress in a range of 0..1

    -- Get some variables to work with

    -- Indexes
    local chunks_per_tick = settings.global["gh_index-chunks-per-tick"].value
    local total_indexes = ghost_tracker.get_total_chunks()
    local total_index_ticks = math.ceil(total_indexes / chunks_per_tick) -- Total nr of ticks required to index all chunks
    local current_indexes = ghost_tracker.get_chunks_indexed()
    local current_index_ticks = math.floor(current_indexes / chunks_per_tick) -- Ticks used so far to index chunks

    -- Searches
    local searches_per_tick = settings.global["gh_scan-actions-per-tick"].value
    local total_searches, num_ghosts, num_chests = ghost_tracker.get_total_entities()
    local total_search_ticks = math.ceil(total_searches / searches_per_tick) -- Total nr of ticks required to search all chests for all ghosts
    local current_searches = ghost_tracker.get_num_searches_performed()
    local current_search_ticks = math.floor(current_searches / searches_per_tick) -- Ticks used so far for searching

    -- Totals
    local total_actions = total_searches + total_indexes
    local total_ticks = total_index_ticks + total_search_ticks
    local current_ticks = current_index_ticks + current_search_ticks

    -- If this is the first cycle we perform a full scan we don't know how many chunks/ghosts/inventories there are yet, so the total_actions will return 1
    if total_actions == 1 then
        -- Display the progress of surfaces vs total nr of surfaces
        local num_srf_remain = 0
        if global.scan.surfaces then
            num_srf_remain = #global.scan.surfaces
        end
        local tot_srf = 0
        if global.settings.surfaces then
            tot_srf = #global.settings.surfaces
        end
        local surfaces_remaining = math.max(0, tot_srf - num_srf_remain)
        local total_surfaces = tot_srf + 1

        -- Return the proportion of surfaces processed
        return surfaces_remaining / total_surfaces, -1
    else
        -- util.silent(
        --     "Indexes: " .. current_index_ticks .. "/" .. total_index_ticks .. " - Searches: " .. current_search_ticks ..
        --         "/" .. total_search_ticks)
        -- util.silent("Indexes: " .. current_indexes .. "/" .. total_indexes .. " - Searches: " .. current_searches .. "/" ..
        --            total_searches)
        return math.min(1, (current_ticks / total_ticks)), total_ticks
    end
end

----- Get data -----
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

----- Scheduled -----

ghost_tracker.tick_update = function()
    -- Early exit if disabled
    if not settings.global["gh_enable"].value then
        return
    end

    if #global.scan.surfaces == 0 then
        local component = const.settings.measurement.component.SURFACE
        timer.start_measurement(component)
        -- Populate the scan surfaces array with new data
        update_surfaces()

        -- Update the tick count history array
        local tot = 0
        for i = #global.track.history, 2, -1 do
            local prev = global.track.history[i - 1]
            global.track.history[i] = prev
            tot = tot + prev
        end

        -- Reset scan & index trackers
        global.track.chunks_indexed = 0
        global.track.searches_performed = 0 -- Update the average ticks
        global.track.avg_num_ticks_per_cycle = math.ceil(tot / #global.track.history)

        -- Reset the first entry
        global.track.history[1] = 0

        timer.end_measurement(component)
        -- elseif #global.scan.surfaces[#global.scan.surfaces].chunks > 0 then
    elseif global.scan.surfaces[#global.scan.surfaces].has_chunks then
        -- Index chunks while there are still chunks left to be indexed
        local component = const.settings.measurement.component.INDEX
        timer.start_measurement(component)
        index_step()
        timer.end_measurement(component)

    else
        -- Perform the scan step
        local component = const.settings.measurement.component.SEARCH
        timer.start_measurement(component)
        scan_step()
        timer.end_measurement(component)
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

    -- Global.data is the static copy of a completed global.scan.data
    global.data = {}

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
    if not global.track.timer then
        global.track.timer = {}
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
