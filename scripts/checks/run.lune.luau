--!strict
-- Packages
local fs = require("@lune/fs")
local process = require("@lune/process")
-- Modules
local run = require("../shared/run")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function main()
	run("lune", { "run", "scripts/codegen/generate.lune.luau" })
	run("lune", { "run", "scripts/codegen/generate.lune.luau", "--check" })
	run("lune", { "run", "scripts/dev/prepare-project.lune.luau" })
	run("lune", { "run", "tests/run.lune.luau" })
	run("stylua", { "--check", "src", "Generated/Package", "Generated/Dev", "scripts", "tests", "examples" })
	run("selene", {
		"--display-style=quiet",
		"--color=never",
		"src",
		"Generated/Package",
		"Generated/Dev",
		"examples",
		"tests/roblox",
	})
	run("selene", {
		"--display-style=quiet",
		"--color=never",
		"--config=scripts/checks/selene-lune.toml",
		"scripts",
		"tests/run.lune.luau",
		"tests/load.luau",
	})
	run("luau-lsp", { "analyze", "--platform=standard", "scripts", "tests/run.lune.luau", "tests/load.luau" })
	local args = {
		"analyze",
		"--platform",
		"roblox",
		"--sourcemap",
		"Generated/sourcemap.json",
		"--definitions",
		".tools/globalTypes-bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0.d.luau",
		"--ignore",
		"Packages/**",
		"--ignore",
		"DevPackages/**",
	}
	local valid = table.clone(args)
	for _, path in { "src", "Generated/Package", "Generated/Dev", "examples", "tests/roblox" } do
		table.insert(valid, path)
	end
	run("luau-lsp", valid)
	local invalid = "tests/type-errors/Invalid.luau"
	table.insert(args, invalid)
	local result = process.exec("luau-lsp", args)
	assert(not result.ok, "Negative type fixtures unexpectedly passed")
	local diagnostics = result.stdout .. result.stderr
	local checked = 0
	local expectedUnknownRequires: { [number]: boolean } = {}
	for lineNumber, line in string.split(fs.readFile(invalid), "\n") do
		if line:find("EXPECT_UNKNOWN_REQUIRE", 1, true) then
			expectedUnknownRequires[lineNumber] = true
		end
		if line:find("-- EXPECT_ERROR", 1, true) then
			assert(
				diagnostics:find(`]({lineNumber},`, 1, true),
				`Expected type error at line {lineNumber}:\n{diagnostics}`
			)
			checked += 1
		end
	end
	for _, line in string.split(diagnostics, "\n") do
		if line:find("Unknown require", 1, true) then
			local lineNumber = tonumber(line:match("%]%((%d+),"))
			assert(lineNumber and expectedUnknownRequires[lineNumber], `Unexpected unresolved import:\n{line}`)
		end
	end
	assert(checked >= 9)
	print(`Strict analysis and {checked} negative type checks passed.`)
end
-- Class
main()
