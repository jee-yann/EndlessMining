local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local W = require(script.Parent.Widgets)

local Slider = {}

function Slider.new(menu, row, position, size, tint, choose, nudge, commit)
	local list = menu.list
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.BackgroundTransparency = "Slider", "", 1
	button.Position, button.Size, button.Parent = position, size, row
	button.NextSelectionLeft, button.NextSelectionRight = button, button
	local track = W.frame(button, "Track", 10, 0, 1, 7, W.ink, 4)
	track.AnchorPoint, track.Position = Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0)
	track.Size = UDim2.new(1, -20, 0, 7)
	local fill = W.frame(track, "Fill", 0, 0, 1, 7, tint, 4)
	local knob = W.frame(track, "Thumb", 0, 0, 19, 19, W.white, 10)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	local rim = W.stroke(knob, tint, 3)

	local drag
	local function move(input)
		local x = input.Position.X + Gui:GetInsetArea(Enum.ScreenInsets.None).Min.X - track.AbsolutePosition.X
		choose(math.clamp(x / math.max(1, track.AbsoluteSize.X), 0, 1))
	end
	local function finish()
		if drag then
			drag = nil
			list.ScrollingEnabled = true
			if commit then commit() end
		end
	end
	button.InputBegan:Connect(function(input)
		if not button.Interactable or not list.ScrollingEnabled or not menu.player:GetAttribute("ProfileReady") then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = input
			list.ScrollingEnabled = false
			move(input)
		end
	end)
	local moved = Input.InputChanged:Connect(function(input)
		if drag and (input == drag or (
			drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
		)) then
			move(input)
		end
	end)
	local ended = Input.InputEnded:Connect(function(input)
		if drag and (input == drag or (
			drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == drag.UserInputType
		)) then
			move(input)
			finish()
		end
	end)
	local keyDown = Input.InputBegan:Connect(function(input)
		if Gui.SelectedObject ~= button or not button.Interactable or not menu.overlay.Visible
			or not menu.player:GetAttribute("ProfileReady") then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft then
			nudge(-1)
		elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.DPadRight then
			nudge(1)
		else
			return
		end
		if commit then commit() end
	end)
	local focus = Input.WindowFocusReleased:Connect(finish)
	local visibility = menu.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		if not menu.overlay.Visible then finish() end
	end)
	row.Destroying:Connect(function()
		finish()
		moved:Disconnect()
		ended:Disconnect()
		keyDown:Disconnect()
		focus:Disconnect()
		visibility:Disconnect()
	end)
	return function(fraction, enabled)
		button.Interactable, button.Selectable = enabled, enabled
		if not enabled then finish() end
		fill.Size, knob.Position = UDim2.fromScale(fraction, 1), UDim2.fromScale(fraction, 0.5)
		knob.BackgroundColor3 = if enabled then W.white else W.muted
		fill.BackgroundColor3 = if enabled then tint else W.line
		rim.Color = if enabled then tint else W.line
	end
end

return Slider
