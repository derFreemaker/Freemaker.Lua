---@class Freemaker.utils
---@field string Freemaker.utils.string
---@field table Freemaker.utils.table
---@field value Freemaker.utils.value
local utils = {}

utils.string = require("src.utils.string")
utils.table = require("src.utils.table")
utils.value = require("src.utils.value")

return utils
