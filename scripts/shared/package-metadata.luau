--!strict
-- Packages
local fs = require("@lune/fs")
local serde = require("@lune/serde")
-- Modules
local Release = require("../release/utils")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(): { Version: string, Archive: string }
	local manifest = serde.decode("toml", fs.readFile("wally.toml"))
	local version = Release.version(manifest.package.version)
	return { Version = version, Archive = `Generated/build/typed-instance-components-{version}.zip` }
end
