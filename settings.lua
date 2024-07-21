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
    name = "scan-inventories-per-tick",
    setting_type = "runtime-global",
    default_value = 16,
    minimum_value = 1,
    maximum_value = 256,
    order = "a1"
}, {
    type = "int-setting",
    name = "scan-ghost-types-per-tick",
    setting_type = "runtime-global",
    default_value = 4,
    minimum_value = 1,
    maximum_value = 64,
    order = "a2"
}})
