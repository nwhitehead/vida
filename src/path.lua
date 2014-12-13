-- simple path manipulation module
local ffi = require('ffi')

local path = {}

local sep = '/'
if ffi.os == 'Windows' then
    sep = '\\'
end

function path.join(...)
    local arg = {...}
    return table.concat(arg, sep)
end

return path
