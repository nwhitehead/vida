-- Requires LuaJIT

if type(jit) ~= 'table' then
    error('This modules requires LuaJIT')
end

local os = require('os')
local ffi = require('ffi')

local md5 = require('md5')
local path = require('path')
local temp = require('temp')

local vida = {}

-- Optionally update value
local function update(old, new)
    if new ~= nil then return new else return old end
end

-- Parse bool, no error on nil
local function toboolean(val)
    if val == nil then return nil end
    return val == 'true' or val == 'True' or val == 'TRUE'
end

-- Update value with environmental variable value
local function update_env(old, name)
    return update(old, os.getenv(name))
end

vida.version = "v0.1.2"
vida.useLocalCopy = update_env(true, 'VIDA_READ_CACHE')
vida.saveLocalCopy = update_env(true, 'VIDA_WRITE_CACHE')
local home_vidacache = '.vidacache'
local home = os.getenv('HOME')
local libsuffix
local objsuffix
if ffi.os == 'Linux' or ffi.os == 'OSX' then
    vida.compiler = update_env('clang', 'VIDA_COMPILER')
    vida.compilerFlags = update_env('-fpic -O3 -c', 'VIDA_COMPILER_FLAGS')
    vida.linkerFlags = update_env('-shared', 'VIDA_LINKER_FLAGS')
    libsuffix = '.so'
    objsuffix = '.o'
    if home then
        home_vidacache = string.format('%s/.vidacache', home)
    end
elseif ffi.os == 'Windows' then
    vida.compiler = update_env('cl', 'VIDA_COMPILER')
    vida.compilerFlags = update_env('/nologo /O2 /c', 'VIDA_COMPILER_FLAGS')
    vida.linkerFlags = update_env('/nologo /link /DLL', 'VIDA_LINKER_FLAGS')
    libsuffix = '.dll'
    objsuffix = '.obj'
else
    error('Unknown platform')
end
vida.cachePath = update_env(home_vidacache, 'VIDA_CACHE_PATH')
vida._prelude = update_env('', 'VIDA_PRELUDE')

-- Fixed header for C source to simplify exports
vida._header = [[
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif
]]

-- Use .so suffix on Linux and Mac, .dll on Windows
-- Use .o suffix on Linux and Mac, .obj on Windows
if ffi.os == 'Windows' then
end

-- Read in a file
function read_file(name)
    local f = io.open(name, 'r')
    if f == nil then
        return nil
    end
    local txt = f:read('*a')
    f:close()
    return txt
end

-- Check if file exists
function file_exists(name)
    local f = io.open(name, 'r')
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

-- Add new code to common C prelude
function vida.prelude(interface, implementation)
    ffi.cdef(interface) -- common to all shared libraries
    vida._prelude = vida._prelude .. implementation
end

-- Compile C code from files, return FFI namespace
function vida.sourceFiles(f_interface, f_implementation)
    local interface = read_file(f_interface)
    if not interface then
        error('Could not open file ' .. f_interface .. ' for reading', 2)
    end
    local implementation = read_file(f_implementation)
    if not implementation then
        error('Could not open file ' .. f_implementation .. ' for reading', 2)
    end
    return vida.source(interface, implementation)
end

-- Compile C code from strings, return FFI namespace
function vida.source(interface, implementation)
    -- First interpret interface using FFI
    ffi.cdef(interface)
    local src = vida._header .. vida._prelude .. implementation
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
