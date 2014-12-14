output/vida.lua: src/md5.lua src/temp.lua src/vida.lua
	mkdir -p output/
	lua tools/combiner.lua src/md5.lua src/path.lua src/temp.lua src/vida.lua > output/vida.lua
install: output/vida.lua
	install output/vida.lua /usr/local/share/lua/5.1/vida.lua
