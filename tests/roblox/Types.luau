--!strict
-- Packages
local Packages = script.Parent.Parent.Packages
local React = require(Packages.React)
local C = require(Packages.TypedInstanceComponents)
-- Modules
-- Types
-- Constants
-- References
local Frame = C.Frame
-- Global Variables
-- Private Functions
-- Class
local size = UDim2.fromScale(1, 1)
local props: C.FrameProperties = {
	Size = size,
	BackgroundColor3 = Color3.new(1, 0, 0),
	[React.Change.AbsoluteSize] = function(frame: Frame)
		assert(frame.AbsoluteSize.X >= 0)
	end,
}
local className: "Frame", merged: C.FrameProperties = C.Frame({}, props)
local cachedProps: C.FrameProperties = props
local cachedClass: "Frame", cachedMerged: C.FrameProperties = Frame({}, cachedProps)
local baseProps: C.GuiBase2dProperties = { Name = "Abstract properties" }
assert(cachedClass == className and cachedMerged.Size == merged.Size and baseProps.Name ~= nil)
local element = React.createElement(C.Frame({}, props, {
	Label = React.createElement(C.TextLabel({ Text = "Typed" }, {})),
}))
assert(className == "Frame" and merged.Size == size)
return element
