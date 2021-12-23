# Metatable Creators

Metatable Creators is a lightweight, brutally simple library for creating metatables in Lua.

# Installation

Meta Creators can be installed from [lit](https://luvit.io/lit.html) using
```
lit install RiskoZoSlovenska/meta-creators
```

Once installed, it can be required using
```lua
local meta = require("meta-creators")
```

# Example

The library was born from the desire to avoid this kind of code:
```lua
-- Very specific use case which requires an auto-2D table, where both the main table itself and any subtables are weak-keyed
local WEAK_META = {__mode = "k"}
local MAIN_META = {
	__index = function(tbl, key)
		local new = setmetatable({}, WEAK_META)
		tbl[key] = new
		return new
	end,
	__mode = "k",
}

local someTable = setmetatable({}, MAIN_META)
```

With Meta Creators, the above can be condensed down to
```lua
local creator = meta.Combined(
	meta.Auto2D(meta.Weak("k")),
	meta.Weak("k")
)

local someTable = creator:create()
```
Using some convenience shortcuts, it can be compacted even further:
```lua
local creator = meta.A2D(meta.W("k")) .. meta.W("k")

local someTable = creator:create()
```


# Docs

## `Creator` Objects

This library is based around `Creator` objects. These objects are extremely simple:

### Properties
|Name|Type            |Description|
|:--:|:--------------:|-----------|
|meta|`table`         |The metatable that this `Creator` will use when creating new objects|
|base|`table` or `nil`|An optional table structure template  that this `Creator` will use for creating new objects|
|useProxy|`boolean`|Whether this creator operates using proxies. See [Proxied Tables](#proxied-tables).

### Methods

---
#### `:create(base)`

|Parameter|Type   |Optional|
|:-------:|:-----:|:------:|
|base     |`table`|✔️| 


If the `base` argument is non-`nil`, the creator's `meta` field will be set as its metatable and be it will be returned. Otherwise, if the creator's `base` property is not `nil`, it will be deepcopied, the `meta` field set as its metatable and returned. Otherwise, returns a new empty table with the `meta` field set as its metatable.

**Returns:** `table`

---
#### `:combine(...)`

|Parameter|Type     |
|:-------:|:-------:|
|...      |`Creator`|

Creates a new `Creator` via the `Combined` constructor, using itself and any other arguments as arguments for the constructor.

**Returns:** `Creator`

```lua
creator1:combine(creator2, creator3)
-- is the equivalent of
Combined(creator1, creator2, creator3)
```

---
#### `:__concat(...)`

Overload for the `..` concat operator. Behaves identically to `:combine()`.

```lua
creator1 .. creator2
-- is the equivalent of
creator1:combine(creator2)
```

## Constructors

`Creator` objects are created using constructors provided by the module. These are:

--- 
### `Creator(meta, base, isProxied)`

***Aliases:** None*

|Parameter|Type     |Optional|
|:-------:|:-------:|:-:|
|meta     |`table`  |❌|
|base     |`table`  |✔️|
|useProxy |`boolean`|✔️|

Creates a new Creator with the provided `meta` and `base` fields. This is the most fundamental constructor, and is used by all others. By default, `base` is `nil` and `useProxy` is `false`.

---
### `Base(base)`

***Aliases:** `B`*

|Parameter|Type   |Optional|
|:-------:|:-----:|:-:|
|base     |`table`|❌|

Creates a new `Creator` with an empty table `meta` and a `base`.

---
### `Combined(...)`

***Aliases:** `C`*

|Parameter|Type     |Optional|
|:-------:|:-------:|:-:|
|...      |`Creator`|❌|

Creates a new `Creator` by merging the `meta`s of the provided creators (newer fields overwrite old fields) and taking the newest non-`nil` `base`.

```lua
Combined(
	Creator({__index = func1, __mode = "k"}),
	Creator({}, {123, 456})
	Creator({__index = func2}, {1, 2, 3}),
)
-- is the equivalent of
Creator(
	{__index = func2, __mode = "k"},
	{1, 2, 3}
)
```

---
### `Weak(mode)`

***Aliases:** `W`*

|Parameter|Type                          |Optional|
|:-------:|:----------------------------:|:-:|
|mode     |One of `"k"`, `"v"`, or `"kv"`|❌|

Creates a new `Creator` with a metatable that has the `__mode` method set to the provided `mode`.

---
### `Auto0()`

***Aliases:** `A0`*

Creates a new `Creator` with a metatable so that indexing non-existing elements returns a 0. Useful for frequency tables.

```lua
local freq = Auto0():create() -- freq is {}

print(freq[1]) -- Prints 0; freq is still {}

freq.hi = freq.hi + 1 -- freq is now {["hi"] = 1}
```

---
### `Auto2D(sub)`

***Aliases:** `A2D`*

|Parameter|Type     |Optional|
|:-------:|:-------:|:-:|
|sub      |`Creator`|✔️|

Creates a new `Creator` with a metatable so that indexing non-existing elements creates and returns a new table at the accessed index. Optionally, `sub` may be provided to act as a provider for new sub-tables. Otherwise, plain empty tables are used.

```lua
local twoD = Auto2D():create() -- twoD is {}

print(#twoD[2]) -- Prints 0; twoD is now {nil, {}}

table.insert(twoD[1], "hello") -- twoD is now {{"hello"}, {}}
```

---
### `Proxied(meta, base)`

***Aliases:** None*

|Parameter|Type     |Optional|
|:-------:|:-------:|:-:|
|meta     |`table`  |❌|
|base     |`table`  |✔️|

Creates a new `Creator` with `isProxied` set to true. The metatable passed to the new creator is modified so that any functions are called with an extra leading argument, that being the real table (not the proxy). See [Proxied Tables](#proxied-tables).

---
### `ReadOnly()`

***Aliases:** `RO`*

Creates a new `Creator` that creates proxied tables that can be read from, but writing to throws an error.

```lua
local readOnly = ReadOnly():create({1, 2, 3})

print(readOnly[2]) -- 2
print(#readOnly) -- 3
readOnly[2] = 4 -- error: cannot write to read-only table
```

## Proxied Tables
Some metatable effects require proxies, such as read-only tables (since to invoke the `__index` and `__newindex` metamethods, the queried index has to be `nil`). Meta Creators supports this via the `useProxy` parameter provided by the `Creator()` constructor. When it is set to a truthy value, `Creator:create()` creates two tables: a "real" table just like it does normally, and an empty proxy table. The proxy table has its metatable set and is returned, while the "real" table is stored behind the scenes.

To facilitate writing metamethods for proxy tables, the `Proxied()` constructor exists. It is similar to `Creator()`, except:
* `useProxy` is `true`
* functions in the provided `meta` table are wrapped to receive an extra leading argument - the real table.

To give an example:
```lua
local readOnly = ReadOnly():create({1, 2, 3})
-- readOnly is now a proxy table ({}), while the real table ({1, 2, 3}) is hidden


-- This is the __index metamethod that ReadOnly() passed to Proxied()
__index = function(tbl, proxy, key)
	-- tbl is the real, hidden table ({1, 2, 3}) and proxy is the same table as in the readOnly variable ({})
	return tbl[key]
end
```


## Custom Constructors
Sometimes, the default constructors provided by Meta Creators won't be sufficient for your exact use case, but creating your own isn't difficult. It can be done using the provided `createConstructor(constructor)` function. The only argument `constructor` is a function what will be called when then resulting constructor is called; it may accept any parameters, and should return a table (the resulting `Creator`). Note that the resulting `Creator` will have its metatable set *after* it's returned.

As an example, the `Auto0()` constructor is defined as:
```lua
local AUTO_0_META = {__index = function() return 0 end}
local Auto0 = createConstructor(function()
	return Creator(AUTO_0_META)
end)
```








