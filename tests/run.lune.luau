--!strict
-- Packages
local fs = require("@lune/fs")
local serde = require("@lune/serde")
-- Modules
local Api = require("../scripts/codegen/api")
local Release = require("../scripts/release/utils")
local getSource = require("../scripts/codegen/source")
local createLoader = require("./load")
-- Types
-- Constants
-- References
local C = createLoader()("src")
-- Global Variables
local count = 0
-- Private Functions
local function test(name: string, callback: () -> ())
	callback()
	count += 1
	print(`PASS {name}`)
end
-- Class
test("package entry point loads and caches only the requested builder", function()
	local loaded: { [string]: number } = {}
	local load = createLoader(function(name: string)
		loaded[name] = (loaded[name] or 0) + 1
	end)
	local components = load("src")
	assert(loaded["src/Custom"] == nil)
	assert(loaded["src/Frame"] == nil and loaded["src/TextLabel"] == nil)
	local frame = components.Frame
	assert(frame == components.Frame and frame == load("src/Frame"))
	assert(loaded["src/Frame"] == 1 and loaded["src/TextLabel"] == nil and loaded["src/Custom"] == nil)
	local class, props = frame({}, { Name = "Lazy", Private = true })
	assert(class == "Frame" and props.Name == "Lazy" and props.Private == nil)
	assert(components.GuiBase2d == nil and components.DoesNotExist == nil)
	assert(table.isfrozen(components) and table.isfrozen(getmetatable(components)))
end)

test("private class modules load independently without unrelated classes", function()
	local loaded: { [string]: boolean } = {}
	local load = createLoader(function(name: string)
		loaded[name] = true
	end)
	local corner = load("src/UICorner")
	assert(loaded.src == nil and loaded["src/Lazy"] == nil and loaded["src/Frame"] == nil)
	local class, props = corner({}, { Name = "Direct", Private = true })
	assert(class == "UICorner" and props.Name == "Direct" and props.Private == nil)
	local abstract = load("src/GuiBase2d")
	assert(type(abstract) == "table" and next(abstract) == nil and table.isfrozen(abstract))
end)

test("generalized iteration exposes every lazy builder", function()
	local components = createLoader()("src")
	local entries = 0
	for name, builder in components do
		assert(type(builder) == "function" and builder == components[name])
		entries += 1
	end
	assert(entries == 34)
end)

test("override precedence, false values and immutable inputs", function()
	local props = table.freeze({ Name = "Caller", Visible = true, LayoutOrder = 2, Label = "private" })
	local overrides = table.freeze({ Name = "Component", Visible = false })
	local class, merged = C.Frame(overrides, props)
	assert(class == "Frame" and merged.Name == "Component" and merged.Visible == false and merged.LayoutOrder == 2)
	assert(merged.Label == nil and props.Visible and props.Name == "Caller")
	merged.LayoutOrder = 10
	assert(props.LayoutOrder == 2)
end)

test("nonstring keys pass through and defaults copy metadata without wrappers", function()
	local event, change, tag = {}, {}, {}
	local binding, ref, children = {}, {}, { Child = {} }
	local callback = function() end
	local props: { [any]: any } = {
		Size = binding,
		ref = ref,
		key = "button",
		children = children,
		[event] = callback,
		[change] = callback,
		[tag] = "Interactive",
	}
	local _, merged, returnedChildren = C.TextButton({ ref = ref, key = "button" }, props, children)
	assert(merged.Size == binding and merged.ref == ref and merged.key == "button")
	assert(merged[event] == callback and merged[change] == callback and merged[tag] == "Interactive")
	assert(merged.children == nil and returnedChildren == children)
end)

test("empty props, explicit children and separate result tables", function()
	local _, first, children = C.Frame({}, {})
	local _, second = C.Frame({}, {})
	assert(next(first) == nil and first ~= second and children == nil)
	local child = {}
	local _, _, result = C.Frame({}, {}, child)
	assert(result == child)
	local _, filtered, inherited = C.Frame({}, { children = child, ref = {}, key = "private" })
	assert(inherited == nil and filtered.children == nil and filtered.ref == nil and filtered.key == nil)
	local _, _, removed = C.Frame({}, { children = child }, false)
	assert(removed == false)
	local _, _, replaced = C.Frame({ children = child }, { children = {} })
	assert(replaced == nil)
end)

test("all generated hosts filter inherited and class-specific properties", function()
	local dump = serde.decode("json", fs.readFile(getSource().snapshot)) :: Api.Dump
	local index = Api.index(dump)
	local hosts = 0
	for _, class in dump.Classes do
		if not Api.inTree(index, class, { "GuiBase2d", "UIBase" }) then
			continue
		end
		if Api.creatable(class) then
			hosts += 1
			local supplied: { [string]: unknown } = { PrivateProp = true, AbsoluteSize = true, Parent = true }
			local props = Api.properties(index, class.Name)
			for name in props do
				supplied[name] = name
			end
			local name, result = C[class.Name]({}, supplied)
			assert(name == class.Name and result.Name == "Name")
			assert(result.PrivateProp == nil and result.AbsoluteSize == nil and result.Parent == nil)
			for key in props do
				assert(result[key] == key, `{class.Name}.{key} was lost`)
			end
		else
			assert(C[class.Name] == nil, `Non-public class {class.Name} exposed as a host`)
		end
	end
	assert(hosts == 33)
end)

test("custom classes and function components use the typed projection", function()
	local function project(props: any): any
		return { Value = props.Value, ref = props.ref }
	end
	local components: { any } = { "Part", function() end, {} }
	for _, component in components do
		local builder = C.Custom(component, project)
		local input = table.freeze({ Value = 3, PrivateProp = true })
		local target, result, children = builder({ Value = 4 }, input, false)
		assert(target == component and result.Value == 4 and result.PrivateProp == nil and children == false)
		assert(input.Value == 3)
		local _, empty = builder({ Value = 5 }, {})
		assert(empty.Value == 5)
	end
end)

test("API maps enum, asset URI, Content and instance reference types", function()
	assert(Api.propertyType({ Category = "DataType", Name = "ContentId" }) == "string")
	assert(Api.propertyType({ Category = "DataType", Name = "Content" }) == "Content")
	assert(Api.propertyType({ Category = "Enum", Name = "Font" }) == "Enum.Font")
	assert(Api.propertyType({ Category = "Class", Name = "Camera" }) == "Camera?")
	local index = Api.index(serde.decode("json", fs.readFile(getSource().snapshot)))
	assert(Api.properties(index, "ImageLabel").Image == "string")
	assert(Api.properties(index, "ViewportFrame").CurrentCamera == "Camera?")
end)

test("subclass restrictions remove inherited writable properties", function()
	local index: { [string]: Api.Class } = {
		Base = {
			Name = "Base",
			Superclass = "none",
			Members = {
				{
					Name = "Value",
					MemberType = "Property",
					Security = { Read = "None", Write = "None" },
					ValueType = { Category = "Primitive", Name = "int" },
				},
			},
		},
		Child = {
			Name = "Child",
			Superclass = "Base",
			Members = {
				{ Name = "Value", MemberType = "Property", Tags = { "ReadOnly" } },
			},
		},
	}
	assert(Api.properties(index, "Base").Value == "number" and Api.properties(index, "Child").Value == nil)
end)

test("release rejects tag mismatches and false-positive Wally success", function()
	Release.validateTag("v0.1.0", "0.1.0")
	assert(not pcall(Release.validateTag, "v0.2.0", "0.1.0"))
	assert(not pcall(Release.version, "01.2.3"))
	assert(not Release.published(true, "Registry error"))
	assert(Release.published(true, "Package published successfully!"))
end)
print(`{count} regression tests passed.`)
