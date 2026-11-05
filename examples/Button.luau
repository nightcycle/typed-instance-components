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
export type Properties = RobloxComponents.TextButtonProperties & { Label: string, OnActivated: () -> () }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(props: Properties)
	return React.createElement(RobloxComponents.TextButton(
		{
			Text = props.Label,
			[React.Event.Activated] = props.OnActivated,
		},
		props,
		{
			Corner = React.createElement(RobloxComponents.UICorner({ CornerRadius = UDim.new(0, 8) }, {})),
		}
	))
end
