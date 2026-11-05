--!strict
-- Packages
local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local task = require("@lune/task")
-- Modules
-- Types
-- Constants
-- References
local model = roblox.deserializePlace(fs.readFile("Generated/build/typed-instance-components-tests.rbxl")) :: any
-- Global Variables
-- Private Functions
local function encode(instance: any): any
	local children = {}
	for _, child in instance:GetChildren() do
		table.insert(children, encode(child))
	end
	local source: string? = nil
	if instance:IsA("ModuleScript") then
		source = instance.Source
		-- Wally dev thunks point at the live DataModel. Rebase those thunks to this detached tree.
		local depth = 0
		local current = instance
		while current ~= model do
			depth += 1
			current = current.Parent
		end
		source = (source :: string):gsub(
			"game%.ReplicatedStorage%.Packages",
			"script" .. string.rep(".Parent", depth) .. ".ReplicatedStorage.Packages"
		)
	end
	return { Name = instance.Name, Source = source, Children = children }
end
-- Class
-- Serves only the built test module tree, on loopback, for an isolated Studio smoke test.
local body = serde.encode("json", encode(model))
local port = tonumber(process.args[1]) or 8741
net.serve(port, function(request)
	if request.path ~= "/tests" then
		return { status = 404, body = "Not found" }
	end
	return { status = 200, body = body, headers = { ["Content-Type"] = "application/json" } }
end)
print(`Studio test tree available at http://127.0.0.1:{port}/tests`)
while true do
	task.wait(60)
end
