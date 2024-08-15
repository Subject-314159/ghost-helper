local const = require("lib.const")
local util = require("lib.util")

local gutil = {}

gutil.get_gui_outer = function(player)
    if player and player.gui.left[const.gui.outer.FRAME] then
        return player.gui.left[const.gui.outer.FRAME]
    end
end

gutil.get_gui_window = function(player, component)
    local outer = gutil.get_gui_outer(player)
    if outer then
        return outer[component]
    end
end

gutil.get_main_gui = function(player)
    return gutil.get_gui_window(player, const.gui.main.FRAME)
end

gutil.get_settings_gui = function(player)
    return gutil.get_gui_window(player, const.gui.settings.FRAME)
end

gutil.add_generic_title_bar = function(gui, caption)
    gui.add {
        type = "flow",
        name = "titlebar",
        style = "gh_titlebar_flow"
    }
    gui.titlebar.add {
        type = "label",
        style = "frame_title",
        caption = caption
    }
    gui.titlebar.add {
        type = "empty-widget",
        style = "gh_titlebar_drag_handle"
    }
end

return gutil
