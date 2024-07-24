local global_player = require("scripts.global-player")

local ghost_finder = {}

local calculate = function(character, entity)

    -- Get some variables to work with
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

    -- Prepare the return array
    local prop = {}

    -- Do the calculations
    prop.angle_rad = math.atan2(pt.delta.x, pt.delta.y) + (math.pi / 2)
    prop.angle_deg = prop.angle_rad * (180 / math.pi)
    prop.distance = math.sqrt(pt.delta.x ^ 2 + pt.delta.y ^ 2) - 0.5
    prop.offset = math.min(prop.distance, 5) -- Draw the arrow at max 5 meter
    prop.offx = prop.offset * math.cos(prop.angle_rad)
    prop.offy = prop.offset * math.sin(prop.angle_rad)

    return prop

end

local box_has_area = function(box)
    return box and box.left_top.x < 0 and box.left_top.y < 0 and box.right_bottom.x > 0 and box.right_bottom.y > 0
end

local update_boxes = function(p, gp)
    -- Init array
    if not gp.drew then
        gp.drew = {}
    end

    -- Remove old boxes
    if gp.drew.boxes then
        for _, b in pairs(gp.drew.boxes) do
            rendering.destroy(b)
        end
    end
    -- Clear the array
    gp.drew.boxes = {}

    -- Add new boxes
    if game.tick <= gp.track_start + (settings.global["arrow-time-to-live"].value * 60) then
        for _, e in pairs(gp.track_entities) do
            if e.valid then
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

                -- Draw the box
                local id = rendering.draw_rectangle({
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
                    time_to_live = settings.global["arrow-time-to-live"].value * 60
                })

                -- Store the id in the array
                table.insert(gp.drew.boxes, id)
            end
        end
    end

end

local update_arrows = function(p, gp)

    -- Erase all previous arrows
    if gp.drew.arrows then
        for _, a in pairs(gp.drew.arrows) do
            rendering.destroy(a)
        end
    end

    -- Reset the arrow array
    gp.drew.arrows = {}

    -- Draw new arrows, but only within the time to live window
    if game.tick <= gp.track_start + (settings.global["arrow-time-to-live"].value * 60) then
        -- Only if the player is on the same surface
        if p.character and p.character.surface == gp.track_entities[1].surface then
            for _, e in pairs(gp.track_entities) do
                if e.valid then
                    -- Calculate the angle/distance between player and entity
                    local prop = calculate(p.character, e)
                    -- Draw the arrow if it is further away than 5m
                    if prop.distance >= 5 then
                        local id = rendering.draw_sprite({
                            sprite = "utility/alert_arrow",
                            orientation = (prop.angle_deg + 90) / 360,
                            -- orientation_target = e,
                            target = p.character,
                            target_offset = {
                                x = prop.offx,
                                y = prop.offy
                            },
                            surface = e.surface,
                            time_to_live = settings.global["arrow-time-to-live"].value * 60,
                            x_scale = 2,
                            y_scale = 2
                        })
                        -- Store the id in the array
                        table.insert(gp.drew.arrows, id)
                    end
                end
            end
        end
    end
end

ghost_finder.tick_update = function()
    -- Early exit if we do not have access to game yet
    if not game then
        return
    end

    for _, p in pairs(game.players) do
        -- Get the global player
        local gp = global_player.get(p)
        if gp.track_start then
            update_boxes(p, gp)
            update_arrows(p, gp)

        end
    end
end

ghost_finder.init = function()

end

return ghost_finder
