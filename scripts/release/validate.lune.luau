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
	local input = assert(process.env.RELEASE_TAG or process.args[1], "Provide RELEASE_TAG or a version tag")
	Release.validateTag(input, metadata.Version)
	local head = process.exec("git", { "rev-parse", "HEAD" })
	for _, tag in Release.tags(input) do
		local target = process.exec("git", { "rev-parse", "--verify", `refs/tags/{tag}^\{commit\}` })
		if target.ok then
			assert(head.ok and target.stdout == head.stdout, "Release must build the exact existing tag commit")
			print(`Validated {tag} against wally.toml and HEAD.`)
			return
		end
	end
	error(`No release tag exists for version {Release.version(input)} (checked both spellings)`)
end
-- Class
main()
