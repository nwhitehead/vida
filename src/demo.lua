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

print(fast.func(3, 5)) -- should print 8
