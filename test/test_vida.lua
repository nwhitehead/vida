local vida = require('vida')

function test(txt, func)
    io.write(txt, ' : ')
    local status, err = pcall(func)
    if status then
        io.write('PASS\n')
    else
        io.write('FAIL\n')
        error(err, 2)
    end
end

print('Testing Vida ' .. vida.version)

test('call prelude', function()
    vida.prelude([[
        typedef unsigned int uint;
]], [[
        typedef unsigned int uint;
]])
end)

test('allow constants', function()
    local fast = vida.compile(
        vida.code[[EXPORT int testConstant = 101;]],
        vida.interface[[int testConstant;]])
    assert(fast.testConstant == 101)
end)

test('simple addition', function()
    local fast = vida.source(
        'int add(int, int);',
        'EXPORT int add(int a, int b) { return a+b; }'
    )
    assert(fast.add(3, 5) == 8)
end)

test('multiple functions and types', function()
    local fast = vida.source([[
        typedef unsigned char uchar;
        int add(int, int);
        uchar mult(uchar, uchar);
]],[[
        typedef unsigned char uchar;
        EXPORT int add(int a, int b) {
            return a + b;
        }
        EXPORT uchar mult(uchar x, uchar y) {
            return x * y;
        }
]])
    assert(fast.add(1000, 1001) == 2001)
    assert(fast.mult(123, 125) == 15)
end)

test('use prelude', function()
    local fast = vida.source(
        'uint add(uint, uint);',
        'EXPORT uint mult(uint a, uint b) { return a*b; }'
    )
    assert(fast.mult(3, 5) == 15)
end)

test('load source from files', function()
    local fast = vida.sourceFiles('modulus.ci', 'modulus.c')
    assert(fast.modulus(17, 8) == 1)
end)
