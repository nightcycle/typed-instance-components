--!strict
-- Packages
local Packages = script.Parent.Parent.Packages
local React = require(Packages.React)
-- Modules
-- Components
local RobloxComponents = require(Packages.TypedInstanceComponents)
-- Contexts
-- Hooks
-- Types
type PartProps = {
	Color: Color3?,
	Anchored: boolean?,
}

type BadgeProps = { Title: string?, children: React.ReactNode? }
-- Constants
-- References
-- Global Variables
-- Private Functions
local function Badge(props: BadgeProps)
	return React.createElement(RobloxComponents.TextLabel({ Text = props.Title or "Badge" }, {}, props.children))
end
-- Class
local Part = RobloxComponents.Custom("Part", function(props: PartProps): PartProps
	return { Color = props.Color, Anchored = props.Anchored }
end)

local CustomBadge = RobloxComponents.Custom(Badge, function(props: BadgeProps): BadgeProps
	return { Title = props.Title, children = props.children }
end)

return { Part = Part, Badge = CustomBadge }
