local const = require("lib.const")
local timer = require("scripts.timer")
local global_player = require("scripts.global-player")

require("util")

local ghost_finder = {}

------------------------------------------------------------------------------------------
-- Helper functions
------------------------------------------------------------------------------------------

local get_pt = function(character, entity)
    local pt = {
        first = {
            x = character.position.x,
            y = character.position.y
        },
        second = {
            x = entity.position.x,
            y = entity.position.y
        }
    }
    pt.delta = {
        -- x = pt.second.x - pt.first.x,
        -- y = pt.second.y - pt.first.y
        x = pt.first.x - pt.second.x,
        y = pt.second.y - pt.first.y
    }
    return pt
end

local get_distance = function(character, entity)
    local pt = get_pt(character, entity)
    local distance = math.sqrt(pt.delta.x ^ 2 + pt.delta.y ^ 2) - 0.5
    return distance
end

local calculate = function(character, entity)

    -- Get some variables to work with
    local pt = get_pt(character, entity)

    -- Prepare the return array
    local prop = {}

    -- Do the calculations
    -- Angle calculations
    prop.angle_rad = math.atan2(pt.delta.x, pt.delta.y) + (math.pi / 2)
    prop.angle_deg = prop.angle_rad * (180 / math.pi)

    -- Segmented angle
    local deg_seg = 20
    local angle_corr = prop.angle_deg - (deg_seg / 2)
    prop.angle_deg_seg = math.floor((angle_corr) / deg_seg) * deg_seg

    prop.distance = get_distance(character, entity)
    prop.offset = math.min(prop.distance, 5) -- Draw the arrow at max 5 meter
    prop.offx = prop.offset * math.cos(prop.angle_rad)
    prop.offy = prop.offset * math.sin(prop.angle_rad)

    return prop

end

local box_has_area = function(box)
    return box and box.left_top.x < 0 and box.left_top.y < 0 and box.right_bottom.x > 0 and box.right_bottom.y > 0
end

local get_angle_corrected = function(angle)
    if not angle then
        return 0
    end
    return ((angle + 90) / 360) or 0
end

------------------------------------------------------------------------------------------
-- Validity check
------------------------------------------------------------------------------------------

-- update_boxes(p, gp)
-- update_arrows(p, gp)
local validate = function(p, gp)
    -- Early exit if we do not have a character
    if not p.character then
        return
    end

    -- Initiate scan array
    if not gp.scan then
        gp.scan = {}
    end
    if not gp.scan.to_track then
        gp.scan.to_track = {}
    end
    if not gp.to_track then
        gp.to_track = {}
    end

    -- Spaced update
    local action = 1

    while action < 100 do
        -- Get entity to track index
        local idx = gp.scan.track_entity_idx or 1
        if idx > #gp.track_entities then
            -- All entities analyzed, copy over scan to gp
            -- for id, prop in pairs(gp.scan.to_track) do
            --     gp.to_track[id] = prop
            -- end
            gp.to_track = gp.scan.to_track

            -- Clear scan.to_track array
            gp.scan.to_track = {}

            -- Reset index counters
            gp.scan.track_entity_idx = 1
        else
            -- Continue scanning
            local e = gp.track_entities[idx]
            if e.valid then
                local prop = calculate(p.character, e)
                local id = ""
                local draw_arrow = false
                local draw_box = false
                -- Distance based
                if prop.distance < 100 then
                    -- Make ID based on entity position
                    local pos = e.position
                    id = "entity-x" .. pos.x .. "-y" .. pos.y -- The entity ID
                    if prop.distance >= 5 then
                        -- Draw arrow only when further than 5m
                        draw_arrow = true
                    else
                    end
                    -- Draw box always
                    draw_box = true
                else
                    -- Make ID based on angle segment
                    id = "angle-seg" .. prop.angle_deg_seg -- The entity ID
                    draw_arrow = true
                end

                gp.scan.to_track[id] = {
                    id = id,
                    entity = e,
                    prop = prop,
                    draw_arrow = draw_arrow,
                    draw_box = draw_box,
                    last_update = game.tick
                }
            end
            -- Increase scan index
            gp.scan.track_entity_idx = idx + 1
        end

        -- Increase action counter
        action = action + 1
    end

end

------------------------------------------------------------------------------------------
-- Render new
------------------------------------------------------------------------------------------

local draw_arrow = function(p, drew)
    -- Early exit if we already drew this one
    if drew and drew.arrow and rendering.is_valid(drew.arrow) then
        return
    end

    local prop = {
        sprite = "utility/alert_arrow",
        orientation = get_angle_corrected(drew.data.prop.angle_deg),
        -- orientation_target = e,
        target = p.character,
        target_offset = {
            x = drew.data.prop.offx,
            y = drew.data.prop.offy
        },
        surface = drew.data.entity.surface,
        time_to_live = settings.global["gh_arrow-time-to-live"].value * 60,
        x_scale = 2,
        y_scale = 2
    }

    -- Draw & remember the box
    drew.arrow = rendering.draw_sprite(prop)
end

local remove_arrow = function(p, drew)
    if not drew or not drew.arrow then
        return
    end
    if rendering.is_valid(drew.arrow) then
        rendering.destroy(drew.arrow)
    end
end

local draw_box = function(p, drew)
    -- Early exit if we already drew this one
    if drew and drew.box and rendering.is_valid(drew.box) then
        return
    end

    -- Get entity
    local e = drew.data.entity

    -- Get box coordinates
    local ent = e.prototype
    if e.type == 'entity-ghost' then
        ent = e.ghost_prototype
    end
    local lefttop = {
        x = -0.5,
        y = -0.5
    }
    local rightbottom = {
        x = 0.5,
        y = 0.5
    }

    -- Get entity box properties
    if ent.selection_box and box_has_area(ent.selection_box) then
        lefttop = ent.selection_box.left_top
        rightbottom = ent.selection_box.right_bottom

    elseif ent.collision_box and box_has_area(ent.collision_box) then
        lefttop = ent.collision_box.left_top
        rightbottom = ent.collision_box.right_bottom

    elseif ent.drawing_box and box_has_area(ent.drawing_box) then
        lefttop = ent.drawing_box.left_top
        rightbottom = ent.drawing_box.right_bottom
    end

    local prop = {
        color = {0.8, 0.5, 0},
        left_top = {
            x = e.position.x + lefttop.x,
            y = e.position.y + lefttop.y
        },
        right_bottom = {
            x = e.position.x + rightbottom.x,
            y = e.position.y + rightbottom.y
        },
        surface = e.surface,
        time_to_live = settings.global["gh_arrow-time-to-live"].value * 60
    }

    -- Draw & remember the box
    drew.box = rendering.draw_rectangle(prop)
end
local update_arrow = function(p, drew)
    -- Sanity check
    if not drew or not drew.arrow then
        game.print("Not drawn")
        return
    end
    if not rendering.is_valid(drew.arrow) then
        game.print("Not valid")
        return
    end

    -- Update orientation
    rendering.set_orientation(drew.arrow, get_angle_corrected(drew.data.prop.angle_deg))

    local target = p.character
    local target_offset = {
        x = drew.data.prop.offx,
        y = drew.data.prop.offy
    }
    -- Update offset
    rendering.set_target(drew.arrow, target, target_offset)
end

local remove_render = function(gp, drew_id)
    -- Get some variables to work with
    local arr = gp.drew[drew_id]

    -- Remove sprites and array entry
    if arr.arrow then
        rendering.destroy(arr.arrow)
    end
    if arr.box then
        rendering.destroy(arr.box)
    end
    gp.drew[drew_id] = nil
end

local remove_all_renders = function(player)
    local gp = global_player.get(player)

    -- Early exit if we did not draw anything
    if not gp.drew then
        return
    end

    -- Remove all renders
    for id, arr in pairs(gp.drew) do
        remove_render(gp, id)
    end

    -- Clear all arrays
    gp.to_track = {}
    gp.scan = {}
end

local draw = function(p, gp)
    -- Early exit if there is nothing to draw
    if not gp.to_track then
        return
    end

    -- Initiate render array
    if not gp.drew then
        gp.drew = {}
    end
    if not gp.to_track_indexes then
        gp.to_track_indexes = {} -- Index translation array 
    end

    -- Get some variables to work with
    local threshold = gp.track_start + (settings.global["gh_arrow-time-to-live"].value * 60)

    -- Remove sprites which are no longer required
    -- Iterate over drew sprites
    for eid, arr in pairs(gp.drew) do
        -- Check if we need to track this entity id
        if not gp.to_track[eid] then
            remove_render(gp, eid)
        end
    end

    -- Spaced update
    local action = 1

    while action < settings.global["gh_track-entities-per-tick"].value do
        -- Get index
        local idx = gp.draw_entity_idx or 1
        if idx > #gp.to_track_indexes then
            -- Repopulate track indexes
            local i = 1
            for id, _ in pairs(gp.to_track) do
                gp.to_track_indexes[i] = id
                i = i + 1
            end

            -- game.print(serpent.line(gp.to_track_indexes))

            idx = 1
        end
        local id = gp.to_track_indexes[idx]
        local data = gp.to_track[id]

        -- Only if we have data
        if data then
            -- Check if this still needs to be tracked by tick
            -- local threshold = game.tick - (settings.global["gh_arrow-time-to-live"].value * 60)
            if data.last_update > threshold then
                gp.to_track[id] = nil
            else
                -- Add/update sprites which are still to be tracked
                -- Check if the id is new
                local new = not gp.drew[id]
                if new then
                    gp.drew[id] = {}
                end

                -- Update the data
                gp.drew[id].data = data

                -- Draw new sprites
                -- if new then
                -- Draw the new sprite
                if data.draw_arrow then
                    draw_arrow(p, gp.drew[id])
                    update_arrow(p, gp.drew[id])
                else
                    remove_arrow(p, gp.drew[id])
                end
                if data.draw_box then
                    draw_box(p, gp.drew[id])
                end

            end
        end

        gp.draw_entity_idx = idx + 1
        action = action + 1
    end
end

local ping = function(player, entity)
    if entity and entity.valid then
        player.print(entity.name .. ' at [gps=' .. (entity.position.x) .. ',' .. (entity.position.y) .. ',' ..
                         entity.surface.name .. ']')
    end
end

ghost_finder.set_new_entities_to_track = function(player, entities)
    -- Early exit if no entities passed
    if not entities then
        return
    end

    -- Get some variables to work with
    local gp = global_player.get(player)
    local announce = settings.global["gh_announce-chat"].value

    -- Initiate & fill the array
    local i = 1
    if not gp.track_entities then
        gp.track_entities = {}
    end
    gp.track_entities = {}
    for _, ent in pairs(entities) do
        gp.track_entities[i] = ent
        if announce then
            ping(player, ent)
        end
        i = i + 1
    end

    -- Warn player when tracking more ghosts than can be handled in one tick update
    if i > settings.global["gh_track-entities-per-tick"].value then
        player.print("[Ghost Handler] WARNING: Tracking large amount of entities (" .. i ..
                         ") may result in hampering arrow accuracy")
    end

    -- Remove all old annotations
    remove_all_renders(player)

    -- Set global player stats
    if not gp.scan then
        gp.scan = {}
    end
    gp.scan.track_entity_idx = 1
    gp.track_start = game.tick

end

ghost_finder.tick_update = function()
    -- Early exit if we do not have access to game yet
    if not game then
        return
    end

    -- Get some variables to work with
    local component = const.settings.measurement.component.ANNOTATE

    -- Update each player
    for _, p in pairs(game.players) do
        -- Get the global player
        local gp = global_player.get(p)

        -- Only if we are inside the time to live window
        if gp.track_start and game.tick <= gp.track_start + (settings.global["gh_arrow-time-to-live"].value * 60) then

            -- Start timer
            timer.start_measurement(component)

            -- Do update
            validate(p, gp)
            draw(p, gp)

            -- End timer
            timer.end_measurement(component)
        else
            remove_all_renders(p)
        end
    end

end

ghost_finder.init = function()

end

return ghost_finder
