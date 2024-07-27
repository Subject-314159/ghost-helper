local const = {}

const.gui = {
    outer = {
        FRAME = "gh_outer"
    },
    main = {
        FRAME = "gh_main-frame",
        CAPTION = "gh-gui.main-frame",
        surface = {
            PREFIX = "surface_",
            label = {
                PREFIX = "srf-lbl-"
            },
            ghost_frame = {
                PREFIX = "gf-",
                table = {
                    NAME = "gt"
                }
            }
        }
    },
    settings = {
        FRAME = "gh_settings-frame",
        CAPTION = "gh-gui.settings-frame"
    }
}

const.types = {
    GHOST_ENTITY = {"entity-ghost"},
    GHOST = {"accumulator", "artillery-turret", "beacon", "boiler", "burner-generator", "arithmetic-combinator",
             "decider-combinator", "constant-combinator", "container", "logistic-container", "infinity-container",
             "assembling-machine", "rocket-silo", "furnace", "electric-energy-interface", "electric-pole",
             "combat-robot", "construction-robot", "logistic-robot", "gate", "generator", "heat-interface", "heat-pipe",
             "inserter", "lab", "lamp", "land-mine", "linked-container", "market", "mining-drill", "offshore-pump",
             "pipe", "infinity-pipe", "pipe-to-ground", "power-switch", "programmable-speaker", "pump", "radar",
             "curved-rail", "straight-rail", "rail-chain-signal", "rail-signal", "reactor", "roboport",
             "simple-entity-with-owner", "simple-entity-with-force", "solar-panel", "storage-tank", "train-stop",
             "linked-belt", "loader-1x1", "loader", "splitter", "transport-belt", "underground-belt", "turret",
             "ammo-turret", "electric-turret", "fluid-turret", "car", "artillery-wagon", "cargo-wagon", "fluid-wagon",
             "locomotive", "spider-vehicle", "wall", "fish", "simple-entity"},
    INVENTORY = {"container", "logistic-container", "infinity-container", "linked-container"}
}

const.settings = {
    map = {
        PROGRESS_BAR_TICKS = {
            ["never"] = 9999999999,
            ["1 sec"] = 1 * 60,
            ["5 sec"] = 5 * 60,
            ["10 sec"] = 10 * 60,
            ["30 sec"] = 50 * 60,
            ["always"] = 0
        }
    },
    measurement = {
        AVERAGE_COUNT = 30,
        component = {
            SURFACE = "surface",
            INDEX = "index",
            SEARCH = "search",
            ANNOTATE = "ghost-finder-annotate"
        }
    },
    tick_actions = {
        index = {
            MIN = 1,
            DEFAULT = 200,
            MAX = 500
        },
        search = {
            MIN = 1,
            DEFAULT = 500,
            MAX = 1000
        },
        annotate = {
            MIN = 1,
            DEFAULT = 100,
            MAX = 400
        }
    }
}

return const
