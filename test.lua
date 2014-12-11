local inspect = require('inspect')
local vida = require('vida')

local fast = vida.source('test', [[
// C interface
int testConstant;
int theFunction(int a, int b);
]],
[[
// C implementation
int testConstant = 101;
int theFunction(int a, int b) {
    return a + b;
}
]])

print(inspect(fast))

print(fast.testConstant)

local x = 3
local y = 5
local z = fast.theFunction(x, y)
print(x, y, z)
