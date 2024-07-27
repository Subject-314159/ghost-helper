local const = require("lib.const")

local timer = {}

----- Time measurement util -----

local get_ptr = function(component)

    -- Get/initialize the component
    if not global.timer then
        global.timer = {}
    end
    if not global.timer[component] then
        global.timer[component] = {}
    end
    local comp = global.timer[component]

    if not comp.ticks then
        comp.ticks = {}
    end
    if not comp.summary then
        comp.summary = {}
    end
    return comp
end

timer.end_measurement = function(component)
    -- Get the pointer
    local comp = get_ptr(component)

    -- Stop the current timer if there is any
    if comp.ticks[1] then
        comp.ticks[1].stop()
    end
end

timer.start_measurement = function(component)
    -- End any previous measurement if any
    timer.end_measurement(component)

    -- Get the pointer
    local comp = get_ptr(component)

    -- Bitshit each consecutive component
    for i = const.settings.measurement.AVERAGE_COUNT - 1, 1, -1 do
        if comp.ticks[i - 1] and comp.ticks[i - 1].valid then
            comp.ticks[i] = comp.ticks[i - 1]
        end
    end

    -- Start a new profiler on the first index
    comp.ticks[1] = game.create_profiler()

end

timer.get_measurement_results = function(component)
    -- Get the pointer
    local comp = get_ptr(component)

    -- Create a new stopped profiler for summary
    comp.summary = game.create_profiler(true)

    -- Add the individual times of each measurement to our summary profiler
    local valid = 0
    for i = 2, const.settings.measurement.AVERAGE_COUNT, 1 do
        if comp.ticks[i] and comp.ticks[i].valid then
            comp.summary.add(comp.ticks[i])
            valid = valid + 1
        end
    end
    if valid > 0 and comp.summary and comp.summary.valid then
        comp.summary.divide(valid)
        return comp.summary
    else
        return ("No measurement")
    end
end

return timer
