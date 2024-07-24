data:extend({{
    type = "int-setting",
    name = "scan-actions-per-tick",
    setting_type = "runtime-global",
    default_value = 16,
    minimum_value = 1,
    maximum_value = 256,
    order = "a1"
}, {
    type = "int-setting",
    name = "arrow-time-to-live",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 60,
    order = "a2"
}, {
    type = "bool-setting",
    name = "announce-chat",
    setting_type = "runtime-global",
    default_value = true,
    order = "a3"
}})
