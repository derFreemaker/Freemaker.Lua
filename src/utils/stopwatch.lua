---@class Freemaker.utils.stopwatch
---@field start_time number | nil
---@field last_lap_time number | nil
local _stopwatch = {}

function _stopwatch.new()
    return setmetatable({
    }, { __index = _stopwatch })
end

function _stopwatch.start_new()
    local instance = _stopwatch.new()
    instance:start()
    return instance
end

function _stopwatch:start()
    if self.start_time then
        return
    end

    self.start_time = os.clock()
end

---@return number elapesd_milliseconds
function _stopwatch:stop()
    if not self.start_time then
        return 0
    end

    local elapesd_time = os.clock() - self.start_time
    self.start_time = nil

    return elapesd_time * 1000
end

---@return number elapesd_milliseconds
function _stopwatch:lap()
    if not self.start_time then
        return 0
    end

    local lap_time = os.clock()
    self.last_lap_time = lap_time

    local previous_lap = self.last_lap_time or self.start_time
    local elapesd_time = lap_time - previous_lap

    return elapesd_time * 1000
end

return _stopwatch
