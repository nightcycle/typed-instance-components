--!strict
-- Packages
local Packages = script.Parent.Parent.Packages
local React = require(Packages.React)
local RobloxComponents = require(Packages.TypedInstanceComponents)
-- Modules
-- Components
local TextButton = RobloxComponents.TextButton
local UICorner = RobloxComponents.UICorner
-- Contexts
-- Hooks
-- Types
export type Properties = RobloxComponents.TextButtonProperties & { Label: string, OnActivated: () -> () }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(props: Properties)
	return React.createElement(TextButton(
		{
			Text = props.Label,
			[React.Event.Activated] = props.OnActivated,
		},
		props,
		{
			Corner = React.createElement(UICorner({ CornerRadius = UDim.new(0, 8) }, {})),
		}
	))
end
