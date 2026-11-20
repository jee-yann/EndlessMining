local Input = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Guide, Expeditions = require(Shared.FieldGuide), require(Shared.Expeditions)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Map = {}
Map.__index = Map

local branches = {
	Reach = { color = W.orange, icon = "Power" },
	Stride = { color = W.green, icon = "Speed" },
	Lamp = { color = W.aqua, icon = "Lamp" },
}
local emblems = { ReachII = "Hook", Spring = "Spring", Lantern = "Beacon", Tempo = "Tempo", Scout = "Boot" }
local function branchOf(node)
	while node.parent do
		node = Guide.byId[node.parent]
	end
	return branches[node.id]
end
local function clear(parent, name, x, y, w, h)
	local f = W.frame(parent, name, x, y, w, h, W.ink)
	f.BackgroundTransparency = 1
	return f
end

function Map.new(parent, player, net, close)
	local self = setmetatable({ player = player, net = net, nodes = {}, pan = Vector2.zero, zoom = 1 }, Map)
	local screen = W.frame(parent, "Skill map", 0, 0, 1, 1, Color3.fromRGB(19, 27, 43))
	screen.Size, screen.Visible, screen.Active = UDim2.fromScale(1, 1), false, true
	W.gradient(screen, Color3.fromRGB(255, 255, 255), Color3.fromRGB(122, 146, 178), 55)
	self.screen = screen
	local view = clear(screen, "Map viewport", 0, 65, 1, 1)
	view.Size, view.ClipsDescendants, view.Active = UDim2.new(1, 0, 1, -65), true, true
	self.view = view
	local canvas = clear(view, "Branches", 0, 0, 1, 1)
	self.canvas, self.scale = canvas, W.scale(canvas)
	self.extent = Vector2.zero
	for _, node in Guide.skills do
		self.extent = Vector2.new(math.max(self.extent.X, math.abs(node.x)), math.max(self.extent.Y, math.abs(node.y)))
	end
	-- Survey grid moves with the branches so dragging keeps a visible frame of reference.
	local grid = clear(canvas, "Survey grid", 0, 0, 1, 1)
	local spanX, spanY = self.extent.X + 1100, self.extent.Y + 800
	for x = -math.floor(spanX / 80), math.floor(spanX / 80) do
		W.frame(grid, "Easting", x * 80, -spanY, 1, spanY * 2, W.line).BackgroundTransparency = 0.83
	end
	for y = -math.floor(spanY / 80), math.floor(spanY / 80) do
		W.frame(grid, "Northing", -spanX, y * 80, spanX * 2, 1, W.line).BackgroundTransparency = 0.83
	end
	local function diamond(parent, name, x, y, size, color)
		local f = W.frame(parent, name, x, y, size, size, color, 5)
		W.anchor(f, 0.5, 0.5, UDim2.fromOffset(x, y))
		f.Rotation = 45
		return f
	end
	for _, node in Guide.skills do
		local upstream = Guide.byId[node.parent or ""]
		local a = if upstream then Vector2.new(upstream.x, upstream.y) else Vector2.zero
		local b = Vector2.new(node.x, node.y)
		local delta, mid = b - a, (a + b) / 2
		local line = W.frame(canvas, "Path to " .. node.id, 0, 0, delta.Magnitude, 4, W.line, 2)
		W.anchor(line, 0.5, 0.5, UDim2.fromOffset(mid.X, mid.Y))
		line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		self.nodes[node.id] = { node = node, line = line, style = branchOf(node) }
	end
	local origin = diamond(canvas, "Prospector", 0, 0, 69, W.gold)
	W.stroke(origin, W.ink, 4)
	local center = diamond(canvas, "Keystone", 0, 0, 59, W.ocean)
	W.enamel(center, W.ocean, W.ink)
	Icons.draw(canvas, "Power", -22, -22, 44)
	W.outlineText(W.title(canvas, "Prospector", -70, 52, 140, 23, 17, W.gold), 2)
	for _, node in Guide.skills do
		local item = self.nodes[node.id]
		local b = W.clearButton(canvas, node.id, node.x - 42, node.y - 42, 84, 84, "Select")
		item.button = b
		local base = diamond(b, "Gem setting", 42, 44, 54, W.ink)
		W.stroke(base, W.ink, 3)
		item.rim = W.stroke(diamond(b, "Bezel", 42, 41, 54, W.panel), W.line, 2)
		item.face = diamond(b, "Enamel", 42, 41, 44, W.card)
		W.gradient(item.face, W.white, Color3.fromRGB(158, 153, 192), 66)
		Icons.draw(b, emblems[node.id] or item.style.icon, 25, 23, 34, item.style.color)
		local title = W.title(b, node.name, -25, 79, 134, 23, 16, W.white)
		W.outlineText(title, 1.8)
		item.mark = W.title(b, "", 57, 51, 22, 22, 18, W.green)
		W.outlineText(item.mark, 2)
		b.Activated:Connect(function()
			if os.clock() >= (self.suppressClickUntil or 0) then
				self:select(node.id)
			end
		end)
		b.SelectionGained:Connect(function()
			if Input.PreferredInput == Enum.PreferredInput.Gamepad then
				self.pan = -Vector2.new(node.x, node.y) * self.scale.Scale
				self:position()
				self:select(node.id)
			end
		end)
	end
	local header = W.frame(screen, "Map header", 0, 0, 1, 65, W.panel)
	header.Size = UDim2.new(1, 0, 0, 65)
	W.enamel(header, W.panel, W.ink)
	W.frame(header, "Seam", 0, 63, 1, 2, W.aqua).Size = UDim2.new(1, 0, 0, 2)
	self.heading = W.title(header, "Skill tree", 16, 1, 160, 34, 28, W.white, true)
	self.summary = W.text(header, "", 17, 35, 350, 21, 15, W.aqua, true)
	self.summary.Name = "Summary"
	self.summary.TextScaled = true
	local font = Instance.new("UITextSizeConstraint")
	font.MinTextSize, font.MaxTextSize, font.Parent = 10, 17, self.summary
	local home = W.button(header, "Recenter", 0, 10, 78, 44, W.aqua, "Center", "Select")
	home.Position = UDim2.new(1, -138, 0, 10)
	home.Activated:Connect(function()
		self:home()
	end)
	local exit = W.button(header, "Close", 0, 10, 44, 44, W.white, "×", "Close")
	exit.Position, exit.TextSize = UDim2.new(1, -52, 0, 10), 26
	exit.Activated:Connect(close)
	local footer = W.frame(screen, "Skill details", 0, 0, 420, 62, W.panel, 10)
	W.anchor(footer, 0.5, 1, UDim2.new(0.5, 0, 1, -6))
	W.stroke(footer, W.line, 1.5)
	self.footer = footer
	self.footerScale = W.scale(footer)
	self.title = W.title(footer, "", 12, 4, 250, 26, 19, W.gold, true)
	self.detail = W.text(footer, "", 12, 30, 250, 27, 14, W.white, true)
	self.detail.TextWrapped = true
	self.learn = W.button(footer, "Learn", 0, 9, 114, 44, W.green, "", "Select")
	self.learn.Position = UDim2.new(1, -122, 0, 9)
	self.learn.Activated:Connect(function()
		if self.selected then
			net.Action:FireServer("Skill", self.selected)
		end
	end)
	local drag, start, initial
	local function inside(pos, box)
		local origin = game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.None).Min
		local d = Vector2.new(pos.X, pos.Y) + origin - box.AbsolutePosition
		return d.X >= 0 and d.Y >= 0 and d.X < box.AbsoluteSize.X and d.Y < box.AbsoluteSize.Y
	end
	Input.InputBegan:Connect(function(input)
		if not screen.Visible or drag or not inside(input.Position, view) or inside(input.Position, footer) then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			drag, start, initial = input, Vector2.new(input.Position.X, input.Position.Y), self.pan
		end
	end)
	Input.InputChanged:Connect(function(input)
		if not screen.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel and inside(input.Position, view) then
			local before = self.zoom
			self.zoom = math.clamp(before * (if input.Position.Z > 0 then 1.12 else 1 / 1.12), 0.65, 1.8)
			self.pan *= self.zoom / before
			self:position()
		elseif
			drag
			and (
				drag == input
				or (
					drag.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement
				)
			)
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - start
			if delta.Magnitude > 6 then
				self.pan = initial + delta
				self.suppressClickUntil = math.huge
				self:position()
			end
		end
	end)
	Input.InputEnded:Connect(function(input)
		if
			input == drag
			or (
				drag
				and drag.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == drag.UserInputType
			)
		then
			drag = nil
			if self.suppressClickUntil == math.huge then
				self.suppressClickUntil = os.clock() + 0.12
			end
		end
	end)
	screen:GetPropertyChangedSignal("Visible"):Connect(function()
		drag = nil
		self.suppressClickUntil = 0
	end)
	view:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if screen.Visible then
			self:position()
		end
	end)
	return self
end

function Map:position()
	local size = self.view.AbsoluteSize
	local scale = math.clamp(math.min(size.X / 800, (size.Y - 95) / 553), 0.73, 1.72) * self.zoom
	self.scale.Scale = scale
	local bounds = self.extent * scale + Vector2.new(75, 95)
	self.pan = Vector2.new(math.clamp(self.pan.X, -bounds.X, bounds.X), math.clamp(self.pan.Y, -bounds.Y, bounds.Y))
	self.canvas.Position = UDim2.new(0.5, self.pan.X, 0.40, self.pan.Y)
	self.footerScale.Scale = math.clamp(size.X / 1080, 1, 1.24)
	local width = math.clamp((size.X - 12) / self.footerScale.Scale, 190, 455)
	self.footer.Size = UDim2.fromOffset(width, 62)
	self.title.Size, self.detail.Size = UDim2.fromOffset(width - 144, 26), UDim2.fromOffset(width - 144, 27)
	self.summary.Size = UDim2.new(1, -163, 0, 23)
end
function Map:home()
	self.zoom, self.pan = 1, Vector2.zero
	self:position()
end
function Map:select(id)
	self.selected = id
	self:refresh()
end
function Map:refresh()
	local p = self.player
	local points, xp = p:GetAttribute("SkillPoints") or 0, p:GetAttribute("MiningXP") or 0
	local level = Expeditions.level(xp)
	local start = Expeditions.levelXP(level)
	self.summary.Text = string.format(
		"%d skill %s   ·   Lv %d   ·   %d / %d XP",
		points,
		if points == 1 then "point" else "points",
		level,
		xp - start,
		Expeditions.levelXP(level + 1) - start
	)
	for id, item in self.nodes do
		local learned = p:GetAttribute("Skill" .. id)
		local ready = not item.node.parent or p:GetAttribute("Skill" .. item.node.parent)
		local color = item.style.color
		item.face.BackgroundColor3 = if learned then color elseif ready then color:Lerp(W.panel, 0.44) else W.card
		item.line.BackgroundColor3 = if learned then color elseif ready then color:Lerp(W.panel, 0.42) else W.line
		item.rim.Color = if self.selected == id then W.white elseif ready then color else W.line
		item.rim.Thickness = if self.selected == id then 4 else 2
		item.mark.Text = if learned then "✓" elseif ready and points > 0 then "+" else ""
		if self.selected == id then
			self.title.Text, self.title.TextColor3 = item.node.name, color
			self.detail.Text = item.node.detail
			self.learn.Visible = true
			self.learn.Interactable = not learned and ready == true and points > 0
			self.learn.Text = if learned
				then "Learned ✓"
				elseif not ready then "Locked"
				elseif points == 0 then "Need 1 point"
				else "Learn · 1 pt"
			self.learn.BackgroundColor3 = if self.learn.Interactable then W.green else W.muted
			if not ready then
				self.detail.Text = item.node.detail .. " · Needs " .. Guide.byId[item.node.parent].name
			end
		end
	end
	if not self.selected then
		self.title.Text, self.title.TextColor3 = "Choose a skill", W.gold
		self.detail.Text, self.learn.Visible = "Drag to explore the branches.", false
	end
end
return Map
