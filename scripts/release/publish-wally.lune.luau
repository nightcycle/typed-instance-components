--!strict
-- Packages
local process = require("@lune/process")
-- Modules
local Release = require("./utils")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function main()
	local token = process.env.WALLY_AUTH_TOKEN
	assert(token and token ~= "", "Configure the WALLY_AUTH_TOKEN repository secret before releasing")
	local login = process.exec("wally", { "login", "--token", token })
	assert(login.ok, "Wally authentication failed")
	local result = process.exec("wally", { "publish" })
	print(table.concat(string.split(result.stdout .. result.stderr, token), "[REDACTED]"))
	assert(
		Release.published(result.ok, result.stdout),
		"Wally did not confirm publication; inspect the registry response"
	)
end
-- Class
main()
