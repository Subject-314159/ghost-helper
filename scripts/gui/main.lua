local const = require("lib.const")
local util = require("lib.util")
local helper = require("scripts.ghost-tracker")
local global_player = require("scripts.global-player")

local gutil = require("scripts.gui.util")

local gui_main = {}

---------------------------------------------------------------------------
-- COMPONENTS
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------

gui_main.update = function(player)
    -- Get the player's gui or early exit if not open
    local gui = gutil.get_main_gui(player)
    if not gui then
        return
    end

    -- Show/hide content based on global enable/disable
    if settings.global["gh_enable"].value then
        gui.progress.visible = true
        gui.pane.visible = true
        gui.disabled.visible = false
    else
        gui.progress.visible = false
        gui.pane.visible = false
        gui.disabled.visible = true
    end

    -- Get the information to work with
    local data = helper.get_ghosts_grouped(player)
    local tb_str = "" -- TEMP

    -- Set the generic progress bar
    local progress, ticks_required = helper.get_progress()

    if ticks_required == -1 or ticks_required >
        const.settings.map.PROGRESS_BAR_TICKS[settings.global["gh_show-progress-bar"].value] then
        gui.progress.visible = true
        gui.progress.value = progress
    else
        -- Hide the progress bar if update cycle is less than 1sec
        gui.progress.visible = false
    end

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
                style = "gh_surface_frame",
                direction = "vertical"
            }
            srf_frm.add {
                type = "label",
                name = const.gui.main.surface.label.PREFIX .. srf.surface.index,
                caption = "Ghosts on " .. srf.surface.name,
                style = "gh_surface_name_label"
            }
        end

        if srf_frm then

            -- Loop through labels and remove ones no longer applicable
            for _, lbl in pairs(srf_frm.children) do
                local exists = false
                for itm, gt in pairs(srf.ghost_types) do
                    if lbl.name == const.gui.main.surface.ghost_frame.PREFIX .. itm then
                        exists = true
                    end
                end
                if lbl.name ~= const.gui.main.surface.label.PREFIX .. srf.surface.index and not exists then
                    lbl.destroy()
                end
            end

            -- Loop through ghost types on this surface and show label
            for itm, gt in pairs(srf.ghost_types) do
                local exists = false
                local fr
                for _, frm in pairs(srf_frm.children) do
                    if frm.name == const.gui.main.surface.ghost_frame.PREFIX .. itm then
                        fr = frm
                        exists = true
                    end
                end
                if not exists then
                    local tag = {
                        surface_index = srf.surface.index,
                        entity = itm
                    }
                    -- Create the container frame
                    fr = srf_frm.add {
                        type = "frame",
                        name = const.gui.main.surface.ghost_frame.PREFIX .. itm, -- Ghost Frame
                        direction = "vertical",
                        style = "gh_ghost_frame"
                    }

                    local ifr = fr.add {
                        type = "frame",
                        name = "inner", -- Ghost Frame inner
                        direction = "vertical"
                    }

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
                        sprite = ("item/" .. itm),
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
                    game.print("Oops, no table found for " .. itm)
                end

                -- Do some calculations
                local delta = util.arr_cnt(gt.ghosts) - gt.storage.total_count
                local craftable = player.get_craftable_count(itm) or 0
                local threshold = math.min(delta, craftable)

                -- Set background tint
                if delta > 0 then
                    if (delta - craftable) > 0 and fr.inner.style ~= "gh_ghost_frame_red" then
                        fr.inner.style = "gh_ghost_frame_red"
                    elseif (delta - craftable) <= 0 and fr.inner.style ~= "gh_ghost_frame_orange" then
                        fr.inner.style = "gh_ghost_frame_orange"
                    end
                elseif delta <= 0 and fr.inner.style ~= "gh_ghost_frame_green" then
                    fr.inner.style = "gh_ghost_frame_green"
                end

                -- Update badge numbers
                local cnt = util.arr_cnt(gt.ghosts)
                if tbl.ghost_count.number ~= cnt then
                    tbl.ghost_count.number = cnt
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

---------------------------------------------------------------------------
-- BUILD
---------------------------------------------------------------------------

gui_main.destroy = function(player)
    local gui = gutil.get_main_gui(player)
    if gui then
        gui.destroy()
    end
    local outer = gutil.get_gui_outer(player)
    if outer then
        outer.destroy()
    end
end

gui_main.build = function(player)

    -- Make the outer container that will contain the main and settings frame
    local outer = gutil.get_gui_outer(player)
    if not outer then
        -- Make the container frame
        outer = player.gui.left.add {
            type = "flow",
            name = const.gui.outer.FRAME,
            direction = "horizontal"
        }
    end

    -- Early exit if main window already exists
    local gui = gutil.get_main_gui(player)
    if gui then
        return
    end

    -- Make the main window
    gui = outer.add {
        type = "frame",
        name = const.gui.main.FRAME,
        -- caption = {const.gui.main.CAPTION},
        direction = "vertical"
    }

    -- Title bar flow
    gutil.add_generic_title_bar(gui, {const.gui.main.CAPTION})
    gui.titlebar.add {
        type = "sprite-button",
        name = "gh_settings",
        style = "frame_action_button",
        -- sprite = "gh_settings"
        sprite = "arrow-right"
    }

    -- Progress bar
    gui.add {
        type = "progressbar",
        name = "progress",
        value = 0.5
    }
    gui.progress.style.horizontally_stretchable = "on"
    gui.progress.style.height = 10

    -- Main content
    gui.add {
        type = "scroll-pane",
        name = "pane",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto",
        style = "gh_main_pane"
    }

    gui.pane.add {
        type = "flow",
        name = "main_frame",
        direction = "vertical",
        style = "gh_main_frame"
    }
    gui.pane.main_frame.add {
        type = "label",
        name = "no_ghosts",
        caption = "No ghosts found in enabled surfaces"
    }
    gui.add {
        type = "label",
        name = "disabled",
        caption = "Ghost Helper is disabled in mod settings"
    }

    -- Store reference to gui in global
    local global_player = global_player.get(player)
    global_player.gui = gui

    -- Decorate the main frame
    gui_main.update(player)

end

return gui_main
