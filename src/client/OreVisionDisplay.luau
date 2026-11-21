local Run = game:GetService("RunService")
local Ores = require(game:GetService("ReplicatedStorage").Shared.Ores)
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local W = require(script.Parent.Widgets)
local Display = {}
Display.__index = Display

function Display.new(gui, location, onToggle, onFilter)
	local self = setmetatable({ pins = {}, options = {} }, Display)
	local safe = location.Parent
	local surface, depth = location:WaitForChild("Surface"), location:WaitForChild("Depth")
	local controls = W.frame(location, "X-ray controls", 0, 0, 172, 30, W.ink)
	controls.BackgroundTransparency = 1
	controls.AnchorPoint = Vector2.new(0.5, 0)
	local toggle = W.button(controls, "Toggle", 0, 0, 82, 30, W.aqua, "X-ray off", "Select")
	local filters = W.button(controls, "Filters", 88, 0, 84, 30, W.muted, "Ore filters", "Select")
	toggle.TextSize, filters.TextSize = 13, 13
	local badge = W.text(location, "", 0, 0, 208, 21, 13, W.white)
	badge.Name, badge.AnchorPoint = "Ore vision status", Vector2.new(0.5, 0)
	W.outlineText(badge, 1.4)
	local function place()
		local row = if surface.Visible then surface else depth
		local bottom = row.Position.Y + row.Size.Y
		controls.Position = UDim2.new(0.5, 0, bottom.Scale, bottom.Offset + 4)
		badge.Position = controls.Position + UDim2.fromOffset(0, 32)
	end
	for _, row in { surface, depth } do
		row:GetPropertyChangedSignal("Position"):Connect(place)
	end
	surface:GetPropertyChangedSignal("Visible"):Connect(place)
	place()
	local panel = W.frame(safe, "X-ray ore filters", 0, 0, 252, 262, W.panel, 12)
	panel.AnchorPoint, panel.Position, panel.ZIndex = Vector2.one * 0.5, UDim2.fromScale(0.5, 0.5), 20
	panel.Visible, panel.Active = false, true
	W.stroke(panel, W.line, 2)
	W.title(panel, "X-ray ores", 12, 5, 150, 32, 19, W.white, true)
	local close = W.closeButton(panel, 213, 6, 30)
	close.Modal = true
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	W.button(panel, "Starfall only", 10, 45, 140, 30, W.violet, "Starfall only", "Select").Activated:Connect(function()
		onFilter(Ores.byName.Starfall.visionBit)
	end)
	W.button(panel, "All", 156, 45, 86, 30, W.aqua, "All ores", "Select").Activated:Connect(function()
		onFilter(Ores.visionMask)
	end)
	local index = 0
	for i = #Ores.list, 1, -1 do
		local ore = Ores.list[i]
		if ore.host then
			continue
		end
		local button = W.button(
			panel,
			ore.name,
			10 + (index % 2) * 118,
			84 + math.floor(index / 2) * 34,
			114,
			30,
			W.card,
			ore.name,
			"Select"
		)
		button.TextSize = 13
		button.Activated:Connect(function()
			onFilter(bit32.bxor(self.mask, ore.visionBit))
		end)
		self.options[ore] = button
		index += 1
	end
	toggle.Activated:Connect(onToggle)
	filters.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	local overlay = W.frame(gui, "Ore waypoints", 0, 0, 0, 0, W.ink)
	overlay.Size, overlay.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	self.overlay, self.panel, self.toggle, self.badge = overlay, panel, toggle, badge
	self.location, self.safe = location, safe
	return self
end

function Display:selection(mask)
	self.mask = mask
	self.primary = nil
	for _, ore in Ores.list do
		if ore.visionBit and bit32.btest(mask, ore.visionBit) then
			self.primary = ore.name
		end
	end
	for ore, button in self.options do
		local on = bit32.btest(mask, ore.visionBit)
		button.Text = if on then "✓ " .. ore.name else ore.name
		button.TextColor3 = if on then ore.color:Lerp(W.white, 0.65) else W.muted
	end
end

function Display:targets(positions)
	for name, pin in self.pins do
		if not positions[name] then
			pin.frame:Destroy()
			self.pins[name] = nil
		end
	end
	for name, at in positions do
		local pin = self.pins[name]
		if not pin then
			local color = Ores.byName[name].color:Lerp(W.white, 0.25)
			local frame = W.frame(self.overlay, name, 0, 0, 148, 50, W.ink)
			frame.AnchorPoint = Vector2.new(0.5, 0.26)
			frame.BackgroundTransparency, frame.Visible = 1, false
			local point = W.title(frame, "◇", 61, 0, 26, 26, 25, color)
			local label = W.text(frame, "", 0, 26, 148, 23, 15, color)
			label.BackgroundColor3, label.BackgroundTransparency = W.ink, 0.15
			W.round(label, 7)
			W.outlineText(point, 2)
			W.outlineText(label, 1.8)
			pin = { frame = frame, point = point, label = label }
			self.pins[name] = pin
		end
		pin.at = at
	end
end

function Display:render(root)
	local camera = workspace.CurrentCamera
	if not camera or not root then
		return
	end
	local size = camera.ViewportSize
	local half, margin = size / 2, Vector2.new(80, math.clamp(size.Y * 0.24, 76, 182))
	local bounds = (half - margin):Max(Vector2.one)
	for name, pin in self.pins do
		local screen = camera:WorldToViewportPoint(pin.at)
		local offset = Vector2.new(screen.X, screen.Y) - half
		local onScreen = screen.Z > 0 and math.abs(offset.X) <= bounds.X and math.abs(offset.Y) <= bounds.Y
		pin.frame.Visible = onScreen or name == self.primary
		if not pin.frame.Visible then
			continue
		end
		local pos = half + offset
		if onScreen then
			pin.point.Text, pin.point.Rotation = "◇", 0
		else
			local relative = camera.CFrame:PointToObjectSpace(pin.at)
			local dir = Vector2.new(relative.X, -relative.Y)
			if dir.Magnitude < 0.001 then
				dir = Vector2.yAxis
			end
			pos = half + dir / math.max(math.abs(dir.X) / bounds.X, math.abs(dir.Y) / bounds.Y)
			pin.point.Text, pin.point.Rotation = "▲", math.deg(math.atan2(dir.Y, dir.X)) + 90
		end
		pin.frame.Position = UDim2.fromOffset(pos.X, pos.Y)
		pin.label.Position = UDim2.fromOffset(0, if not onScreen and pos.Y > half.Y then -24 else 26)
		local distance = math.round((root.Position - pin.at).Magnitude / Config.Cell)
		if distance ~= pin.distance then
			pin.distance = distance
			pin.label.Text = string.format("%s · %d blocks", name, distance)
		end
		if name == self.primary then
			local down = math.round((root.Position.Y - pin.at.Y) / Config.Cell)
			if down ~= pin.down then
				pin.down = down
				self.badge.Text = if down == 0
					then name .. " · same level"
					else string.format(
						"%s · %d blocks %s",
						name,
						math.abs(down),
						if down > 0 then "below" else "above"
					)
			end
		end
	end
end

function Display:enable(on, player)
	self.badge.Visible = on
	self.toggle.Text = if on then "X-ray on" else "X-ray off"
	if self.rendering then
		self.rendering:Disconnect()
	end
	self.overlay.Visible = on
	if on then
		self.rendering = Run.RenderStepped:Connect(function()
			self.overlay.Visible = self.safe.Visible and self.location.Visible and not self.panel.Visible
			if self.overlay.Visible then
				self:render(player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
			end
		end)
	else
		self.panel.Visible = false
	end
end
return Display
