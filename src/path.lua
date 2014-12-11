-- simple path manipulation module

local path = {}

function path.join(...)
    local arg = {...}
    return table.concat(arg, '/')
end

return path
