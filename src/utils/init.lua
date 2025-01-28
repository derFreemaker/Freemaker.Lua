---@class Freemaker.utils
---@field number Freemaker.utils.number
---@field string Freemaker.utils.string
---@field table Freemaker.utils.table
---@field array Freemaker.utils.array
---@field value Freemaker.utils.value
local utils = {}

utils.number = require("src.utils.number")
utils.string = require("src.utils.string.init")
utils.table = require("src.utils.table")
utils.array = require("src.utils.array")
utils.value = require("src.utils.value")

return utils
