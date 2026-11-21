local W = require(script.Parent.Widgets)
local Icons = require(script.Parent.Icons)
local Audio = require(script.Parent.HarborAudio)

local TouchActions = {}
TouchActions.__index = TouchActions

function TouchActions.new(root)
	local self = setmetatable({}, TouchActions)
	self.hold = W.clearButton(root, "Mine", 0, 0, 112, 64, "Mine")
	Icons.draw(self.hold, "Power", 38, 0, 36, W.gold)
	self.label = W.title(self.hold, "", 0, 32, 112, 18, 15, W.white)
	self.hint = W.text(self.hold, "", 0, 49, 112, 15, 12, W.white)
	self.label.Name, self.hint.Name = "Mining mode", "Gesture hint"
	W.outlineText(self.label, 1.8)
	W.outlineText(self.hint, 1.4)
	self:setAuto(false)
	return self
end

function TouchActions:setAuto(enabled)
	self.enabled = enabled
	self.label.Text = if enabled then "Auto mine ON" else "Hold to mine"
	self.label.TextColor3 = if enabled then W.green else W.white
	self.hint.Text = if enabled then "Double-tap to stop" else "Double-tap for auto"
end

-- Draw on the native button so Roblox still handles jump, hold, respawn and
-- the player's control layout. All artwork is passive inside its hit target.
function TouchActions.skinJump(jump)
	if jump:FindFirstChild("Miner jump") then
		return
	end
	local art = W.frame(jump, "Miner jump", 0, 0, 64, 64, W.ink, 32)
	W.anchor(art, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	art.ZIndex = jump.ZIndex + 1
	local scale = W.scale(art)
	local face = W.frame(art, "Teal enamel", 3, 2, 58, 57, W.ocean, 29)
	W.enamel(face, Color3.fromRGB(61, 163, 162), Color3.fromRGB(36, 69, 88))
	local rim = W.stroke(face, Color3.fromRGB(128, 204, 183), 1.5)
	for _, x in { 6, 48 } do
		local rivet = W.frame(face, "Brass rivet", x, 27, 4, 4, W.gold, 2)
		W.stroke(rivet, W.ink, 1)
	end
	for i, angle in { -42, 42 } do
		local x = if i == 1 then 11 else 26
		local edge = W.frame(face, "Arrow edge", x, 18, 21, 9, W.ink, 3)
		edge.Rotation = angle
		local light = W.frame(face, "Arrow", x + 1, 17, 20, 7, W.gold, 2)
		light.Rotation = angle
	end
	W.outlineText(W.title(face, "JUMP", 4, 34, 50, 17, 13, W.white), 1.4)
	face.ZIndex = art.ZIndex + 1
	for _, detail in face:GetChildren() do
		if detail:IsA("GuiObject") then
			detail.ZIndex = face.ZIndex + 1
		end
	end
	local function paint()
		local pressed = jump.GuiState == Enum.GuiState.Press
		local compress = pressed and game.Players.LocalPlayer:GetAttribute("MenuMotion") ~= false
		scale.Scale = math.min(jump.AbsoluteSize.X, jump.AbsoluteSize.Y) / 64 * (if compress then 0.9 else 0.96)
		rim.Color = if pressed then W.gold else Color3.fromRGB(128, 204, 183)
	end
	jump.ImageTransparency = 1
	jump:GetPropertyChangedSignal("GuiState"):Connect(paint)
	jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint)
	Audio.bind(jump, "Select")
	paint()
end

function TouchActions:layout(root, jump, visible, toolsBottom)
	self.hold.Visible = visible
	if not visible then
		return
	end
	local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local size = if jump then jump.AbsoluteSize else Vector2.new(70, 70)
	local pos = if jump then jump.AbsolutePosition - root.AbsolutePosition else Vector2.new(width - 88, height - 90)
	local extent = Vector2.new(self.hold.Size.X.Offset, self.hold.Size.Y.Offset)
	local x, y = pos.X + (size.X - extent.X) / 2, pos.Y - extent.Y - 8
	if y < toolsBottom then
		x = if pos.X >= extent.X + 8 then pos.X - extent.X - 8 else pos.X + size.X + 8
		y = pos.Y + (size.Y - extent.Y) / 2
	end
	local corner = Vector2.new(math.clamp(x, 0, math.max(0, width - extent.X)), math.clamp(y, 0, height - extent.Y))
	W.anchor(self.hold, 0.5, 0.5, UDim2.fromOffset(corner.X + extent.X / 2, corner.Y + extent.Y / 2))
	local bounds = { Rect.new(pos, pos + size), Rect.new(corner, corner + extent) }
	table.sort(bounds, function(a, b)
		return a.Min.Y > b.Min.Y
	end)
	return bounds
end

function TouchActions.feedbackPosition(screen, size, footer, bounds)
	local x, y = screen.X / 2, screen.Y - footer
	if bounds then
		local left = screen.X
		for _, box in bounds do
			if box.Min.Y < y + 6 and box.Max.Y > y - size.Y - 6 then
				left = math.min(left, box.Min.X - 8)
			end
		end
		if screen.X >= screen.Y and left - size.X >= 100 then
			x = math.min(x, left - size.X / 2)
		else
			for _, box in bounds do
				if
					x + size.X / 2 > box.Min.X - 6
					and x - size.X / 2 < box.Max.X + 6
					and y > box.Min.Y - 6
					and y - size.Y < box.Max.Y + 6
				then
					y = box.Min.Y - 7
				end
			end
		end
	end
	return UDim2.new(0.5, x - screen.X / 2, 1, y - screen.Y)
end

return TouchActions
