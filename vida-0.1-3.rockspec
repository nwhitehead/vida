package = "Vida"
version = "0.1-3"
source = {
    url = 'https://github.com/nwhitehead/vida/archive/v0.1-3.tar.gz',
    dir = 'vida-0.1-3'
}
description = {
    summary = "Mix C code into your LuaJIT code seamlessly.",
    detailed = [[
        Vida is a Lua module that allows you to include C code and
        call it right from your Lua code without messing around with
        makefiles, compilers, or any other nonsense.
    ]],
    homepage = "https://github.com/nwhitehead/vida",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
    "luajit >= 2.0"
}
build = {
    type = 'builtin',
    modules = {
        vida = "output/vida.lua'
    }
}

