--!strict
-- Packages
local fs = require("@lune/fs")
-- Modules
local run = require("../shared/run")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
run("lune", { "run", "scripts/codegen/generate.lune.luau" })
if fs.isDir("Packages") and fs.isDir("DevPackages") then
	run("lune", { "run", "scripts/dev/prepare-project.lune.luau" })
else
	print(
		"Generated package sources. Run lune run scripts/dev/setup.lune.luau to install dependencies and enable editor type analysis."
	)
end
