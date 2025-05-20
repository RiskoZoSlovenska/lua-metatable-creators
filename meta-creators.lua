--[[lit-meta
	name = "RiskoZoSlovenska/meta-creators"
	version = "1.0.0"
	homepage = "https://github.com/RiskoZoSlovenska/lua-metatable-creators"
	description = "A simple, lightweight Lua library for easily building metatables."
	tags = {"metatable", "create"}
	license = "MIT"
	author = "RiskoZoSlovenska"
]]


local pairs = pairs
local type = type
local setmetatable = setmetatable
local select = select



local function set(tbl, key, value)
	tbl[key] = value
	return value
end

local function merge(tbl1, tbl2)
	local merged = {}

	for key, value in pairs(tbl1) do
		merged[key] = value
	end

	for key, value in pairs(tbl2) do
		merged[key] = value
	end

	return merged
end

local function copy(tbl)
	local copied = {}

	for key, value in pairs(tbl) do
		copied[key] = type(value) == "table" and copy(value) or value
	end

	return copied
end



local objectMeta = {}
objectMeta.__index = objectMeta



local function createConstructor(constructor)
	return function(...)
		return setmetatable(constructor(...), objectMeta)
	end
end



local Creator = createConstructor(function(meta, base, useProxy)
	return {
		meta = meta,
		base = base,
		useProxy = useProxy or false,
	}
end)


local BaseCreator = createConstructor(function(base)
	return Creator({}, base)
end)


local CombinedCreator = createConstructor(function(...)
	local meta, base = {}, nil

	for i = 1, select("#", ...) do
		local creator = select(i, ...)

		meta = merge(meta, creator.meta)
		base = creator.base or base
	end

	return Creator(meta, base)
end)


local WEAK_MEM = {}
local function getWeakMeta(mode)
	if mode == "vk" then mode = "kv" end

	local meta = WEAK_MEM[mode]
	if not meta then
		meta = {__mode = mode}
		WEAK_MEM[mode] = meta
	end

	return meta
end
local WeakCreator = createConstructor(function(mode)
	return Creator(getWeakMeta(mode))
end)


local AUTO_0_META = {__index = function() return 0 end}
local Auto0Creator = createConstructor(function()
	return Creator(AUTO_0_META)
end)


local Auto2DCreator = createConstructor(function(sub)
	return Creator({__index = function(tbl, key)
		return set(tbl, key, sub and sub:create() or {})
	end})
end)


local proxies = setmetatable({}, getWeakMeta("k"))
local ProxiedCreator = createConstructor(function(meta, base)
	local newMeta = {}

	for key, value in pairs(meta) do
		if type(value) == "function" then
			newMeta[key] = function(proxy, ...)
				return value(proxies[proxy], proxy, ...)
			end
		else
			newMeta[key] = value
		end
	end

	return Creator(newMeta, base, true)
end)


local READ_ONLY_META = {
	__index = function(tbl, _, key)
		return tbl[key]
	end,
	__newindex = function()
		error("cannot write to read-only table")
	end,
	__len = function(tbl)
		return #tbl
	end,
	__pairs = function(tbl)
		local k, v
		return function()
			k, v = next(tbl, k)
			return k, v
		end
	end,
	__ipairs = function(tbl)
		local i = 0
		return function()
			i = i + 1
			local v = tbl[i]
			return (v ~= nil and i or nil), v
		end
	end,
}
local ReadOnlyCreator = createConstructor(function()
	return ProxiedCreator(READ_ONLY_META)
end)



function objectMeta:create(base)
	local new = base or (self.base and copy(self.base)) or {}

	if self.useProxy then
		local real = new
		new = {} -- new becomes the proxy
		proxies[new] = real
	end

	return setmetatable(new, self.meta)
end

objectMeta.combine = CombinedCreator -- We can use this directly
objectMeta.__concat = objectMeta.combine



return {
	Creator = Creator,

	Base = BaseCreator,
	B    = BaseCreator,

	Combined = CombinedCreator,
	C        = CombinedCreator,

	Weak = WeakCreator,
	W    = WeakCreator,

	Auto0 = Auto0Creator,
	A0    = Auto0Creator,

	Auto2D = Auto2DCreator,
	A2D    = Auto2DCreator,


	Proxied = ProxiedCreator,

	ReadOnly = ReadOnlyCreator,
	RO = ReadOnlyCreator,


	createConstructor = createConstructor,
}