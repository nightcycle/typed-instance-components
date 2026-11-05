--!strict
-- Packages
-- Modules
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
local Release = {}
function Release.version(value: unknown): string
	assert(type(value) == "string", "Package version must be a string")
	local major, minor, patch = value:match("^(%d+)%.(%d+)%.(%d+)$")
	assert(major and minor and patch, "Releases require a stable X.Y.Z version")
	for _, part in { major, minor, patch } do
		assert(#part == 1 or part:sub(1, 1) ~= "0", "Version components cannot have leading zeros")
	end
	return value
end
function Release.validateTag(tag: string, version: string)
	assert(tag == "v" .. Release.version(version), "Release tag must match wally.toml version")
end
function Release.published(ok: boolean, stdout: string): boolean
	-- Wally 0.3.2 may return exit code zero on a registry rejection.
	return ok and stdout:find("Package published successfully!", 1, true) ~= nil
end
return Release
