local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local Preferences = require(game:GetService("ReplicatedStorage").Shared.Preferences)
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Settings = {}
Settings.__index = Settings

function Settings.new(player, net)
	local self = setmetatable({ values = table.clone(Preferences.defaults), player = player, net = net }, Settings)
	local function load()
		if not player:GetAttribute("ProfileReady") then
			return
		end
		for key in Preferences.defaults do
			local value = player:GetAttribute(key)
			if Preferences.valid(key, value) then
				self.values[key] = value
			end
		end
		Audio.volume("MusicVolume", self.values.MusicVolume)
		Audio.volume("SfxVolume", self.values.SfxVolume)
	end
	player:GetAttributeChangedSignal("ProfileReady"):Connect(load)
	load()
	return self
end

function Settings:slider(menu, i, key, title, tint)
	local row = W.frame(menu.list, title, 1, 1 + (i - 1) * 69, 447, 62, W.card, 10)
	W.enamel(row, tint:Lerp(W.panel, 0.68), W.panel)
	W.title(row, title, 14, 1, 280, 26, 19, W.white, true)
	local percent = W.title(row, "", 366, 2, 66, 24, 17, tint)
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.BackgroundTransparency = "Slider", "", 1
	button.Position, button.Size, button.Parent = UDim2.fromOffset(8, 24), UDim2.fromOffset(428, 36), row
	button.NextSelectionLeft, button.NextSelectionRight = button, button
	local track = W.frame(button, "Track", 10, 15, 408, 7, W.ink, 4)
	local fill = W.frame(track, "Volume", 0, 0, 1, 7, tint, 4)
	local knob = W.frame(track, "Thumb", 0, 0, 19, 19, W.white, 10)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	W.stroke(knob, tint, 3)
	local function draw()
		local value = self.values[key]
		fill.Size, knob.Position = UDim2.fromScale(value / 100, 1), UDim2.fromScale(value / 100, 0.5)
		percent.Text = value .. "%"
	end
	table.insert(menu.updates, draw)
	local function change(value)
		self.values[key] = math.clamp(math.round(value), 0, 100)
		Audio.volume(key, self.values[key])
		draw()
	end
	local function commit()
		self.net.Action:FireServer("Preference", key, self.values[key])
		if key == "SfxVolume" then
			Audio.preview()
		end
	end
	local drag
	local function move(input)
		change((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X) * 100)
	end
	local function finish()
		if not drag then
			return
		end
		drag = nil
		menu.list.ScrollingEnabled = true
		commit()
	end
	button.InputBegan:Connect(function(input)
		if not self.player:GetAttribute("ProfileReady") or drag then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			drag = input
			menu.list.ScrollingEnabled = false
			move(input)
		end
	end)
	local moved = Input.InputChanged:Connect(function(input)
		if
			drag
			and (
				input == drag
				or (
					drag.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement
				)
			)
		then
			move(input)
		end
	end)
	local ended = Input.InputEnded:Connect(function(input)
		if
			drag
			and (
				input == drag
				or (drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == drag.UserInputType)
			)
		then
			move(input)
			finish()
		end
	end)
	local keyDown = Input.InputBegan:Connect(function(input)
		if not menu.overlay.Visible or Gui.SelectedObject ~= button or not self.player:GetAttribute("ProfileReady") then
			return
		end
		local code = input.KeyCode
		if code == Enum.KeyCode.Left or code == Enum.KeyCode.DPadLeft then
			change(self.values[key] - 5)
			commit()
		elseif code == Enum.KeyCode.Right or code == Enum.KeyCode.DPadRight then
			change(self.values[key] + 5)
			commit()
		end
	end)
	local focus = Input.WindowFocusReleased:Connect(finish)
	row.Destroying:Connect(function()
		finish()
		moved:Disconnect()
		ended:Disconnect()
		keyDown:Disconnect()
		focus:Disconnect()
	end)
end

function Settings:build(menu)
	self:slider(menu, 1, "MusicVolume", "Music volume", W.aqua)
	self:slider(menu, 2, "SfxVolume", "Sound effects", W.gold)
	local _, detail, button = menu:row(3, "Menu animations", "Settings", W.violet)
	detail.Text = "Slide panels in and out"
	table.insert(menu.updates, function()
		button.Text = if self.values.MenuMotion then "On" else "Off"
		button.Interactable = self.player:GetAttribute("ProfileReady") == true
	end)
	button.Activated:Connect(function()
		self.values.MenuMotion = not self.values.MenuMotion
		menu:refresh()
		self.net.Action:FireServer("Preference", "MenuMotion", self.values.MenuMotion)
	end)
	return 3
end
return Settings
