--!strict
-- Packages
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
-- Modules
local run = require("../shared/run")
local getMetadata = require("../shared/package-metadata")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function main()
	run("lune", { "run", "scripts/codegen/generate.lune.luau" })
	run("lune", { "run", "scripts/dev/prepare-project.lune.luau" })
	local metadata = getMetadata()
	fs.writeDir("Generated/build")
	run("rojo", { "build", "default.project.json", "--output", "Generated/build/typed-instance-components.rbxm" })
	run("rojo", { "build", "dev.project.json", "--output", "Generated/build/typed-instance-components-tests.rbxl" })
	run("wally", { "package", "--output", metadata.Archive })
	local testPlace =
		roblox.deserializePlace(fs.readFile("Generated/build/typed-instance-components-tests.rbxl")) :: any
	local header = testPlace.ReplicatedStorage.Packages.TypedInstanceComponents
	assert(header:IsA("ModuleScript") and #header:GetChildren() == 0, "Public Wally header must have no children")
	assert(
		header.Source:find("_Index.TypedInstanceComponentsDev", 1, true),
		"Header must forward into the package index"
	)
	local implementation =
		testPlace.ReplicatedStorage.Packages._Index.TypedInstanceComponentsDev["typed-instance-components"]
	assert(implementation.Frame:IsA("ModuleScript") and implementation.Custom:IsA("ModuleScript"))
	local package = roblox.deserializeModel(fs.readFile("Generated/build/typed-instance-components.rbxm"))[1] :: any
	assert(package:IsA("ModuleScript") and package.Name == "TypedInstanceComponents")
	local scripts = { package }
	for _, instance in package:GetDescendants() do
		assert(instance.Parent == package, `Package modules must be flat: {instance.Name}`)
		table.insert(scripts, instance)
	end
	for _, instance in scripts do
		assert(instance:IsA("ModuleScript") and instance.Source:find("^%-%-!strict"))
		luau.compile(instance.Source)
		for expression in instance.Source:gmatch("require%((script[%w%.]*)%)") do
			-- The React sibling is supplied by Wally or the consumer of the model.
			if expression:match("%.React$") then
				continue
			end
			local target = instance
			for i, segment in string.split(expression, ".") do
				if i > 1 then
					target = target[segment]
				end
			end
			assert(target ~= nil and target:IsA("ModuleScript"), `Invalid require: {expression}`)
		end
	end
	local listing = run("wally", { "package", "--list" }):gsub("\\", "/")
	for _, required in
		{
			"Generated/Package/init.luau",
			"Generated/Package/Frame.luau",
			"Generated/Package/GuiBase2d.luau",
			"Generated/Package/UIBase.luau",
			"src/Custom.luau",
			"src/Lazy.luau",
		}
	do
		assert(listing:find(required, 1, true), `Missing archive content: {required}`)
	end
	for _, name in fs.readDir("Generated/Package") do
		assert(listing:find(`Generated/Package/{name}`, 1, true), `Missing generated archive module: {name}`)
	end
	for _, forbidden in
		{
			"Packages/",
			"DevPackages/",
			"tests/",
			"scripts/",
			".github/",
			".tools/",
			"Generated/build/",
			"Generated/Api/",
			"Generated/Dev/",
			"Generated/sourcemap.json",
			"Generated/classes.md",
			"Generated/Package/Hosts.luau",
			"Generated/Package/Properties.luau",
			"src/Host.luau",
			"src/Merge.luau",
			"src/Types.luau",
		}
	do
		assert(not listing:find(forbidden, 1, true), `Unexpected archive content: {forbidden}`)
	end
	print(`Built and verified {#scripts} package modules, Wally archive and Studio test place.`)
end
-- Class
main()
