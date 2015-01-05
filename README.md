# Vida

Vida is a Lua module that allows you to include C code and call it
right from your Lua code. 

## Requirements

* Works in Windows, Mac OS X, or Linux
* LuaJIT 2.0+
* A working copy of Visual Studio (Windows),
clang or gcc (Mac OS X and Linux), available from the command line

## How to use

You include the Vida module as normal. Call `vida.compile` to provide
C code together with a C interface that will be passed along to
FFI. The return value will be the FFI namespace of the loaded dynamic
library.

Example:

```lua
local vida = require('vida')

local fast = vida.compile(
    vida.interface [[
        // C interface
        int func(int, int);
    ]],
    vida.code [[
        // C implementation
        EXPORT int func(int a, int b) {
            return a + b;
        }
    ]])

print(fast.func(3, 5)) -- prints out 8
```

## Getting it

Vida is a single Lua source file `vida.lua` (available in the `output`
directory in the repository) that you can copy to `/usr/local/share/lua/5.1`
or wherever else you keep your Lua modules.

You can also install vida using luarocks:
```
sudo luarocks install vida
```
Vida requires LuaJIT which is based on Lua 5.1. Your installation
of LuaRocks may default to only installing modules for Lua 5.2.
You may want to install two versions of LuaRocks, one for Lua 5.1 and
another for Lua 5.2 (see [these instructions](http://stackoverflow.com/questions/20321560/how-do-install-libraries-for-both-lua5-2-and-5-1-using-luarocks)).

## How it works

Each call to `vida.compile` builds a new shared library using clang
(or other compiler) called from the command line with appropriate arguments.
The shared library is named using an MD5 hash of the C source code,
opened for immediate use, then saved in a cache directory and reused in
later runs.

Functions in the implementation that will be called from LuaJIT need to
be marked `EXPORT` so that the symbol is made public. Functions
and symbols not marked with `EXPORT` are private.

## Advantages

There are several reasons to use Vida. 

* Performance of simple C functions is often 3x to 10x faster than LuaJIT
compiled Lua code.
* No complicated OS-specific build steps needed, everything is in Lua files.
* No new language to learn (compare to Terra).
* No changes to LuaJIT interpreter required.
* Easy binary distribution of cached libraries, users don't need a compiler.
* [Future work] Allows precompiles during build to support targets
such as Android without compilers in the runtime environment.

## Setup

### Windows

Install LuaJIT, available from http://luajit.org.

Make sure that `cl`, the command line version of the Visual Studio compiler,
is available from your command prompt. One way to do this is to run the
Developer Command Prompt for Visual Studio, which has environmental
variables set properly. From this prompt run `luajit` on your lua source
file.

### Mac OS X

Install LuaJIT, available from http://luajit.org.

Make sure that clang is available from the command line. If you already
have XCode installed then this is already true. If not, install the Command Line
Tools. For OS X version 10.9 and newer, type the following line in Terminal
to install the Command Line Tools: `xcode-select --install`

For versions of Mac OS X prior to 10.9 you will need to sign up for a
free Apple Developer account. Once you have an account, you should be
able to download and install the Command Line Tools for XCode at
https://developer.apple.com/downloads/index.action

### Linux

Install LuaJIT, available from http://luajit.org.

Make sure that clang is available from the command line. On Debian-based
distributions such as Ubuntu this is accomplished by installing the ``clang``
package. Any version of Clang should be compatible with Vida.

## Binary Distribution (Windows and Mac OS X)

For convenient application distribution to users on Windows and Mac OS X platforms
it is recommended to include precompiled shared libraries for the platform
in a `.vidacache` directory and turn off dynamic compilation
with `vida.compiler = nil` before any calls to `vida.compile`. This
forces Vida to use provided shared libraries or throw an error if there
is a problem loading them. Note that in this scenario you will also
likely be providing a precompiled binary version of `luajit` or
`luajit.exe` as well.

## Single File Module

There is a small build step to provide the `vida` module in a single
file. Do `make` to create the single-file module in `output/`.
