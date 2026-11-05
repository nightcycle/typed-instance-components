--!strict
-- Packages
local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")
-- Modules
local Api = require("./api")
local getSource = require("./source")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function main()
	local source = getSource()
	local raw: string
	if process.args[1] then
		raw = fs.readFile(process.args[1])
	else
		local response = net.request(source.url)
		assert(response.ok, "Failed to download pinned API dump")
		raw = response.body
	end
	local dump = serde.decode("json", raw) :: Api.Dump
	local index = Api.index(dump)
	local selected: { [string]: boolean } = {}
	for _, class in dump.Classes do
		if Api.inTree(index, class, source.roots) then
			local current: Api.Class? = class
			while current do
				selected[current.Name] = true
				current = index[current.Superclass]
			end
		end
	end
	local classes: { Api.Class } = {}
	for _, class in dump.Classes do
		if selected[class.Name] then
			local members: { Api.Member } = {}
			for _, member in class.Members do
				if member.MemberType == "Property" then
					table.insert(
						members,
						{
							MemberType = member.MemberType,
							Name = member.Name,
							Tags = member.Tags,
							Security = member.Security,
							ValueType = member.ValueType,
						} :: Api.Member
					)
				end
			end
			table.sort(members, function(a, b)
				return a.Name < b.Name
			end)
			table.insert(
				classes,
				{ Name = class.Name, Superclass = class.Superclass, Tags = class.Tags, Members = members }
			)
		end
	end
	table.sort(classes, function(a, b)
		return a.Name < b.Name
	end)
	fs.writeDir("Generated/Api")
	fs.writeFile(source.snapshot, serde.encode("json", { Classes = classes }, true) .. "\n")
	print(`Saved {#classes} classes, including ancestors, from the pinned API dump.`)
end
-- Class
main()
