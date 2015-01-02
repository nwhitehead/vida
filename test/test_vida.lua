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
    vida.prelude(
        vida.interface[[typedef unsigned int uint;]],
        vida.code[[typedef unsigned int uint;]]
    )
end)

test('allow constants', function()
    local fast = vida.compile(
        vida.code [[EXPORT int testConstant = 101;]],
        vida.interface [[int testConstant;]])
    assert(fast.testConstant == 101)
end)

test('simple addition', function()
    local fast = vida.compile(
        vida.code 'EXPORT int add(int a, int b) { return a+b; }',
        vida.interface 'int add(int, int);')
    assert(fast.add(3, 5) == 8)
end)

test('string-is-code', function()
    local fast = vida.compile(
        'EXPORT int adder(int a, int b) { return a+b; }')
    vida.cdef('int adder(int, int);')
    assert(fast.adder(3, 5) == 8)
end)

test('multiple functions and types', function()
    local fast = vida.compile(vida.interface[[
        typedef unsigned char uchar;
        int add(int, int);
        uchar mult(uchar, uchar);
]], vida.code[[
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
    local fast = vida.compile(
        vida.interface 'uint add(uint, uint);',
        vida.code 'EXPORT uint mult(uint a, uint b) { return a*b; }'
    )
    assert(fast.mult(3, 5) == 15)
end)

test('load source from files', function()
    local fast = vida.compile(
        vida.interfacefile 'modulus.ci',
        vida.codefile 'modulus.c')
    assert(fast.modulus(17, 8) == 1)
end)
