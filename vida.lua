local os = require('os')
local ffi = require('ffi')

local vida = {}

function vida.source(name, interface, implementation)
    local fname = os.tmpname() .. name
    local cname = fname .. ".c"
    local oname = fname .. ".o"
    local libname = fname .. ".so"
    local file = io.open(cname, 'w')
    file:write(interface)
    file:write(implementation)
    file:close()
    os.execute(string.format('clang -fpic -c %s -o %s', cname, oname))
    os.execute(string.format('clang -shared %s -o %s', oname, libname))
    ffi.cdef(interface)
    return ffi.load(libname)
end


return vida
