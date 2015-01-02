local ffi = require('ffi')
local vida = require('vida')
local os = require('os')
local bench = require('bench')

local fast = vida.compile(
    vida.interface [[
    int func(int a, int b);
]], vida.code [[
    EXPORT int func(int a, int b) {
        return a + b;
    }
]])

local vector = vida.compile(
    vida.interface [[

    void add(int *, int *, size_t);
    void mix(int *, int *, size_t, float);
    void sort(int *, size_t);

]], vida.code [[

    #include <stddef.h>

    EXPORT void add(int *x, int *y, size_t n) {
        while (n--) *x++ += *y++;
    }

    EXPORT void mix(int *x, int *y, size_t n, float alpha) {
        while (n--) {
            *x++ += (int)(alpha * (*y++));
        }
    }

    void quicksort_h(int *list, int m, int n) {
        int key, i, j, k, tmp;
        if (m < n) {
            k = (m + n) / 2; // pivot
            tmp = list[m];
            list[m] = list[k];
            list[k] = tmp;
            key = list[m];
            i = m + 1;
            j = n;
            while (i <= j) {
                while((i <= n) && (list[i] <= key)) i++;
                while((j >= m) && (list[j] > key)) j--;
                if (i < j) {
                    tmp = list[i];
                    list[i] = list[j];
                    list[j] = tmp;
                }
            }
            tmp = list[m];
            list[m] = list[j];
            list[j] = tmp;
            quicksort_h(list, m, j - 1);
            quicksort_h(list, j + 1, n);
        }
    }

    EXPORT void sort(int *list, size_t n) {
        quicksort_h(list, 0, n - 1);
    }

]])

assert(8 == fast.func(3, 5))

local n = 10000
local xvec = ffi.new('int[?]', n)
local xx = {}
local originalxx = {}
for i = 0, n - 1 do
    xvec[i] = math.random(n)
    if i == 100 then
        xvec[i] = 999999
    end
    xx[i] = xvec[i]
    originalxx[i] = xx[i]
end

local function ms(v)
    return string.format('%s ms', v * 1000)
end

local t = 0.5

for i = 0, n - 1 do
    xx[i] = originalxx[i]
end
print('luajit sort', ms(bench.smart(t, function ()
    table.sort(xx)
end)))
assert(xx[n - 1] == 999999) -- spot check output

for i = 0, n - 1 do
    xvec[i] = originalxx[i]
end
print('vector sort', ms(bench.smart(t, function ()
    vector.sort(xvec, n)
end)))
assert(xvec[n - 1] == 999999) -- spot check output


local n = 10000
local xvec = ffi.new('int[?]', n)
local yvec = ffi.new('int[?]', n)
local xx = {}
local yy = {}
for i = 0, n-1 do
    xvec[i] = i
    xx[i] = i
    yvec[i] = i * i
    yy[i] = i * i
end
vector.add(xvec, yvec, n)
assert(110 == xvec[10])
vector.mix(xvec, yvec, n, 0.5)
assert(160 == xvec[10])

print('luajit add (cdata)', ms(bench.smart(t, function ()
    for j = 0, n - 1 do
        xvec[j] = xvec[j] + yvec[j]
    end
end)))

print('luajit add (hash)', ms(bench.smart(t, function ()
    for j = 0, n - 1 do
        xx[j] = xx[j] + yy[j]
    end
end)))

jit.off()
print('luajit add (hash nojit)', ms(bench.smart(t, function ()
    for j = 0, n - 1 do
        xx[j] = xx[j] + yy[j]
    end
end)))
jit.on()

jit.off()
print('luajit add (nojit)', ms(bench.smart(t, function ()
    for j = 0, n - 1 do
        xvec[j] = xvec[j] + yvec[j]
    end
end)))
jit.on()

print('vector.add', ms(bench.smart(t, function ()
    vector.add(xvec, yvec, n)
end)))

print('luajit mix', ms(bench.smart(t, function ()
    local alpha = 0.001
    for j = 0, n - 1 do
        xvec[j] = xvec[j] + alpha * yvec[j]
    end
end)))

print('vector.mix', ms(bench.smart(t, function ()
    local alpha = 0.001
    vector.mix(xvec, yvec, n, alpha)
end)))
