local ffi = require('ffi')

local temp = {}

function temp.name()
	if ffi.os == 'Windows' then
		return os.getenv('TEMP') .. os.tmpname()
	end
	return os.tmpname()
end

return temp
