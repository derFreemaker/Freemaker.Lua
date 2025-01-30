local _number = require("src.utils.number")

---@class Freemaker.utils.stopwatch
---@field private running boolean
---
---@field start_time number
---@field end_time number
---@field private elapesd_milliseconds integer
---
---@field private laps integer[]
---@field private laps_count integer
local _stopwatch = {}

---@return Freemaker.utils.stopwatch
function _stopwatch.new()
    return setmetatable({
        running = false,

        start_time = 0,
        end_time = 0,
        elapesd_milliseconds = 0,

        laps = {},
        laps_count = 0,
    }, { __index = _stopwatch })
end

---@return Freemaker.utils.stopwatch
function _stopwatch.start_new()
    local instance = _stopwatch.new()
    instance:start()
    return instance
end

function _stopwatch:start()
    if self.running then
        return
    end

    self.start_time = os.clock()
    self.running = true
end

function _stopwatch:stop()
    if not self.running then
        return
    end

    self.end_time = os.clock()
    local elapesd_time = self.end_time - self.start_time
    self.running = false

    self.elapesd_milliseconds = _number.round(elapesd_time * 1000)
end

---@return integer
function _stopwatch:get_elapesd_seconds()
    return _number.round(self.elapesd_milliseconds / 1000)
end

---@return integer
function _stopwatch:get_elapesd_milliseconds()
    return self.elapesd_milliseconds
end

---@return integer elapesd_milliseconds
function _stopwatch:lap()
    if not self.running then
        return 0
    end

    local lap_time = os.clock()
    local previous_lap = self.laps[self.laps_count] or self.start_time

    self.laps_count = self.laps_count + 1
    self.laps[self.laps_count] = previous_lap

    local elapesd_time = lap_time - previous_lap

    return _number.round(elapesd_time * 1000)
end

---@return integer elapesd_milliseconds
function _stopwatch:avg_lap()
    if not self.running then
        return 0
    end

    self:lap()

    local sum = 0
    for _, lap_time in ipairs(self.laps) do
        sum = sum + lap_time
    end

    return sum / #self.laps
end

return _stopwatch
