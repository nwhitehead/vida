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

function bench.time(func, ...)
    local t0 = bench.gettime()
    func(...)
    local t1 = bench.gettime()
    return t1 - t0
end

return bench
