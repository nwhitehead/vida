local os = require('os')
local ffi = require('ffi')

local vida = {}

-- From lhf
-- http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

vida.useLocalCopy = true
vida.saveLocalCopy = true
vida.cachePath = 'cache'

function vida.source(interface, implementation)
    name = 'test'
    -- First interpret interface using FFI
    ffi.cdef(interface)
    -- Check for local copy of shared library
    local locallib = name .. ".so"
    if vida.useLocalCopy then
        if file_exists(locallib) then
            return ffi.load("./" .. locallib)
        end
    end
    -- Create names
    local fname = os.tmpname() .. name
    local cname = fname .. ".c"
    local oname = fname .. ".o"
    local libname = fname .. ".so"
    -- Write C contents
    -- Note: includes interface to avoid inconsistencies
    local file = io.open(cname, 'w')
    file:write(interface)
    file:write(implementation)
    file:close()
    -- Compile
    local r
    r = os.execute(string.format('clang -fpic -c %s -o %s', cname, oname))
    if r ~= 0 then error('Error during compile', 2) end
    -- Link to shared library
    r = os.execute(string.format('clang -shared %s -o %s', oname, libname))
    if r ~= 0 then error('Error during link', 2) end
    -- Save a local copy
    if vida.saveLocalCopy then
        r = os.execute(string.format('cp %s %s', libname, locallib))
        if r ~= 0 then error('Error saving local copy', 2) end
    end
    -- Load the shared library
    return ffi.load(libname)
end


return vida
