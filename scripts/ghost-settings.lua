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
    for i, srf in pairs(global.data.surfaces) do
        for _, gt in pairs(srf.ghost_types) do
            num_ghosts = num_ghosts + #gt.ghosts
        end
        if srf.storages then
            num_chests = num_chests + #srf.storages
        end
    end

    -- Print stats
    player.print("Avg # ticks for full scan: " .. global.track.avg_num_ticks_per_cycle)
    player.print("# ghosts total: " .. num_ghosts)
    player.print("# chests total: " .. num_chests)
    player.print("Total # scan actions for full scan: " .. num_ghosts * num_chests)
    player.print("# scan actions per tick: " .. settings.global["scan-actions-per-tick"].value .. " (mod setting)")

end

function ghost_settings.init()

    -- Add debug commands
    commands.add_command("gh_stats", "Resets the konami state for the given player", function(command)
        ghost_settings.print_stats(command.player_index)
    end)
end
return ghost_settings
