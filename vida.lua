local os = require('os')

local vida = {}

vida.sources = {}

function vida.source(interface, implementation)
    vida.sources[#vida.sources] = {interface, implementation}
end


return vida
