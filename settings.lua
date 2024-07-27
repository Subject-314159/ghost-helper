local const = require("lib.const")

data:extend({{
    type = "bool-setting",
    name = "gh_enable",
    setting_type = "runtime-global",
    default_value = true,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_index-chunks-per-tick",
    setting_type = "runtime-global",
    default_value = const.settings.tick_actions.index.DEFAULT,
    minimum_value = const.settings.tick_actions.index.MIN,
    maximum_value = const.settings.tick_actions.index.MAX,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_scan-actions-per-tick",
    setting_type = "runtime-global",
    default_value = const.settings.tick_actions.search.DEFAULT,
    minimum_value = const.settings.tick_actions.search.MIN,
    maximum_value = const.settings.tick_actions.search.MAX,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_track-entities-per-tick",
    setting_type = "runtime-global",
    default_value = const.settings.tick_actions.annotate.DEFAULT,
    minimum_value = const.settings.tick_actions.annotate.MIN,
    maximum_value = const.settings.tick_actions.annotate.MAX,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_arrow-time-to-live",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 60,
    order = "a2"
}, {
    type = "bool-setting",
    name = "gh_announce-chat",
    setting_type = "runtime-global",
    default_value = true,
    order = "a3"
}, {
    type = "string-setting",
    name = "gh_show-progress-bar",
    setting_type = "runtime-global",
    default_value = "1 sec",
    allowed_values = {"never", "1 sec", "5 sec", "10 sec", "30 sec", "always"},
    order = "a3"
}})
