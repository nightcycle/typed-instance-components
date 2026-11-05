--!strict
-- Packages
local process = require("@lune/process")
-- Modules
local getMetadata = require("../shared/package-metadata")
local Release = require("./utils")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function main()
	local metadata = getMetadata()
	local tag = assert(process.env.RELEASE_TAG or process.args[1], "Provide RELEASE_TAG or a version tag")
	Release.validateTag(tag, metadata.Version)
	local target = process.exec("git", { "rev-parse", "--verify", `refs/tags/{tag}^\{commit\}` })
	local head = process.exec("git", { "rev-parse", "HEAD" })
	assert(target.ok and head.ok and target.stdout == head.stdout, "Release must build the exact existing tag commit")
	print(`Validated {tag} against wally.toml and HEAD.`)
end
-- Class
main()
