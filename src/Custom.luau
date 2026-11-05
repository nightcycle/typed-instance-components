--!strict
-- Packages
local React = require(script.Parent.Parent.React)
-- Modules
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
-- The typed projector is the schema for a class/component unknown to the generator.
return function<P, C>(component: C, project: (props: P) -> P): (P, P, React.ReactNode?) -> (C, P, React.ReactNode?)
	assert(
		type(component) == "string" or type(component) == "function" or type(component) == "table",
		"Invalid component"
	)
	return function(defaults: P, props: P, children: React.ReactNode?): (C, P, React.ReactNode?)
		local result: { [any]: any } = table.clone(project(props) :: any)
		for name, value in defaults :: any do
			result[name] = value
		end
		return component, result :: any, children
	end
end
