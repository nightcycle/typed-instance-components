--!strict
-- Packages
-- Modules
-- Types
type Loader = () -> unknown
type Components = { [string]: unknown }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(loaders: { [string]: Loader }): Components
	local cache: Components = {}
	local function get(name: string): unknown
		if cache[name] ~= nil then
			return cache[name]
		end
		local loader = loaders[name]
		if loader == nil then
			return nil
		end
		local component = loader()
		cache[name] = component
		return component
	end
	return (
		table.freeze(setmetatable(
			{} :: Components,
			table.freeze({
				__index = function(_: Components, name: string): unknown
					return get(name)
				end,
				-- Explicit generalized iteration loads each requested entry as it is visited.
				__iter = function()
					local name: string? = nil
					return function(): (string?, unknown)
						name = next(loaders, name)
						if name == nil then
							return nil, nil
						end
						return name, get(name)
					end
				end,
			})
		)) :: unknown
	) :: Components
end
