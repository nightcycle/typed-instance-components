--!strict
-- Packages
local Packages = script.Parent.Parent.Packages
local React = require(Packages.React)
local ReactRoblox = require(script.Parent.Parent.Parent.ServerStorage.DevPackages.ReactRoblox)
local C = require(Packages.TypedInstanceComponents)
-- Modules
local Custom = require(script.Parent.Parent.Examples.Custom)
local CachedButton = require(script.Parent.Parent.Examples.Cached)
-- Types
-- Constants
-- References
local Frame = C.Frame
-- Global Variables
-- Private Functions
-- Class
return function()
	assert(C.Frame == Frame and #Packages.TypedInstanceComponents:GetChildren() == 0)
	local container = Instance.new("Folder")
	local root = ReactRoblox.createRoot(container)
	local ref = React.createRef()
	local text, updateText = React.createBinding("Initial")
	local changes = 0
	local ok, problem = pcall(function()
		ReactRoblox.act(function()
			-- Bindings are a React runtime value; generated property records stay plain.
			root:render(React.createElement(C.TextLabel({
				Name = "Root",
				Text = text :: any,
				ref = ref,
				[React.Change.Text] = function()
					changes += 1
				end,
			}, {}, { Corner = React.createElement(C.UICorner({ CornerRadius = UDim.new(0, 7) }, {})) })))
		end)
		local label = assert(container:FindFirstChild("Root")) :: TextLabel
		assert(label.Text == "Initial" and ref.current == label)
		assert((label:FindFirstChild("Corner") :: UICorner).CornerRadius == UDim.new(0, 7))
		ReactRoblox.act(function()
			updateText("Updated")
		end)
		assert((label.Text :: string) == "Updated" and changes > 0)
		ReactRoblox.act(function()
			root:render(React.createElement(Custom.Badge({ Title = "Custom" }, {})))
		end)
		assert((container:FindFirstChildWhichIsA("TextLabel") :: TextLabel).Text == "Custom")
		local child: React.ReactNode = React.createElement(C.UICorner({ Name = "ForwardedChild" }, {}))
		ReactRoblox.act(function()
			root:render(React.createElement(Custom.Badge({}, {}, { Child = child })))
		end)
		assert(assert(container:FindFirstChildWhichIsA("TextLabel")):FindFirstChild("ForwardedChild"))
		ReactRoblox.act(function()
			root:render(React.createElement(C.Frame({}, {}, { Child = child })))
		end)
		assert(assert(container:FindFirstChildWhichIsA("Frame")):FindFirstChild("ForwardedChild"))
		ReactRoblox.act(function()
			root:render(React.createElement(Frame({}, { children = { Child = child } }, false)))
		end)
		assert(#assert(container:FindFirstChildWhichIsA("Frame")):GetChildren() == 0)
		ReactRoblox.act(function()
			root:render(React.createElement(CachedButton, { Label = "Cached", OnActivated = function() end }))
		end)
		local button = assert(container:FindFirstChildWhichIsA("TextButton"))
		assert(button.Text == "Cached" and button:FindFirstChildWhichIsA("UICorner") ~= nil)
		ReactRoblox.act(function()
			root:render(React.createElement(Custom.Part({ Anchored = true }, { Color = Color3.new(1, 0, 0) })))
		end)
		local part = container:FindFirstChildWhichIsA("Part") :: Part
		assert(part.Anchored and part.Color == Color3.new(1, 0, 0))
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	assert(ref.current == nil and #container:GetChildren() == 0)
	container:Destroy()
	assert(ok, tostring(problem))
	return "ReactRoblox mount, binding update, change event, ref, children, Custom and cleanup passed."
end
