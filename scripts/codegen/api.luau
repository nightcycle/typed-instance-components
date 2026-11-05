--!strict
-- Packages
-- Modules
-- Types
export type ValueType = { Category: string, Name: string }
export type Member = {
	MemberType: string,
	Name: string,
	Tags: { unknown }?,
	Security: { Read: string, Write: string }?,
	ValueType: ValueType?,
}
export type Class = { Name: string, Superclass: string, Tags: { unknown }?, Members: { Member } }
export type Dump = { Classes: { Class } }
-- Constants
local primitives =
	{ bool = "boolean", string = "string", int = "number", int64 = "number", float = "number", double = "number" }
local datatypes = {
	BrickColor = "BrickColor",
	Color3 = "Color3",
	ColorSequence = "ColorSequence",
	Content = "Content",
	ContentId = "string",
	Font = "Font",
	NumberSequence = "NumberSequence",
	Rect = "Rect",
	UDim = "UDim",
	UDim2 = "UDim2",
	Vector2 = "Vector2",
	Vector3 = "Vector3",
}
-- References
-- Global Variables
-- Private Functions
-- Class
local Api = {}

function Api.hasTag(tags: { unknown }?, tag: string): boolean
	return tags ~= nil and table.find(tags, tag) ~= nil
end

function Api.index(dump: Dump): { [string]: Class }
	local index: { [string]: Class } = {}
	for _, class in dump.Classes do
		index[class.Name] = class
	end
	return index
end

function Api.inTree(index: { [string]: Class }, class: Class, roots: { string }): boolean
	local current: Class? = class
	while current do
		if table.find(roots, current.Name) then
			return true
		end
		current = index[current.Superclass]
	end
	return false
end

function Api.propertyType(value: ValueType): string?
	if value.Category == "Enum" then
		return `Enum.{value.Name}`
	elseif value.Category == "Class" then
		return `{value.Name}?`
	elseif value.Category == "Primitive" then
		return (primitives :: { [string]: string })[value.Name]
	end
	return (datatypes :: { [string]: string })[value.Name]
end

function Api.properties(index: { [string]: Class }, name: string): { [string]: string }
	local class = assert(index[name], `Missing ancestor {name}`)
	local result: { [string]: string } = if index[class.Superclass] then Api.properties(index, class.Superclass) else {}
	for _, member in class.Members do
		if member.MemberType ~= "Property" then
			continue
		end
		-- A subclass can override an inherited member with restricted access.
		result[member.Name] = nil
		if
			member.Name == "Parent"
			or member.Name == "ClassName"
			or member.Name == "RobloxLocked"
			or member.Name == "Capabilities"
			or member.Name == "Sandboxed"
			or member.Name == "UniqueId"
			or not member.Name:match("^[%a_][%w_]*$")
			or not member.Security
			or member.Security.Read ~= "None"
			or member.Security.Write ~= "None"
			or Api.hasTag(member.Tags, "ReadOnly")
			or Api.hasTag(member.Tags, "NotScriptable")
			or Api.hasTag(member.Tags, "Hidden")
			or Api.hasTag(member.Tags, "Deprecated")
		then
			continue
		end
		local valueType = assert(member.ValueType)
		local propertyType = Api.propertyType(valueType)
		-- New public API types must be reviewed instead of silently becoming any.
		assert(propertyType, `Unsupported type {valueType.Name} on {name}.{member.Name}`)
		result[member.Name] = propertyType
	end
	return result
end

function Api.creatable(class: Class): boolean
	return not Api.hasTag(class.Tags, "NotCreatable")
		and not Api.hasTag(class.Tags, "Service")
		and not Api.hasTag(class.Tags, "Deprecated")
		and not Api.hasTag(class.Tags, "NotBrowsable")
end

return Api
