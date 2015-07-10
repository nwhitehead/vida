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

vida.version = "v0.1.10"
vida.useLocalCopy = update_env(true, 'VIDA_READ_CACHE')
vida.saveLocalCopy = update_env(true, 'VIDA_WRITE_CACHE')
local home_vidacache = '.vidacache'
local home = os.getenv('HOME')
local libsuffix
local objsuffix
if ffi.os == 'Linux' or ffi.os == 'OSX' then
    vida.compiler = update_env(update_env('clang', 'CC'), 'VIDA_COMPILER')
    vida.compilerFlags = update_env('-fpic -O3 -fvisibility=hidden', 'VIDA_COMPILER_FLAGS')
    vida.justCompile = '-c'
    vida.linkerFlags = update_env('-shared', 'VIDA_LINKER_FLAGS')
    libsuffix = '.so'
    objsuffix = '.o'
    if home then
        home_vidacache = string.format('%s/.vidacache', home)
    end
elseif ffi.os == 'Windows' then
    vida.compiler = update_env('cl', 'VIDA_COMPILER')
    vida.compilerFlags = update_env('/nologo /O2', 'VIDA_COMPILER_FLAGS')
    vida.justCompile = '/c'
    vida.linkerFlags = update_env('/nologo /link /DLL', 'VIDA_LINKER_FLAGS')
    libsuffix = '.dll'
    objsuffix = '.obj'
else
    error('Unknown platform')
end
vida.cachePath = update_env(home_vidacache, 'VIDA_CACHE_PATH')
vida._code_prelude = update_env('', 'VIDA_CODE_PRELUDE')
vida._interface_prelude = update_env('', 'VIDA_INTERFACE_PRELUDE')

-- Fixed header for C source to simplify exports
vida._code_header = [[
#line 0 "vida_header"
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__ ((visibility ("default")))
#endif
]]

vida.cdef = ffi.cdef

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

-- Give C header interface
function vida.interface(txt, info)
    local res = {
        vida = 'interface',
        code = txt,
        filename = 'vida_interface',
        linenum = 1,
    }
    if info == true or info == nil then
        -- Get filename and linenumber of caller
        -- This helps us give good error messages when compiling
        -- Add caller filename and line numbers for debugging
        local caller = debug.getinfo(2)
        res.filename = caller.short_src
        res.linenum = caller.currentline
    end
    return res
end

-- Give C source code
function vida.code(txt)
    local res = {
        vida='code',
        code=txt,
        filename = 'vida_code',
        linenum = 1,
    }
    if info == true or info == nil then
        -- Get filename and linenumber of caller
        -- This helps us give good error messages when compiling
        -- Add caller filename and line numbers for debugging
        local caller = debug.getinfo(2)
        res.filename = caller.short_src
        res.linenum = caller.currentline
    end
    return res
end

-- Give interface file
function vida.interfacefile(filename)
    local interface = read_file(filename)
    if not interface then
        error('Could not open file ' .. filename .. ' for reading', 2)
    end
    return {
        vida='interface',
        code=interface,
        filename = filename,
        linenum = 1,
    }
end

-- Give source code file
function vida.codefile(filename)
    local src = read_file(filename)
    if not src then
        error('Could not open file ' .. filename .. ' for reading', 2)
    end
    return {
        vida='code',
        code=src,
        filename = filename,
        linenum = 1,
    }
end

-- Add code or interface to common prelude
function vida.prelude(...)
    local args = {...}
    -- Put together source string
    local srcs = { vida._code_prelude }
    local ints = { vida._interface_prelude }
    for k, v in ipairs(args) do
        if not type(v) == 'table' then
            error('Argument ' .. k .. ' to prelude not Vida code or interface', 2)
        end
        if v.vida == 'code' then
            srcs[#srcs + 1] = string.format('#line %d "%s"', v.linenum, v.filename)
            srcs[#srcs + 1] = v.code
        elseif v.vida == 'interface' then
            ints[#ints + 1] = v.code
        else
            error('Argument ' .. k .. ' to prelude not Vida code or interface', 2)
        end
    end
    vida._code_prelude = table.concat(srcs, '\n')
    vida._interface_prelude = table.concat(ints, '\n')
end

-- Given chunks of C code and interfaces, return working FFI namespace
function vida.compile(...)
    local args = {...}
    -- Put together source string
    local srcs = { vida._code_header, vida._code_prelude }
    local ints = { vida._interface_prelude }
    for k, v in ipairs(args) do
        if type(v) == 'string' then
            -- Assume code
            local caller = debug.getinfo(2)
            srcs[#srcs + 1] = string.format('#line %d "%s"', caller.currentline, caller.short_src)
            srcs[#srcs + 1] = v
        elseif type(v) ~= 'table' then
            error('Argument ' .. k .. ' to compile not Vida code or interface', 2)
        elseif v.vida == 'code' then
            srcs[#srcs + 1] = string.format('#line %d "%s"', v.linenum, v.filename)
            srcs[#srcs + 1] = v.code
        elseif v.vida == 'interface' then
            ints[#ints + 1] = v.code
        else
            error('Argument ' .. k .. ' to compile not Vida code or interface', 2)
        end
    end
    local src = table.concat(srcs, '\n')
    local interface = table.concat(ints, '\n')
    -- Interpret interface using FFI
    -- (Do this first in case there is an error here)
    if interface ~= '' then
        ffi.cdef(interface)
    end
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
        r = os.execute(string.format('%s %s %s %s /Fo%s >nul', vida.compiler, vida.compilerFlags, vida.justComile, cname, oname))
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
        r = os.execute(string.format('%s %s %s %s -o %s', vida.compiler, vida.compilerFlags, vida.justCompile, cname, oname))
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
