local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local StarterGui = game:GetService("StarterGui")
local Upgrades, Expeditions = require(Shared.Upgrades), require(Shared.Expeditions)
local W, Icons, Menu = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.HarborMenu)
local Audio = require(script.Parent.HarborAudio)
local rarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
local Hud = {}
Hud.__index = Hud
local function card(parent, name, x, y, w, h, top, bottom)
	local f = W.frame(parent, name, x, y, w, h, W.panel, 13)
	W.stroke(f, W.ink, 2)
	W.enamel(f, top or W.ocean, bottom or W.panel)
	local shine = W.frame(f, "Enamel highlight", 11, 2, w - 22, 2, W.white, 1)
	shine.BackgroundTransparency = 0.68
	return f
end
function Hud.new(player, net, mobile)
	local self = setmetatable({ player = player, net = net, mobile = mobile }, Hud)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.ScreenInsets, gui.ZIndexBehavior =
		"MiningHUD", false, Enum.ScreenInsets.CoreUISafeInsets, Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	gui.DisplayOrder = 2
	local backdrop = Instance.new("ScreenGui")
	backdrop.Name, backdrop.ScreenInsets, backdrop.ResetOnSpawn, backdrop.DisplayOrder =
		"HarborShade", Enum.ScreenInsets.None, false, 1
	backdrop.Enabled, backdrop.Parent = false, gui.Parent
	local dim = W.frame(backdrop, "Dim", 0, 0, 1, 1, W.ink)
	dim.Size, dim.BackgroundTransparency, dim.Active = UDim2.fromScale(1, 1), 0.23, true
	local root = W.frame(gui, "SafeArea", 0, 0, 1, 1, W.ink)
	root.Size, root.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	self.root = root
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	local wallet = card(root, "Wallet", 0, 0, 224, 64, Color3.fromRGB(234, 148, 39), Color3.fromRGB(169, 74, 38))
	self.wallet = wallet
	Icons.draw(wallet, "Coins", 9, 7, 48)
	W.text(wallet, "GOLD", 64, 2, 148, 18, 13, W.white, true)
	self.gold = W.title(wallet, "0", 61, 15, 157, 45, 38, W.gold, true)
	self.gold.TextScaled = true
	local goldSize = Instance.new("UITextSizeConstraint")
	goldSize.MinTextSize, goldSize.MaxTextSize, goldSize.Parent = 14, 38, self.gold
	W.outlineText(self.gold)
	self.status = W.text(wallet, "", 0, -18, 224, 16, 12, W.white, true)
	self.status.TextStrokeTransparency = 0.2
	local haul = card(root, "Haul", 0, 0, 215, 79, Color3.fromRGB(57, 117, 126), W.panel)
	self.haul, self.rows = haul, {}
	W.title(haul, "Your haul", 10, 4, 99, 24, 20, W.white, true)
	self.pack = W.text(haul, "", 107, 5, 98, 21, 15, W.white)
	local track = W.frame(haul, "Capacity", 10, 30, 195, 5, W.ink, 3)
	self.fill = W.frame(track, "Ore", 0, 0, 0, 5, W.green, 3)
	self.empty = W.text(haul, "Empty pack", 10, 38, 195, 20, 14, W.muted, true)
	self.haulValue = W.text(haul, "", 10, 58, 195, 18, 13, W.gold, true)
	for _, ore in Ores.list do
		local row = W.frame(haul, ore.name, 10, 38, 195, 20, W.panel)
		row.BackgroundTransparency = 1
		W.text(row, ore.name, 0, 0, 75, 20, 15, ore.color:Lerp(W.white, 0.48), true)
		W.text(row, ore.rarity, 76, 0, 74, 20, 12, W.muted, true)
		local quantity = W.text(row, "", 150, 0, 45, 20, 15, W.white)
		quantity.Name, quantity.TextXAlignment = "Quantity", Enum.TextXAlignment.Right
		self.rows[ore.name] = row
	end
	local details = Instance.new("TextButton")
	details.Name, details.Text, details.BackgroundTransparency = "Haul details", "", 1
	details.Size, details.ZIndex, details.Parent = UDim2.fromScale(1, 1), 2, haul
	Audio.bind(details, "Select")
	details.Activated:Connect(function()
		self:openPage("Pack")
	end)
	local taskCard = card(root, "Current job", 0, 0, 215, 86, Color3.fromRGB(157, 65, 190), Color3.fromRGB(77, 49, 149))
	W.anchor(taskCard, 1, 0, UDim2.new(1, -12, 0, 9))
	Icons.draw(taskCard, "Jobs", 8, 7, 27)
	W.text(taskCard, "SHIFT JOB", 42, 5, 96, 22, 13, W.gold, true)
	local bounty = W.frame(taskCard, "Payout", 136, 7, 70, 21, W.gold, 9)
	self.reward = W.title(bounty, "", 0, 0, 70, 21, 13, W.ink)
	self.job = W.title(taskCard, "", 12, 29, 193, 25, 20, W.white, true)
	self.jobCount = W.text(taskCard, "", 12, 55, 190, 19, 14, W.muted, true)
	local jobTrack = W.frame(taskCard, "Job progress", 12, 76, 190, 5, W.ink, 3)
	self.jobFill = W.frame(jobTrack, "Mined", 0, 0, 0, 5, W.gold, 3)
	self.ribbon = card(taskCard, "Discovery", 0, 88, 215, 52, W.ocean, W.grape)
	self.ribbon.Visible = false
	self.ribbonType = W.text(self.ribbon, "", 12, 4, 192, 17, 12, W.aqua, true)
	self.ribbonName = W.title(self.ribbon, "", 12, 22, 192, 25, 20, W.white, true)
	local jobTap = Instance.new("TextButton")
	jobTap.Name, jobTap.Text, jobTap.AutoButtonColor, jobTap.BackgroundTransparency = "OpenJob", "", false, 1
	jobTap.Size, jobTap.ZIndex, jobTap.Parent = UDim2.fromScale(1, 1), 2, taskCard
	Audio.bind(jobTap, "Job")
	jobTap.Activated:Connect(function()
		self:openPage("Jobs")
	end)
	local loc = card(root, "Location", 0, 0, 211, 93, Color3.fromRGB(19, 142, 153), Color3.fromRGB(24, 68, 119))
	self.layer = W.text(loc, "CITRINE COVE", 10, 3, 186, 19, 13, W.aqua, true)
	self.layer.Name = "Region"
	self.depth = W.title(loc, "Surface", 10, 22, 99, 26, 18, W.white, true)
	self.depth.Name = "Depth"
	self.surface = W.button(loc, "Surface", 113, 22, 85, 27, W.aqua, "↑ Surface", "Select")
	self.surface.TextSize = 14
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	self.coordinates = W.text(loc, "", 10, 50, 191, 20, 15, W.white, true)
	self.coordinates.Name = "Coordinates"
	self.stats = W.text(loc, "", 10, 71, 194, 18, 12, W.muted, true)
	local dock = W.frame(root, "Action dock", 0, 0, 217, 64, W.ink)
	dock.BackgroundTransparency = 1
	self.nav = {}
	local cues = { Settings = "Open", Jobs = "Job", Book = "Open" }
	for i, key in { "Jobs", "Book", "Settings" } do
		local tint = Menu.pages[key].color
		local b = W.button(dock, key, (i - 1) * 74, 0, 69, 61, tint, "", cues[key])
		local badge = W.frame(b, "Medallion", 15, -6, 39, 39, tint:Lerp(W.white, 0.62), 13)
		W.stroke(badge, W.ink, 2)
		local icon = Icons.draw(badge, key, 3, 3, 33, tint)
		icon.Rotation = if i % 2 == 0 then 4 else -4
		self.nav[key] = W.title(b, if key == "Book" then "Index" else key, 1, 33, 67, 25, 18, W.white)
		W.outlineText(self.nav[key])
		if key == "Jobs" then
			self.jobBadge = W.frame(b, "Reward ready", 53, -5, 20, 20, W.pink, 10)
			W.stroke(self.jobBadge, W.ink, 2)
			W.title(self.jobBadge, "!", 0, 0, 20, 20, 15, W.ink)
		end
		b.Activated:Connect(function()
			self:openPage(key)
		end)
	end
	self.mine = W.button(root, "Mine", 0, 0, 98, 46, W.aqua, "Hold mine", "Mine")
	W.anchor(self.mine, 1, 0.5, UDim2.new(1, -12, 0.54, 0))
	self.mine.Visible = mobile
	local speech = card(root, "Feedback", 0, 0, 320, 47)
	self.message = W.title(speech, "", 5, 1, 310, 25, 18, W.white)
	self.detail = W.text(speech, "", 5, 25, 310, 18, 13, W.muted)
	self.speech = speech
	local meter = W.frame(speech, "Mining progress", 10, -14, 300, 10, W.ink, 5)
	W.stroke(meter, W.ink, 2)
	self.swingFill = W.frame(meter, "Charge", 0, 0, 0, 10, W.aqua, 5)
	W.gradient(self.swingFill, W.white, W.gold, 0)
	meter.Visible = false
	self.meter = meter
	local aimGui = Instance.new("ScreenGui")
	aimGui.Name, aimGui.ResetOnSpawn, aimGui.ScreenInsets = "MiningAim", false, Enum.ScreenInsets.None
	aimGui.Parent = gui.Parent
	self.reticle = W.frame(aimGui, "Aim", 0, 0, 8, 8, W.white, 4)
	W.anchor(self.reticle, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.stroke(self.reticle, W.ink, 1.6)
	self.reticle.Visible = false
	local badge = W.frame(aimGui, "Mining cursor", 0, 0, 28, 28, W.ink, 14)
	self.cursor, self.cursorEdge = badge, W.stroke(badge, W.aqua, 2.3)
	self.cursorPick = Icons.draw(badge, "Power", 2, 2, 24, W.gold)
	self.denied = W.frame(badge, "No entry", 4, 12, 20, 4, Color3.fromRGB(255, 100, 108), 2)
	badge.Visible = false
	self.menu = Menu.new(root, player, net, function()
		self:setShop(false)
	end)
	self.overlay = self.menu.overlay
	self.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		local open = self.overlay.Visible
		backdrop.Enabled = open
		self.mine.Visible = self.mobile and not open
		for _, panel in { wallet, haul, taskCard, loc, dock } do
			panel.Visible = not open
		end
		self.speech.Visible = false
		if self.layout then
			self.layout()
		end
	end)
	local walletScale, taskScale, haulScale, locScale, dockScale, speechScale, mineScale =
		W.scale(wallet),
		W.scale(taskCard),
		W.scale(haul),
		W.scale(loc),
		W.scale(dock),
		W.scale(speech),
		W.scale(self.mine)
	self.layout = function()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if width < 2 or height < 2 then
			return
		end
		local s = math.clamp(math.min((width - 26) / 450, height / 480), 0.52, 1.30)
		local portrait = self.mobile and width < height
		local shelf = if portrait then 113 elseif self.mobile then 69 else 12
		local compact = width < 665 * s + 48
		local showJob = height >= 480 or not self.mobile and height >= 400
		taskCard.Visible = showJob and not self.overlay.Visible
		walletScale.Scale, taskScale.Scale, haulScale.Scale, locScale.Scale, dockScale.Scale = s, s, s, s, s
		speechScale.Scale, mineScale.Scale = math.min(s, (width - 20) / 320), math.max(0.82, s)
		self.menu:layout(width, height, self.mobile)
		W.anchor(taskCard, 1, 0, UDim2.new(1, -10, 0, 9))
		W.anchor(haul, 1, 0, UDim2.new(1, -10, 0, if showJob then 16 + 86 * s else 9))
		W.anchor(wallet, 0, 1, UDim2.new(0, 10, 1, -shelf))
		W.anchor(loc, 0, 1, UDim2.new(0, 10, 1, -shelf - 86 * s))
		if compact then
			W.anchor(dock, 1, 1, UDim2.new(1, -10, 1, -shelf))
		else
			W.anchor(dock, 0.5, 1, UDim2.new(0.5, 0, 1, -shelf))
		end
		if compact then
			speechScale.Scale = math.min(s, (width - 218 * s - 25) / 320)
			W.anchor(speech, 1, 1, UDim2.new(1, -10, 1, -shelf - 78 * s))
		else
			W.anchor(speech, 0.5, 1, UDim2.new(0.5, 0, 1, -shelf - 78 * s))
		end
		W.anchor(
			self.mine,
			1,
			1,
			UDim2.new(1, -12, 1, if compact then -shelf - 78 * s - 52 * speechScale.Scale else -shelf)
		)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
	self.layout()
	player.AttributeChanged:Connect(function()
		self:refresh()
	end)
	self:refresh()
	return self
end
function Hud:placePanels(touch)
	self.mobile = touch
	self.layout()
end
function Hud:openPage(key)
	self.menu:open(key)
	self.mine.Visible = self.mobile and not self.overlay.Visible
	self.reticle.Visible = false
end
function Hud:setShop(open)
	if open then
		self:openPage("Gear")
	else
		self.menu:close()
	end
end
function Hud:refresh()
	local p = self.player
	local function level(key)
		return p:GetAttribute(key) or 1
	end
	local used, cap = p:GetAttribute("Used") or 0, Upgrades.items.Capacity.values[level("Capacity")]
	if not self.countingGold then
		self.gold.Text = W.goldAmount(p:GetAttribute("Gold") or 0)
	end
	self.pack.Text = W.number(used) .. " / " .. W.number(cap)
	self.fill.BackgroundColor3 = if used >= cap then W.gold else W.green
	if used ~= self.lastUsed or cap ~= self.lastCap then
		self.lastUsed, self.lastCap = used, cap
		W.tween(self.fill, 0.15, { Size = UDim2.fromScale(used / cap, 1) })
	end
	local held = {}
	for _, ore in Ores.list do
		local amount = p:GetAttribute("Held" .. ore.name) or 0
		local row = self.rows[ore.name]
		row.Visible = amount > 0
		if row.Visible then
			row.Quantity.Text = "×" .. amount
			table.insert(held, { ore = ore, amount = amount, row = row })
		end
	end
	table.sort(held, function(a, b)
		if a.ore.rarity ~= b.ore.rarity then
			return rarityRank[a.ore.rarity] > rarityRank[b.ore.rarity]
		end
		if a.amount ~= b.amount then
			return a.amount > b.amount
		end
		return a.ore.value > b.ore.value
	end)
	for i, entry in held do
		entry.row.Position = UDim2.fromOffset(10, 38 + (i - 1) * 20)
	end
	local visible = #held
	self.empty.Visible = visible == 0
	local footerY = 39 + math.max(1, visible) * 20
	self.haulValue.Position = UDim2.fromOffset(10, footerY)
	self.haulValue.Text = "Sell value   "
		.. W.number((p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1))
		.. " G"
	self.haul.Size = UDim2.fromOffset(215, footerY + 22)
	local status = p:GetAttribute("SaveStatus")
	self.status.Text = if status == "Saving enabled" then "" else status or "Opening pack…"
	local mined, done = p:GetAttribute("Mined") or 0, p:GetAttribute("Jobs") or 0
	local _, rank = Expeditions.rank(mined)
	local job = Expeditions.jobs[done + 1]
	self.jobFill.Size = UDim2.fromScale(if job then math.clamp(mined / job.goal, 0, 1) else 1, 1)
	self.job.Text = if job then job.title else rank.name
	self.reward.Text = if job then "+" .. W.number(job.reward) .. " G" else "All done"
	self.jobCount.Text = if job and mined >= job.goal
		then "Claim reward  ›"
		elseif job then string.format("%d / %d blocks mined", mined, job.goal)
		else W.number(mined) .. " blocks mined"
	self.jobCount.TextColor3 = if job and mined >= job.goal then W.green else W.muted
	self.jobBadge.Visible = job ~= nil and mined >= job.goal
	self.stats.Text = string.format(
		"%s  ·  Power %d  ·  %.2fs",
		rank.name,
		level("Power"),
		Upgrades.items.Speed.values[level("Speed")]
	)
	self.menu:refresh()
end
function Hud:aimAt(screen, valid, locked)
	self.cursor.Visible = screen ~= nil and (valid or locked ~= nil) and not self.overlay.Visible
	if not self.cursor.Visible then
		return
	end
	self.cursor.Position = UDim2.fromOffset(screen.X + 12, screen.Y + 10)
	self.cursorPick.Visible, self.denied.Visible = valid, not valid
	self.cursorEdge.Color = if valid then W.aqua else self.denied.BackgroundColor3
	if not self.meter.Visible then
		self.cursorPick.Rotation = 0
	end
end
function Hud:milestone(kind, name, color)
	local serial = (self.ribbonSerial or 0) + 1
	self.ribbonSerial = serial
	self.ribbonType.Text, self.ribbonType.TextColor3, self.ribbonName.Text = kind, color:Lerp(W.white, 0.36), name
	self.ribbon.Visible = true
	local y = 94 + self.haul.Size.Y.Offset
	self.ribbon.Position = UDim2.fromOffset(18, y)
	W.tween(self.ribbon, 0.2, { Position = UDim2.fromOffset(0, y) })
	task.delay(3.4, function()
		if self.ribbonSerial == serial then
			self.ribbon.Visible = false
		end
	end)
end
function Hud:notice(title, detail, color)
	self.untilTime = os.clock() + 2.1
	self.message.Text, self.message.TextColor3, self.detail.Text = title, color or W.white, detail or ""
	if self.overlay.Visible then
		self.menu.status.Text = title
	end
	self.speech.Visible = not self.overlay.Visible
	self.message.TextTransparency = 0.35
	W.tween(self.message, 0.16, { TextTransparency = 0 })
end
function Hud:guide(title, detail, visible)
	if os.clock() < (self.untilTime or 0) then
		return
	end
	self.speech.Visible = visible
	self.message.Text, self.message.TextColor3, self.detail.Text = title, W.white, detail
end
return Hud
