# Vida

Vida is a Lua module that allows you to include C code and call it
right from your Lua code. 

## Requirements

* Linux or Mac OS X
* LuaJIT 2.0+
* A working copy of clang or gcc available from the command line

## How to use

You include the Vida module as normal. Call `vida.source` to provide
C code together with a C interface that will be passed along to
FFI. The return value will be the FFI namespace of the loaded dynamic
library.

Example:

```lua
local vida = require('vida')

local fast = vida.source([[
    // C interface
    int func(int a, int b);
]],
[[
    // C implementation
    int func(int a, int b) {
        return a + b;
    }
]])

print(fast.func(3, 5)) -- should print out 8
```

## How it works

Each call to `vida.source` builds a new shared library using clang
(or other compiler) called from the command line with appropriate arguments.
The shared library is named using an MD5 hash of the C source code,
opened for immediate use, then saved in a cache directory and reused in
later runs.

## Advantages

There are several reasons to use Vida. 

* Performance of simple C functions is often 3x to 10x faster than LuaJIT
compiled Lua code.
* No complicated OS-specific build steps needed, everything is in Lua files.
* No new language to learn (compare to Terra).
* No changes to LuaJIT interpreter required.
* Easy binary distribution of cached libraries, users don't need compiler.
* [Future work] Allows precompiles during build to support targets
such as Android without compilers in runtime environment.

## Setup

### Linux

Install LuaJIT, available from http://luajit.org.

Make sure that clang is available from the command line. On Debian-based
distributions such as Ubuntu this is accomplished by installing the ``clang``
package. Any version of Clang should be compatible with Vida.

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

## Binary Distribution (Mac OS X and Windows)

For convenient application distribution to users on Mac OS X and Windows platforms
it is recommended to include precompiled shared libraries for the platform
in the default `.vidacache` directory and turn off dynamic compilation
with `vida.compiler = nil` before any calls to `vida.source`. This
forces Vida to use provided shared libraries or throw an error if there
is a problem loading them. Note that in this scenario you will also
likely be providing a precompiled binary version of `luajit` or
`luajit.exe` as well.
