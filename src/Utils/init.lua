---@class Freemaker.utils
---@field string Freemaker.utils.string
---@field table Freemaker.utils.table
---@field array Freemaker.utils.array
---@field value Freemaker.utils.value
local utils = {}

utils.string = require("src.utils.string")
utils.table = require("src.utils.table")
utils.array = require("src.utils.array")
utils.value = require("src.utils.value")

return utils
