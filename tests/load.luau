--!strict
-- Packages
local fs = require("@lune/fs")
local luau = require("@lune/luau")
-- Modules
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
-- Execute the production builders in Lune. React is imported only for type aliases.
return function(onLoad: ((string) -> ())?): (string) -> any
	local cache: { [string]: any } = { React = {} }
	local compiled: { [string]: () -> any } = {}
	local function load(name: string): any
		if cache[name] then
			return cache[name]
		end
		local result = assert(compiled[name], `Missing test module: {name}`)()
		cache[name] = result
		if onLoad then
			onLoad(name)
		end
		return result
	end
	-- Roblox runs precompiled ModuleScripts. Preload source/bytecode without executing
	-- modules so Lune's asynchronous filesystem does not yield inside __index.
	for _, directory in { "src", "Generated/Package" } do
		for _, file in fs.readDir(directory) do
			local moduleName = file:match("^(.*)%.luau$")
			if moduleName == nil then
				continue
			end
			local name = if moduleName == "init" then "src" else `src/{moduleName}`
			local path = `{directory}/{file}`
			local source = fs.readFile(path):gsub("require%((script[%w%.]*)%)", function(expression: string): string
				local segments = string.split(name, "/")
				local members = string.split(expression, ".")
				for i = 2, #members do
					if members[i] == "Parent" then
						table.remove(segments)
					else
						table.insert(segments, members[i])
					end
				end
				return string.format("require(%q)", table.concat(segments, "/"))
			end)
			compiled[name] =
				luau.load(source, { environment = { require = load }, injectGlobals = true, debugName = path })
		end
	end
	return load
end
