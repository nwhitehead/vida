all:
	mkdir -p output/
	lua tools/combiner.lua src/md5.lua src/path.lua src/temp.lua src/vida.lua > output/vida.lua
