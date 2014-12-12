# Vida

Vida is a Lua module that allows you to include C code and call it
right from your Lua code. 

## Requirements

* Linux only (for now)
* LuaJit 2.0+
* A working copy of clang or gcc available from the command line

## How to use

You include the vida module as normal. Call `vida.source` to provide
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
or gcc called from the command line with appropriate arguments.
The shared library is named using an MD5 hash of the C source code,
opened for immediate use, then saved in a cache directory and reused in
later runs.

## Advantages

There are several reasons to use vida. 

* No complicated build steps needed, everything is in Lua files.
* Performance of simple C functions often 6x faster than LuaJIT
compiled Lua code.
* No new language to learn (compare to Terra).
* No changes to LuaJIT interpreter required.
