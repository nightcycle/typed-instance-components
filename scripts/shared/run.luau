--!strict
-- Packages
local process = require("@lune/process")
-- Modules
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(command: string, args: { string }): string
	local result = process.exec(command, args)
	if not result.ok then
		-- Printing first preserves full analyzer diagnostics beyond Lune's error truncation.
		print(result.stdout .. result.stderr)
		error(`Command failed: {command}`, 0)
	end
	if result.stdout ~= "" then
		print(result.stdout)
	end
	return result.stdout
end
