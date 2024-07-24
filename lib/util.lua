local util = {}

util.arr_cnt = function(arr)
    local cnt = 0
    for _ in pairs(arr) do
        cnt = cnt + 1
    end
    return cnt
end

return util
