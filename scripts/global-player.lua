local global_player = {}

local init_player = function(player)
    if not global.players[player.index] then
        global.players[player.index] = {}
    end

end

global_player.get = function(player)
    init_player(player)
    return global.players[player.index]
end

global_player.init = function()
    if not global.players then
        global.players = {}
    end
end

return global_player
