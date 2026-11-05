--!strict
-- Packages
local C = require(script.Parent.Parent.Packages.TypedInstanceComponents)
local React = require(script.Parent.Parent.Packages.React)
-- Modules
-- Types
type Properties = { Value: number? }
-- Constants
-- References
local Frame = C.Frame
-- Global Variables
-- Private Functions
-- Class
-- Each EXPECT_ERROR line must produce a diagnostic; these fixtures are never executed.
C.Frame({ BackgroundTransparency = "opaque" }, {}) -- EXPECT_ERROR
C.TextLabel({ Text = 42 }, {}) -- EXPECT_ERROR
C.UICorner({ CornerRadius = UDim2.new() }, {}) -- EXPECT_ERROR
local binding = React.createBinding("wrong")
C.Frame({ Size = binding }, {}) -- EXPECT_ERROR
C.GuiBase2d({}, {}) -- EXPECT_ERROR
local custom = C.Custom("Part", function(props: Properties): Properties
	return props
end)
custom({ Value = "wrong" }, {}) -- EXPECT_ERROR
Frame({ Size = "wrong" }, {}) -- EXPECT_ERROR
local invalidProps: C.FrameProperties = { BackgroundTransparency = "opaque" } -- EXPECT_ERROR
Frame(invalidProps, {})
-- The public forwarding header deliberately has no child modules.
require(script.Parent.Parent.Packages.TypedInstanceComponents.Frame) -- EXPECT_ERROR EXPECT_UNKNOWN_REQUIRE
return true
