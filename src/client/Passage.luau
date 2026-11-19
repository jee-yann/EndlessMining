local TweenService = game:GetService("TweenService")
local W = require(script.Parent.Widgets)
local Passage = {}
Passage.__index = Passage

function Passage.new(player, net)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ResetOnSpawn, gui.ScreenInsets = "SurfaceReturn", 30, false, Enum.ScreenInsets.None
	gui.Enabled, gui.Parent = false, player.PlayerGui
	local shade = Instance.new("CanvasGroup")
	shade.Name, shade.BackgroundColor3, shade.BorderSizePixel = "Blackout", Color3.new(), 0
	shade.Size, shade.Active, shade.Parent = UDim2.fromScale(1, 1), true, gui
	local title = W.title(shade, "Back to daylight", 0, 0, 320, 44, 31, W.white)
	W.anchor(title, 0.5, 1, UDim2.fromScale(0.5, 0.5))
	local detail = W.text(shade, "", 0, 0, 320, 24, 17, W.gold)
	W.anchor(detail, 0.5, 0, UDim2.fromScale(0.5, 0.5))
	return setmetatable({ gui = gui, shade = shade, detail = detail, net = net, player = player }, Passage)
end

function Passage:fade(transparency, duration)
	local tween = TweenService:Create(
		self.shade,
		TweenInfo.new(duration, Enum.EasingStyle.Sine),
		{ GroupTransparency = transparency }
	)
	tween:Play()
	tween.Completed:Wait()
end

function Passage:depart(id, depth)
	if self.active then
		return
	end
	self.active, self.arrived = id, false
	self.detail.Text = if depth > 0
		then string.format("%d %s to the surface", depth, if depth == 1 then "block" else "blocks")
		else "Mine entrance"
	self.shade.GroupTransparency, self.gui.Enabled = 1, true
	self:fade(0, 0.23)
	if workspace.StreamingEnabled then
		pcall(self.player.RequestStreamAroundAsync, self.player, self.net:GetAttribute("Entrance"), 2)
	end
	self.net.Action:FireServer("ReturnReady", id)
	local blackAt = os.clock()
	local hold = 0.22 + math.min(depth, 288) * 0.0065
	repeat
		task.wait()
		local root = self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
		local outside = root and (root.Position - self.net:GetAttribute("Entrance")).Magnitude < 10
	until (self.arrived and outside and os.clock() - blackAt >= hold) or os.clock() - blackAt > 4.5
	self:fade(1, 0.28)
	self.gui.Enabled, self.active = false, nil
end

function Passage:arrive(id)
	if self.active == id then
		self.arrived = true
	end
end
return Passage
