local os = require('os')
local ffi = require('ffi')
local md5 = require('md5')
local path = require('path')
local temp = require('temp')

local vida = {}

-- From lhf
-- http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

vida.useLocalCopy = true
vida.saveLocalCopy = true
vida.cachePath = '.vidacache'
vida.compiler = 'clang'
vida.compilerFlags = '-O3 -fpic -c'
vida.linkerFlags = '-shared'
if ffi.os == 'Windows' then
    vida.compiler = 'cl'
    vida.compilerFlags = '/nologo /O2 /c'
    vida.linkerFlags = '/nologo /link /DLL'
end

-- Use .so suffix on Linux and Mac, .dll on Windows
-- Use .o suffix on Linux and Mac, .obj on Windows
local libsuffix = '.so'
local objsuffix = '.o'
if ffi.os == 'Windows' then
    libsuffix = '.dll'
    objsuffix = '.obj'
end

-- Fixed header for C source to simplify exports
vida.header = [[
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif
]]

function vida.source(interface, implementation)
    -- First interpret interface using FFI
    ffi.cdef(interface)
    local src = vida.header .. implementation
    local name = md5.hash(src)
    -- Check for local copy of shared library
    local locallib = path.join(vida.cachePath, ffi.os .. '-' .. name .. libsuffix)
    if vida.useLocalCopy then
        if file_exists(locallib) then
            return ffi.load(locallib)
        end
    end
    -- If we don't have a compiler, bail out now
    if not vida.compiler then
        error('Error loading shared library, compiler disabled', 2)
    end
    -- Create names
    local fname = temp.name() .. name
    local cname = fname .. '.c'
    local oname = fname .. objsuffix
    local libname = fname .. libsuffix
    local localcname = path.join(vida.cachePath, name .. '.c')
    -- Write C source contents to .c file
    local file = io.open(cname, 'w')
    if not file then
        error(string.format('Error writing source file %s', cname), 2)
    end
    file:write(src)
    file:close()
    -- Compile
    local r
    if ffi.os == 'Windows' then
        r = os.execute(string.format('%s %s %s /Fo%s >nul', vida.compiler, vida.compilerFlags, cname, oname))
        if r ~= 0 then error('Error during compile', 2) end
        r = os.execute(string.format('%s %s %s /OUT:%s >nul', vida.compiler, oname, vida.linkerFlags, libname))
        if r ~= 0 then error('Error during link', 2) end
        -- Save a local copy of library and source
        if vida.saveLocalCopy then
            os.execute(string.format('mkdir %s >nul 2>nul', vida.cachePath))
            -- Ignore errors, likely already exists
            r = os.execute(string.format('copy %s %s >nul', libname, locallib))
            if r ~= 0 then error('Error saving local copy', 2) end
            r = os.execute(string.format('copy %s %s >nul', cname, localcname))
            if r ~= 0 then error('Error saving local copy2', 2) end
        end
    else
        r = os.execute(string.format('%s %s %s -o %s', vida.compiler, vida.compilerFlags, cname, oname))
        if r ~= 0 then error('Error during compile', 2) end
        -- Link into shared library
        r = os.execute(string.format('%s %s %s -o %s', vida.compiler, vida.linkerFlags, oname, libname))
        if r ~= 0 then error('Error during link', 2) end
        -- Save a local copy of library and source
        if vida.saveLocalCopy then
            r = os.execute(string.format('mkdir -p %s', vida.cachePath))
            if r ~= 0 then error('Error creating cache path', 2) end
            r = os.execute(string.format('cp %s %s', libname, locallib))
            if r ~= 0 then error('Error saving local copy', 2) end
            r = os.execute(string.format('cp %s %s', cname, localcname))
            if r ~= 0 then error('Error saving local copy', 2) end
        end
    end
    -- Load the shared library
    return ffi.load(libname)
end


return vida
