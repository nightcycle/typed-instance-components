--!strict
-- Packages
local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")
-- Modules
-- Types
-- Constants
local definitions = ".tools/globalTypes-bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0.d.luau"
-- References
-- Global Variables
-- Private Functions
local function main()
	local robloxFiles: { string } = {}
	local luneFiles: { string } = {}
	for _, file in process.args do
		local path = file:gsub("\\", "/")
		local root = process.cwd:gsub("\\", "/"):gsub("/$", "") .. "/"
		if path:sub(1, #root):lower() == root:lower() then
			path = path:sub(#root + 1)
		end
		if not path:match("%.luau$") or not fs.isFile(path) then
			continue
		end
		-- Intentional type-error fixtures are verified by checks/run.lune.luau.
		if path:match("^tests/type%-errors/") then
			continue
		end
		if path:match("^scripts/") or path == "tests/run.lune.luau" or path == "tests/load.luau" then
			table.insert(luneFiles, path)
		elseif
			path:match("^src/")
			or path:match("^Generated/Package/")
			or path:match("^Generated/Dev/")
			or path:match("^examples/")
			or path:match("^tests/roblox/")
		then
			table.insert(robloxFiles, path)
		else
			error(`No validation environment configured for {path}`, 0)
		end
	end
	local failures: { string } = {}
	local function check(command: string, args: { string }): boolean
		local result = process.exec(command, args)
		if not result.ok then
			table.insert(failures, `== {command} ==\n{result.stdout}{result.stderr}`)
		end
		return result.ok
	end
	if #robloxFiles > 0 then
		local ready = true
		if not fs.isDir("Generated/Package") then
			ready = check("lune", { "run", "scripts/codegen/generate.lune.luau" })
		end
		-- Rebuild once per edit batch, including new, moved and removed modules.
		ready = check("lune", { "run", "scripts/dev/prepare-project.lune.luau" }) and ready
		if ready then
			local args = {
				"analyze",
				"--platform=roblox",
				"--definitions=" .. definitions,
				"--sourcemap=Generated/sourcemap.json",
				"--ignore=Packages/**",
				"--ignore=DevPackages/**",
			}
			table.move(robloxFiles, 1, #robloxFiles, #args + 1, args)
			check("luau-lsp", args)
		end
		local args = { "--display-style=quiet", "--color=never" }
		table.move(robloxFiles, 1, #robloxFiles, #args + 1, args)
		check("selene", args)
	end
	if #luneFiles > 0 then
		local args = { "analyze", "--platform=standard" }
		table.move(luneFiles, 1, #luneFiles, #args + 1, args)
		check("luau-lsp", args)
		args = { "--display-style=quiet", "--color=never", "--config=scripts/checks/selene-lune.toml" }
		table.move(luneFiles, 1, #luneFiles, #args + 1, args)
		check("selene", args)
	end
	if #failures > 0 then
		stdio.ewrite(table.concat(failures, "\n\n") .. "\n")
		process.exit(2)
	end
end
-- Class
main()
