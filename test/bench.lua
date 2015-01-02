local ffi = require('ffi')

local bench = {}

-- Benchmarking
ffi.cdef[[
    struct timeval {
        uint32_t sec;
        uint64_t usec;
    };
    int gettimeofday(struct timeval *restrict tp, void *restrict tzp);

    long GetTickCount(void);
]]

function bench.gettime()
    if ffi.os == 'Windows' then
        return ffi.C.GetTickCount() / 1000.0
    else
        local t = ffi.new('struct timeval')
        ffi.C.gettimeofday(t, nil)
        return t.sec + (tonumber(t.usec) / 1000000.0)
    end
end

-- Call a function with args, see how long it takes
-- Returns wall clock time
function bench.time(func, ...)
    local t0 = bench.gettime()
    func(...)
    local t1 = bench.gettime()
    return t1 - t0
end

-- Keep calling a function with args, try to get up to desired time
-- Returns average time per function call, reps
function bench.smart(desiredtime, func, ...)
    local n = 0
    local t0 = bench.gettime()
    local t1 = bench.gettime()
    while t1 - t0 < desiredtime do
        func(...)
        n = n + 1
        t1 = bench.gettime()
    end
    if n == 0 then
        return 0, 0
    end
    return (t1 -  t0) / n, n
end

return bench
