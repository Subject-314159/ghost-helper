local util = {}

util.arr_cnt = function(arr)
    if not arr then
        return 0
    end
    local cnt = 0
    for _ in pairs(arr) do
        cnt = cnt + 1
    end
    return cnt
end

util.silent = function(message)
    game.print(message, {
        sound = defines.print_sound.never
    })
end
return util
