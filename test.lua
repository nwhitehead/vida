local inspect = require('inspect')
local vida = require('vida')

vida.source([[
int testConstant;
int theFunction(int a, int b);
]],[[
int testConstant = 101;
int theFunction(int a, int b) {
    return a + b;
}
]])

print(inspect(vida.sources))
