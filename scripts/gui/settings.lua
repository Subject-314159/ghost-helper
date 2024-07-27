local const = require("lib.const")
local util = require("lib.util")
local helper = require("scripts.ghost-tracker")
local timer = require("scripts.timer")
local global_player = require("scripts.global-player")

local gutil = require("scripts.gui.util")

local gui_settings = {}

---------------------------------------------------------------------------
-- COMPONENTS
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------

local function update_setting(setting_flow)

    local sl = setting_flow.slider
    local tb = setting_flow.val
    local tgt = settings.global[tb.tags.setting].value
    local max = tb.tags.max

    -- Slider position
    local tslid = math.ceil((tgt / max) * 20)

    -- Slider
    if sl then
        if sl.slider_value ~= tslid then
            sl.slider_value = tslid
        end
    end

    -- Text box
    if tb then
        if tonumber(tb.text) ~= tgt then
            tb.text = "" .. tgt
        end
    end
end

gui_settings.update = function(player)
    -- Update settings gui if it is open
    local sgui = gutil.get_settings_gui(player)
    if not sgui then
        return
    end
    -- Get some variables to work with
    local gp = global_player.get(player)
    local cs = sgui.tab_outer.settings_tabs.content_surfaces
    local cm = sgui.tab_outer.settings_tabs.content_modsettings

    ----------------------------------------
    -- SURFACES
    ----------------------------------------

    local srf = "Surfaces being scanned:  "
    for _, s in pairs(global.settings.surfaces) do
        srf = srf .. s.surface.name .. ",  "
    end
    cs.surface_info.caption = srf

    ----------------------------------------
    -- SETTINGS
    ----------------------------------------

    -- Do spaced updates here, mainly for the time measurement update because fast changing numbers are annoying
    if not gp.spaced_setting_gui_update_ticks or gp.spaced_setting_gui_update_ticks > 60 then

        -- Get the latest measurements
        cm.surface.duration.caption = timer.get_measurement_results(const.settings.measurement.component.SURFACE)
        cm.chunk.duration.caption = timer.get_measurement_results(const.settings.measurement.component.INDEX)
        cm.search.duration.caption = timer.get_measurement_results(const.settings.measurement.component.SEARCH)

        -- Tracking entities only when active
        if gp.track_start and game.tick <= gp.track_start + (settings.global["gh_arrow-time-to-live"].value * 60) then
            cm.tracker.duration.caption = timer.get_measurement_results(const.settings.measurement.component.ANNOTATE)
        else
            cm.tracker.duration.caption = "No entities being tracked"
        end
        -- Reset the tick counter
        gp.spaced_setting_gui_update_ticks = 0
    end

    -- Update spaced update counter
    gp.spaced_setting_gui_update_ticks = (gp.spaced_setting_gui_update_ticks or 0) + 1

    -- Update GUI according to settings
    local set, tgt, sl, tb

    -- Update flows
    update_setting(cm.chunk.setting)
    update_setting(cm.search.setting)
    update_setting(cm.tracker.setting)
end

---------------------------------------------------------------------------
-- BUILD
---------------------------------------------------------------------------

gui_settings.destroy = function(player)

    local gui = gutil.get_settings_gui(player)
    if gui then
        gui.destroy()
    end
end

gui_settings.build = function(player)

    -- Get outer frame or early exit
    local outer = gutil.get_gui_outer(player)
    if not outer then
        return
    end

    -- Early exit if main window already exists
    local gui = gutil.get_settings_gui(player)
    if gui then
        return
    end

    -------------------------
    -- Main window
    -------------------------
    gui = outer.add {
        type = "frame",
        name = const.gui.settings.FRAME,
        direction = "vertical"
    }
    gui.style.minimal_width = 300
    gui.style.minimal_height = 500
    gui.style.horizontally_stretchable = "on"
    gui.style.vertically_stretchable = "on"

    -- Title bar
    gutil.add_generic_title_bar(gui, {const.gui.settings.CAPTION})

    local to = gui.add {
        type = "frame",
        name = "tab_outer",
        style = "inside_deep_frame_for_tabs"
    }

    -- Tabs container
    local tabs = to.add {
        type = "tabbed-pane",
        -- direction = "vertical",
        name = "settings_tabs",
        style = "tabbed_pane_with_no_side_padding"
    }
    tabs.style.horizontally_stretchable = "on"
    tabs.style.vertically_stretchable = "on"

    -- =======================
    -- Surfaces tab
    -- =======================
    local ts = tabs.add {
        type = "tab",
        name = "tab_surfaces",
        caption = "Surfaces",
        style = "tab"
    }
    local cs = tabs.add {
        type = "flow",
        name = "content_surfaces"
    }
    cs.style.margin = 10
    tabs.add_tab(ts, cs)

    cs.add {
        type = "label",
        name = "surface_info",
        caption = "Foo"
    }
    cs.surface_info.style.single_line = false
    cs.surface_info.style.maximal_width = 300

    -- =======================
    -- Mod settings tab
    -- =======================
    local tm = tabs.add {
        type = "tab",
        name = "tab_modsettings",
        caption = "Mod settings",
        style = "tab"
    }
    local cm = tabs.add {
        type = "flow",
        name = "content_modsettings",
        direction = "vertical"
    }
    cm.style.horizontally_stretchable = "on"
    cm.style.margin = 10
    tabs.add_tab(tm, cm)

    -- Generic how-to message
    cm.add {
        type = "label",
        name = "info_1",
        caption = "Adjust below settings to ~10ms or until UPS start to drop, whichever comes first. Lower duration is better for UPS but results in slower updates."
    }
    cm.info_1.style.single_line = false
    cm.info_1.style.maximal_width = 300

    local setflow

    -------------------------
    -- Surface stats
    -------------------------
    cm.add {
        type = "line"
    }
    cm.add {
        type = "flow",
        name = "surface",
        direction = "vertical"
    }
    cm.surface.add {
        type = "label",
        name = "title",
        caption = "Analyze surfaces",
        style = "bold_label"
    }
    cm.surface.add {
        type = "label",
        name = "duration",
        caption = "<duration>"
    }

    -------------------------
    -- Chunk/index stats & settings
    -------------------------
    cm.add {
        type = "line"
    }
    setflow = cm.add {
        type = "flow",
        name = "chunk",
        direction = "vertical"
    }
    setflow.add {
        type = "label",
        name = "title",
        caption = "Index chunks",
        style = "bold_label"
    }
    setflow.add {
        type = "label",
        name = "duration",
        caption = "<duration>"
    }

    setflow.add {
        type = "label",
        name = "label",
        caption = "Chunks to index per tick (mod setting)"
    }
    setflow.label.style.top_padding = 5

    -- Flow with slider and text field
    setflow.add {
        type = "flow",
        name = "setting",
        direction = "horizontal"
    }
    local tag = {
        setting = "gh_index-chunks-per-tick",
        max = const.settings.tick_actions.index.MAX
    }
    setflow.setting.add {
        type = "slider",
        name = "slider",
        style = "notched_slider",
        -- value = math.ceil((settings.global["gh_index-chunks-per-tick"].value / const.settings.tick_actions.index.MAX) *
        --                       20), --To be updated in update()
        minimum_value = 1,
        maximum_value = 20,
        tags = tag
    }
    setflow.setting.add {
        type = "textfield",
        name = "val",
        -- text = "" .. settings.global["gh_index-chunks-per-tick"].value,
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        tags = tag
    }
    setflow.setting.val.style.width = 50

    -------------------------
    -- Search stats & settings
    -------------------------
    cm.add {
        type = "line"
    }
    setflow = cm.add {
        type = "flow",
        name = "search",
        direction = "vertical"
    }
    setflow.add {
        type = "label",
        name = "title",
        caption = "Search ghosts & chests",
        style = "bold_label"
    }
    setflow.add {
        type = "label",
        name = "duration",
        caption = "<duration>"
    }
    setflow.add {
        type = "label",
        name = "label",
        caption = "Ghosts & chests to search per tick (mod setting)"
    }
    setflow.label.style.top_padding = 5
    -- Flow with slider and text field
    setflow.add {
        type = "flow",
        name = "setting",
        direction = "horizontal"
    }
    local tag = {
        setting = "gh_scan-actions-per-tick",
        max = const.settings.tick_actions.search.MAX
    }
    setflow.setting.add {
        type = "slider",
        name = "slider",
        style = "notched_slider",
        minimum_value = 1,
        maximum_value = 20,
        tags = tag
    }
    setflow.setting.add {
        type = "textfield",
        name = "val",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        tags = tag
    }
    setflow.setting.val.style.width = 50

    -------------------------
    -- Arrow tracker
    -------------------------
    cm.add {
        type = "line"
    }
    setflow = cm.add {
        type = "flow",
        name = "tracker",
        direction = "vertical"
    }
    setflow.add {
        type = "label",
        name = "title",
        caption = "Track entities",
        style = "bold_label"
    }
    setflow.add {
        type = "label",
        name = "duration",
        caption = "<duration>"
    }
    setflow.add {
        type = "label",
        name = "label",
        caption = "Entities to track with arrows per tick (mod setting)"
    }
    setflow.label.style.top_padding = 5
    -- Flow with slider and text field
    setflow.add {
        type = "flow",
        name = "setting",
        direction = "horizontal"
    }
    local tag = {
        setting = "gh_track-entities-per-tick",
        max = const.settings.tick_actions.annotate.MAX
    }
    setflow.setting.add {
        type = "slider",
        name = "slider",
        style = "notched_slider",
        minimum_value = 1,
        maximum_value = 20,
        tags = tag
    }
    setflow.setting.add {
        type = "textfield",
        name = "val",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        tags = tag
    }
    setflow.setting.val.style.width = 50

    -- Bottom line & footnote
    cm.add {
        type = "line"
    }
    cm.add {
        type = "label",
        name = "info_2",
        caption = "See Menu -> Settings -> Mod settings -> Map for all other settings."
    }
    cm.info_2.style.single_line = false

    -- Reset spaced update counter
    local gp = global_player.get(player)
    gp.spaced_setting_gui_update_ticks = nil

    -- Store reference to gui in global
    local global_player = global_player.get(player)
    global_player.gui_settings = gui

    -- Update the setttings frame
    gui_settings.update(player)
end
return gui_settings
