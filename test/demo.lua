local ffi = require('ffi')
local vida = require('vida')
local os = require('os')
local bench = require('bench')

local fast = vida.source([[
    // C interface
    int func(int a, int b);
]], [[
    // C implementation
    EXPORT int func(int a, int b) {
        return a + b;
    }
]])

local vector = vida.source([[

    // C interface
    void add(int *, int *, size_t);
    void mix(int *, int *, size_t, float);
    void sort(int *, size_t);

]], [[

    // C implementation

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

print(8, fast.func(3, 5))

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

local reps = 1000
print('luajit sort', 10 * bench.time(function ()
    for i = 1, reps / 10 do
        for i = 0, n - 1 do
            xx[i] = originalxx[i]
        end
        table.sort(xx)
    end
end))
print(999999, xx[n - 1])

local reps = 1000
print('vector sort', bench.time(function ()
    for i = 0, n - 1 do
        xvec[i] = originalxx[i]
    end
    for i = 1, reps do
        vector.sort(xvec, n)
    end
end))
print(999999, xvec[n - 1])


local n = 100000
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
print(110, xvec[10])
vector.mix(xvec, yvec, n, 0.5)
print(160, xvec[10])

local reps = 1000

print('luajit add', bench.time(function ()
    for i = 0, reps do
        for j = 0, n - 1 do
            xvec[i] = xvec[i] + yvec[i]
        end
    end
end))

print('luajit add (hash)', 10 * bench.time(function ()
    for i = 0, reps / 10 do
        for j = 0, n - 1 do
            xx[i] = xx[i] + yy[i]
        end
    end
end))

jit.off()
print('luajit add (hash nojit)', bench.time(function ()
    for i = 0, reps do
        for j = 0, n - 1 do
            xx[i] = xx[i] + yy[i]
        end
    end
end))
jit.on()

jit.off()
print('luajit add (nojit)', 20 * bench.time(function ()
    for i = 0, reps / 20 do
        for j = 0, n - 1 do
            xvec[i] = xvec[i] + yvec[i]
        end
    end
end))
jit.on()

print('luajit mix', bench.time(function ()
    local alpha = 0.001
    for i = 0, reps do
        for j = 0, n - 1 do
            xvec[i] = xvec[i] + alpha * yvec[i]
        end
    end
end))

print('vector.add', bench.time(function ()
    for i = 0, reps do
        vector.add(xvec, yvec, n)
    end
end))

print('vector.mix', bench.time(function ()
    for i = 0, reps do
        vector.mix(xvec, yvec, n, 0.001)
    end
end))
