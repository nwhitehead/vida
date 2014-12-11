# Vida

Vida is a Lua module that allows you to include C code and call it
right from your Lua code. 

## REQUIREMENTS

* LuaJit 2.0+

* Clang must be installed and working from the command line

## HOW TO USE

You include the vida module as normal. Call vida.source to provide
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
