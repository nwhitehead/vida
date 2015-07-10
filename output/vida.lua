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
__COMBINER.define('md5', (function(require) -- simple md5 library

-- Copied from bitop library (http://bitop.luajit.org/)
-- Original copyright info:
-- MD5 test and benchmark. Public domain.

local bit = require("bit")

local tobit, tohex, bnot = bit.tobit or bit.cast, bit.tohex, bit.bnot
local bor, band, bxor = bit.bor, bit.band, bit.bxor
local lshift, rshift, rol, bswap = bit.lshift, bit.rshift, bit.rol, bit.bswap
local byte, char, sub, rep = string.byte, string.char, string.sub, string.rep

local function tr_f(a, b, c, d, x, s)
    return rol(bxor(d, band(b, bxor(c, d))) + a + x, s) + b
end

local function tr_g(a, b, c, d, x, s)
    return rol(bxor(c, band(d, bxor(b, c))) + a + x, s) + b
end

local function tr_h(a, b, c, d, x, s)
    return rol(bxor(b, c, d) + a + x, s) + b
end

local function tr_i(a, b, c, d, x, s)
    return rol(bxor(c, bor(b, bnot(d))) + a + x, s) + b
end

local function transform(x, a1, b1, c1, d1)
    local a, b, c, d = a1, b1, c1, d1

    a = tr_f(a, b, c, d, x[ 1] + 0xd76aa478,  7)
    d = tr_f(d, a, b, c, x[ 2] + 0xe8c7b756, 12)
    c = tr_f(c, d, a, b, x[ 3] + 0x242070db, 17)
    b = tr_f(b, c, d, a, x[ 4] + 0xc1bdceee, 22)
    a = tr_f(a, b, c, d, x[ 5] + 0xf57c0faf,  7)
    d = tr_f(d, a, b, c, x[ 6] + 0x4787c62a, 12)
    c = tr_f(c, d, a, b, x[ 7] + 0xa8304613, 17)
    b = tr_f(b, c, d, a, x[ 8] + 0xfd469501, 22)
    a = tr_f(a, b, c, d, x[ 9] + 0x698098d8,  7)
    d = tr_f(d, a, b, c, x[10] + 0x8b44f7af, 12)
    c = tr_f(c, d, a, b, x[11] + 0xffff5bb1, 17)
    b = tr_f(b, c, d, a, x[12] + 0x895cd7be, 22)
    a = tr_f(a, b, c, d, x[13] + 0x6b901122,  7)
    d = tr_f(d, a, b, c, x[14] + 0xfd987193, 12)
    c = tr_f(c, d, a, b, x[15] + 0xa679438e, 17)
    b = tr_f(b, c, d, a, x[16] + 0x49b40821, 22)

    a = tr_g(a, b, c, d, x[ 2] + 0xf61e2562,  5)
    d = tr_g(d, a, b, c, x[ 7] + 0xc040b340,  9)
    c = tr_g(c, d, a, b, x[12] + 0x265e5a51, 14)
    b = tr_g(b, c, d, a, x[ 1] + 0xe9b6c7aa, 20)
    a = tr_g(a, b, c, d, x[ 6] + 0xd62f105d,  5)
    d = tr_g(d, a, b, c, x[11] + 0x02441453,  9)
    c = tr_g(c, d, a, b, x[16] + 0xd8a1e681, 14)
    b = tr_g(b, c, d, a, x[ 5] + 0xe7d3fbc8, 20)
    a = tr_g(a, b, c, d, x[10] + 0x21e1cde6,  5)
    d = tr_g(d, a, b, c, x[15] + 0xc33707d6,  9)
    c = tr_g(c, d, a, b, x[ 4] + 0xf4d50d87, 14)
    b = tr_g(b, c, d, a, x[ 9] + 0x455a14ed, 20)
    a = tr_g(a, b, c, d, x[14] + 0xa9e3e905,  5)
    d = tr_g(d, a, b, c, x[ 3] + 0xfcefa3f8,  9)
    c = tr_g(c, d, a, b, x[ 8] + 0x676f02d9, 14)
    b = tr_g(b, c, d, a, x[13] + 0x8d2a4c8a, 20)

    a = tr_h(a, b, c, d, x[ 6] + 0xfffa3942,  4)
    d = tr_h(d, a, b, c, x[ 9] + 0x8771f681, 11)
    c = tr_h(c, d, a, b, x[12] + 0x6d9d6122, 16)
    b = tr_h(b, c, d, a, x[15] + 0xfde5380c, 23)
    a = tr_h(a, b, c, d, x[ 2] + 0xa4beea44,  4)
    d = tr_h(d, a, b, c, x[ 5] + 0x4bdecfa9, 11)
    c = tr_h(c, d, a, b, x[ 8] + 0xf6bb4b60, 16)
    b = tr_h(b, c, d, a, x[11] + 0xbebfbc70, 23)
    a = tr_h(a, b, c, d, x[14] + 0x289b7ec6,  4)
    d = tr_h(d, a, b, c, x[ 1] + 0xeaa127fa, 11)
    c = tr_h(c, d, a, b, x[ 4] + 0xd4ef3085, 16)
    b = tr_h(b, c, d, a, x[ 7] + 0x04881d05, 23)
    a = tr_h(a, b, c, d, x[10] + 0xd9d4d039,  4)
    d = tr_h(d, a, b, c, x[13] + 0xe6db99e5, 11)
    c = tr_h(c, d, a, b, x[16] + 0x1fa27cf8, 16)
    b = tr_h(b, c, d, a, x[ 3] + 0xc4ac5665, 23)

    a = tr_i(a, b, c, d, x[ 1] + 0xf4292244,  6)
    d = tr_i(d, a, b, c, x[ 8] + 0x432aff97, 10)
    c = tr_i(c, d, a, b, x[15] + 0xab9423a7, 15)
    b = tr_i(b, c, d, a, x[ 6] + 0xfc93a039, 21)
    a = tr_i(a, b, c, d, x[13] + 0x655b59c3,  6)
    d = tr_i(d, a, b, c, x[ 4] + 0x8f0ccc92, 10)
    c = tr_i(c, d, a, b, x[11] + 0xffeff47d, 15)
    b = tr_i(b, c, d, a, x[ 2] + 0x85845dd1, 21)
    a = tr_i(a, b, c, d, x[ 9] + 0x6fa87e4f,  6)
    d = tr_i(d, a, b, c, x[16] + 0xfe2ce6e0, 10)
    c = tr_i(c, d, a, b, x[ 7] + 0xa3014314, 15)
    b = tr_i(b, c, d, a, x[14] + 0x4e0811a1, 21)
    a = tr_i(a, b, c, d, x[ 5] + 0xf7537e82,  6)
    d = tr_i(d, a, b, c, x[12] + 0xbd3af235, 10)
    c = tr_i(c, d, a, b, x[ 3] + 0x2ad7d2bb, 15)
    b = tr_i(b, c, d, a, x[10] + 0xeb86d391, 21)

    return tobit(a+a1), tobit(b+b1), tobit(c+c1), tobit(d+d1)
end

-- Note: this is copying the original string and NOT particularly fast.
-- A library for struct unpacking would make this task much easier.
local function md5hash(msg)
    local len = #msg
    msg = msg.."\128"..rep("\0", 63 - band(len + 8, 63))
         ..char(band(lshift(len, 3), 255), band(rshift(len, 5), 255),
            band(rshift(len, 13), 255), band(rshift(len, 21), 255))
         .."\0\0\0\0"
    local a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    local x, k = {}, 1
    for i=1,#msg,4 do
        local m0, m1, m2, m3 = byte(msg, i, i+3)
        x[k] = bor(m0, lshift(m1, 8), lshift(m2, 16), lshift(m3, 24))
        if k == 16 then
            a, b, c, d = transform(x, a, b, c, d)
            k = 1
        else
            k = k + 1
        end
    end
    return tohex(bswap(a))..tohex(bswap(b))..tohex(bswap(c))..tohex(bswap(d))
end

return { hash=md5hash }
 end))
__COMBINER.define('path', (function(require) -- simple path manipulation module
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
 end))
__COMBINER.define('temp', (function(require) local ffi = require('ffi')

local temp = {}

function temp.name()
    if ffi.os == 'Windows' then
        return os.getenv('TEMP') .. os.tmpname()
    end
    return os.tmpname()
end

return temp
 end))
return (function(require) -- Requires LuaJIT

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

vida.version = "v0.1.9"
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
 end)(__COMBINER.require)

