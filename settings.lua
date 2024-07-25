data:extend({{
    type = "bool-setting",
    name = "gh_enable",
    setting_type = "runtime-global",
    default_value = 500,
    minimum_value = 1,
    maximum_value = 10000,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_index-chunks-per-tick",
    setting_type = "runtime-global",
    default_value = 500,
    minimum_value = 1,
    maximum_value = 10000,
    order = "a1"
}, {
    type = "int-setting",
    name = "gh_scan-actions-per-tick",
    setting_type = "runtime-global",
    default_value = 50,
    minimum_value = 1,
    maximum_value = 500,
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
