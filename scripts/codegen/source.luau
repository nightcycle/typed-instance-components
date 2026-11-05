--!strict
-- Packages
local fs = require("@lune/fs")
local serde = require("@lune/serde")
-- Modules
-- Types
export type Source = { revision: string, url: string, roots: { string }, snapshot: string }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(): Source
	local source = serde.decode("json", fs.readFile("api/source.json")) :: Source
	assert(source.revision:match("^%x+$") and #source.revision == 40, "Pin the API source to a commit SHA")
	for _, root in source.roots do
		assert(root:match("^[%a_][%w_]*$"), "API roots must be class names")
	end
	source.snapshot = `Generated/Api/{source.revision}-{table.concat(source.roots, "-")}.json`
	return source
end
