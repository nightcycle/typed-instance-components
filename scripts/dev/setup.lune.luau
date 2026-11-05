--!strict
-- Packages
local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
-- Modules
local run = require("../shared/run")
-- Types
-- Constants
local revision = "bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0"
local path = `.tools/globalTypes-{revision}.d.luau`
-- References
-- Global Variables
-- Private Functions
local function main()
	run("lune", { "setup" })
	run("wally", { "install" })
	run("lune", { "run", "scripts/codegen/generate.lune.luau" })
	run("lune", { "run", "scripts/dev/prepare-project.lune.luau", "--dependencies" })
	if not fs.isFile(path) then
		local response = net.request(
			`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{revision}/scripts/globalTypes.d.luau`
		)
		assert(response.ok, "Failed to download pinned Roblox definitions")
		fs.writeDir(".tools")
		fs.writeFile(path, response.body)
	end
	if not fs.isFile("Generated/Selene/roblox.yml") then
		fs.writeDir("Generated/Selene")
		local result = process.exec("selene", { "generate-roblox-std" }, { cwd = "Generated/Selene" })
		assert(result.ok, result.stdout .. result.stderr)
	end
end
-- Class
main()
