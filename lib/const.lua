local const = {}

const.gui = {
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

return const
