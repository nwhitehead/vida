-- Combine multiple lua files into one

-- Usage:
--   lua combiner.lua [MODULES...] MAIN > OUTPUT
--
-- Result is a single Lua file with embedded modules
--
-- Example:
--   lua combiner.lua src/module.lua src/md5.lua main.lua > output.lua
--
-- Requires new module style definitions for all modules
-- (Module returns table of exports)
--
-- In main.lua, file blah/md5.lua can be imported with:
-- local mymd5 = require('md5')
-- If main.lua is a module, submodules are not visible to importers.

-- Inspired by:
-- https://github.com/yi/node-lua-distiller/blob/master/bin/distill_head.lua

local combinerHead = [[
if __COMBINER == nil then
    __COMBINER = {
        MODULE = {},
        __nativeRequire = require,
        require = function(id)
            assert(type(id) == 'string', 'invalid require id:' .. tostring(id))
            if package.loaded[id] then
                return package.loaded[id]
            end
            if __COMBINER.MODULE[id] then
                local f = __COMBINER.MODULE[id]
                package.loaded[id] = f(__COMBINER.require) or true
                return package.loaded[id]
            end
            return __COMBINER.__nativeRequire(id)
        end,
        define = function(id, f)
            assert(type(id) == 'string', 'invalid define id:' .. tostring(id))
            if package.loaded[id] == nil and __COMBINER.MODULE[id] == nil then
                __COMBINER.MODULE[id] = f
            else
                print('__COMBINER module ' .. tostring(id) .. ' already defined')
            end
        end,
    }
end
]]


-- Main function
function main(files)
    local output = combinerHead
    for i = 1, #files - 1 do
        local filename = files[i]
        output = output .. process(filename)
    end
    local mainfile = files[#files]
    output = output .. process_main(mainfile)
    print(output)
end

-- Strip out .lua suffix (or any . suffix)
function string_rstrip_dot(str)
    local i, j = string.find(str, '%.')
    if i then
        return string.sub(str, 1, i - 1)
    end
    return str
end

-- Get last part of filename (ignore path)
function string_lastpart(str)
    local i, j = string.find(str, '/')
    while i do
        str = string.sub(str, i + 1, -1)
        i, j = string.find(str, '/')
    end
    local i, j = string.find(str, '\\')
    while i do
        str = string.sub(str, i + 1, -1)
        i, j = string.find(str, '\\')
    end
    return str
end

-- Compute modulename from filename
function modulename(filename)
    return string_rstrip_dot(string_lastpart(filename))
end

-- Read entire text file
function readfile(filename)
    local f = io.open(filename, 'r')
    local txt = f:read('*a') -- read entire contents
    f:close()
    return txt
end

-- Process a single module, return source code
function process(filename)
    local mname = modulename(filename)
    local txt = readfile(filename)
    return string.format("__COMBINER.define('%s', (function(require) %s end))\n", mname, txt)
end

-- Process a single main file, return source code
function process_main(filename)
    local txt = readfile(filename)
    return string.format("return (function(require) %s end)(__COMBINER.require)\n", txt)
end


main(arg)
