local util = require("lib.util")

local ghost_settings = {}

ghost_settings.print_stats = function(player_index)

    -- Get the player
    local player = game.players[player_index]
    if not player then
        return
    end

    -- Stat counting
    local num_ghosts = 0
    local num_chests = 0
    local num_chunks = 0
    for i, srf in pairs(global.data.surfaces) do
        for itm, gt in pairs(srf.ghost_types) do
            num_ghosts = num_ghosts + util.arr_cnt(gt.ghosts)
        end
        if srf.storage_entities then
            num_chests = num_chests + util.arr_cnt(srf.storage_entities)
        end
        num_chunks = num_chunks + (srf.chunk_count or 0)
    end
    local scan_actions_pt = settings.global["gh_scan-actions-per-tick"].value
    local chunk_index_pt = settings.global["gh_index-chunks-per-tick"].value
    local scan_est = math.ceil((num_ghosts * num_chests) / scan_actions_pt)
    local index_est = math.ceil(num_chunks / chunk_index_pt)

    -- Print stats
    player.print("=== Indexing ===")
    player.print("# chunks total: " .. num_chunks)
    player.print("# chunk indexes per tick: " .. chunk_index_pt .. " (mod setting)")
    player.print("Estimated # ticks for indexing: " .. index_est)

    player.print("=== Scanning ===")
    player.print("# ghosts total: " .. num_ghosts)
    player.print("# chests total: " .. num_chests)
    player.print("Total # scan actions for full scan: " .. num_ghosts * num_chests)
    player.print("# scan actions per tick: " .. scan_actions_pt .. " (mod setting)")
    player.print("Estimated # ticks for scanning: " .. scan_est)

    player.print("=== Total ===")
    player.print("Estimated # ticks for full cycle: " .. index_est + scan_est .. "(" ..
                     (math.ceil((index_est + scan_est) / 6) / 10) .. "s)")
    player.print("Actual avg # ticks for full cycle: " .. global.track.avg_num_ticks_per_cycle .. " (" ..
                     (math.ceil(global.track.avg_num_ticks_per_cycle / 6) / 10) .. "s)")

end

ghost_settings.reset = function(player_index)
    global.scan = {
        surfaces = {},
        inventories = {},
        data = {}
    }
    global.settings = {
        surfaces = {}
    }
    global.data = {}
    global.track = {}
    global.track.history = {}
    for i = 1, 10, 1 do
        global.track.history[i] = 0
    end
    game.print("Ghost Handler has been reset")
end

function ghost_settings.init()

    local comm = commands.commands

    -- Add debug commands
    if not comm["gh_stats"] then
        commands.add_command("gh_stats", "Provides stats about ghosts & inventories in the current game",
            function(command)
                ghost_settings.print_stats(command.player_index)
            end)
    end

    if not comm["gh_reset"] then
        commands.add_command("gh_reset", "Attempts to reset Ghost Handler global storage data", function(command)
            ghost_settings.reset(command.player_index)
        end)
    end
end
return ghost_settings
