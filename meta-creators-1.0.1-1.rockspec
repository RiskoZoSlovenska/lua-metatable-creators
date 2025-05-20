package = "meta-creators"
version = "1.0.1-1"
source = {
	url = "git://github.com/RiskoZoSlovenska/lua-metatable-creators",
	tag = "v1.0.1",
}
description = {
	summary = "A simple, lightweight Lua library for easily building metatables",
	detailed = "Metatable Creators is a lightweight, brutally simple library for creating metatables in Lua.",
	homepage = "https://github.com/RiskoZoSlovenska/lua-metatable-creators",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "builtin",
	modules = {
		["meta-creators"] = "meta-creators.lua",
	},
}
