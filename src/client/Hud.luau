local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local StarterGui = game:GetService("StarterGui")
local Upgrades, Expeditions = require(Shared.Upgrades), require(Shared.Expeditions)
local W, Icons, Menu = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.HarborMenu)
local Audio = require(script.Parent.HarborAudio)
local Roster = require(script.Parent.MinerRoster)
local Celebration = require(script.Parent.UnlockCelebration)
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
	local wallet = W.frame(root, "Wallet", 0, 0, 154, 65, W.ink, 10)
	wallet.BackgroundTransparency = 0.18
	self.wallet = wallet
	Icons.draw(wallet, "Coins", 3, 2, 28)
	self.gold = W.title(wallet, "0", 34, 0, 114, 29, 24, W.gold, true)
	self.gold.TextScaled = true
	local goldSize = Instance.new("UITextSizeConstraint")
	goldSize.MinTextSize, goldSize.MaxTextSize, goldSize.Parent = 13, 24, self.gold
	W.outlineText(self.gold)
	local xpStrip = W.frame(wallet, "Level progress", 5, 27, 144, 20, W.ink)
	xpStrip.BackgroundTransparency = 1
	self.levelLabel = W.title(xpStrip, "", 0, 0, 49, 15, 13, W.aqua, true)
	self.xpLabel = W.text(xpStrip, "", 49, 0, 95, 15, 12, W.white)
	self.xpLabel.TextXAlignment = Enum.TextXAlignment.Right
	local xpTrack = W.frame(xpStrip, "XP track", 0, 16, 144, 3, W.card, 2)
	self.xpFill = W.frame(xpTrack, "XP fill", 0, 0, 0, 3, W.aqua, 2)
	W.gradient(self.xpFill, W.green, W.aqua, 0)
	self.status = W.text(wallet, "", 2, 65, 154, 16, 11, W.white, true)
	W.outlineText(self.status)
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
		W.text(row, "", 76, 0, 77, 20, 12, W.gold, true).Name = "UnitValue"
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
	local loc = W.frame(root, "Location", 0, 0, 186, 40, W.ink, 10)
	loc.BackgroundTransparency = 0.22
	self.layer = W.title(loc, "CITRINE COVE", 5, 1, 119, 21, 14, W.gold, true)
	self.layer.Name = "Region"
	self.layer.TextScaled = true
	local regionFont = Instance.new("UITextSizeConstraint")
	regionFont.MinTextSize, regionFont.MaxTextSize, regionFont.Parent = 10, 14, self.layer
	self.depth = W.text(loc, "Surface", 124, 2, 57, 19, 12, W.white)
	self.depth.Name = "Depth"
	self.depth.TextXAlignment = Enum.TextXAlignment.Right
	self.coordinates = W.text(loc, "", 5, 20, 176, 18, 12, W.muted)
	self.coordinates.Name = "Coordinates"
	self.surface = W.button(loc, "Surface", 0, 0, 94, 44, W.gold, "↑ Surface", "Select")
	W.anchor(self.surface, 1, 0, UDim2.new(1, 0, 1, 4))
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	local gear = W.frame(wallet, "Equipment", 3, 47, 148, 18, W.ink)
	gear.BackgroundTransparency = 1
	self.gearChips = {}
	for i, key in { "Power", "Speed", "Capacity" } do
		local chip = W.frame(gear, key, (i - 1) * 50, 0, 49, 18, W.ink)
		chip.BackgroundTransparency = 1
		self.gearChips[key] = W.text(chip, "", 0, 0, 49, 18, 12, Upgrades.items[key].color:Lerp(W.white, 0.36))
	end
	local dockWidth = 389
	local dock = W.frame(root, "Action dock", 0, 0, dockWidth, 64, W.ink)
	dock.BackgroundTransparency = 1
	self.nav = {}
	local cues = { Settings = "Open", Jobs = "Job", Book = "Open" }
	local navX = 0
	for i, key in { "Inventory", "Skills", "Achievements", "Book", "Settings" } do
		local tint = Menu.pages[key].color
		local width = if key == "Achievements" then 93 else 69
		local b = W.button(dock, key, navX, 0, width, 61, tint, "", cues[key])
		navX += width + 5
		local badge = W.frame(b, "Medallion", (width - 39) / 2, -6, 39, 39, tint:Lerp(W.white, 0.62), 13)
		W.stroke(badge, W.ink, 2)
		local icon = Icons.draw(badge, if key == "Inventory" then "Pack" else key, 3, 3, 33, tint)
		icon.Rotation = if i % 2 == 0 then 4 else -4
		self.nav[key] = W.title(b, if key == "Book" then "Index" else key, 1, 33, width - 2, 25, 18, W.white)
		if key == "Inventory" or key == "Achievements" then
			self.nav[key].TextSize = 14
		end
		W.outlineText(self.nav[key])
		if key == "Skills" then
			self.jobBadge = W.frame(b, "Reward ready", 53, -5, 20, 20, W.pink, 10)
			W.stroke(self.jobBadge, W.ink, 2)
			W.title(self.jobBadge, "!", 0, 0, 20, 20, 15, W.ink)
		end
		b.Activated:Connect(function()
			self:openPage(key)
		end)
	end
	local shortcuts = W.frame(root, "Edge shortcuts", 0, 0, 76, 100, W.ink)
	shortcuts.BackgroundTransparency = 1
	local function shortcut(key, tint, caption)
		local button = W.button(shortcuts, key, 0, 0, 76, 47, W.panel, "", "Select")
		Icons.draw(button, key, 2, 9, 27, tint)
		W.title(button, caption, 29, if key == "Menu" then 11 else 3, 46, 24, 14, tint, true)
		button.Activated:Connect(function()
			self:openPage(key)
		end)
		return button
	end
	local packButton = shortcut("Pack", W.gold, "Pack")
	self.edgeCount = W.text(packButton, "", 27, 25, 46, 17, 11, W.white, true)
	self.edgeCount.TextScaled = true
	local countSize = Instance.new("UITextSizeConstraint")
	countSize.MinTextSize, countSize.MaxTextSize, countSize.Parent = 9, 12, self.edgeCount
	local menuButton = shortcut("Menu", W.aqua, "Menu")
	self.edgeAlert = W.frame(menuButton, "Available reward", 65, 3, 8, 8, W.pink, 4)
	self.mine = W.button(root, "Mine", 0, 0, 62, 54, W.aqua, "", "Mine")
	Icons.draw(self.mine, "Power", 17, 1, 28, W.gold)
	W.title(self.mine, "Hold mine", 0, 29, 62, 20, 12, W.ink)
	local speech = card(root, "Feedback", 0, 0, 320, 47)
	self.message = W.title(speech, "", 5, 1, 310, 25, 18, W.white)
	self.detail = W.text(speech, "", 5, 25, 310, 18, 13, W.muted)
	self.speech = speech
	for _, label in { self.message, self.detail } do
		local size = Instance.new("UITextSizeConstraint")
		size.MinTextSize, size.MaxTextSize, size.Parent = 10, label.TextSize, label
		label.TextScaled = true
	end
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
	self.unlocks = Celebration.new(self)
	self.roster = Roster.new(root, function()
		if self.layout then
			self.layout()
		end
	end)
	self.menu.showMiners = function()
		self.roster.override = true
		self.menu:close()
		self.layout()
	end
	self.overlay = self.menu.overlay
	self.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		backdrop.Enabled = self.overlay.Visible
		self.speech.Visible = false
		if self.layout then
			self.layout()
		end
	end)
	local walletScale, taskScale, haulScale = W.scale(wallet), W.scale(taskCard), W.scale(haul)
	local locScale, dockScale, speechScale = W.scale(loc), W.scale(dock), W.scale(speech)
	local chatInput = game:GetService("TextChatService"):FindFirstChildOfClass("ChatInputBarConfiguration")
	self.layout = function()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if width < 90 or height < 90 then
			return
		end
		local edge = self.mobile or width < 1020 or height < 565
		self.edgeMode = edge
		local playing = not self.overlay.Visible
		local typing = chatInput and chatInput.IsFocused
		local s = if edge then 1 else math.clamp(math.min(width / 1150, height / 750), 0.88, 1.16)
		local margin = if edge then 6 else 12
		self.menu:layout(width, height, self.mobile)
		walletScale.Scale, taskScale.Scale, haulScale.Scale, dockScale.Scale = s, s, s, s
		locScale.Scale = s
		local locWidth = if edge then math.clamp(width - 154 - margin * 3, 106, 186) else 186
		loc.Size = UDim2.fromOffset(locWidth, 40)
		self.layer.Size = UDim2.fromOffset(locWidth - 67, 21)
		self.depth.Position = UDim2.fromOffset(locWidth - 62, 2)
		self.coordinates.Size = UDim2.fromOffset(locWidth - 10, 18)
		local rosterHeight, browsing = self.roster:layout(s, margin, edge, height - 18 - self.haul.Size.Y.Offset * s)
		self.roster.panel.Visible = playing and (not edge or browsing)
		shortcuts.Visible = playing and edge and not typing and not (browsing and width < 435)
		dock.Visible = playing and not edge
		taskCard.Visible = playing and not edge and not browsing
		haul.Visible = playing and not edge and not browsing
		wallet.Visible = playing and not (edge and (typing or (browsing and width < 435)))
		loc.Visible = playing and not (edge and browsing)
		if edge then
			W.anchor(wallet, 0, 0, UDim2.fromOffset(margin, margin))
			W.anchor(loc, 1, 0, UDim2.new(1, -margin, 0, margin))
			-- On short landscape screens the two taps share one row above movement.
			local short = height < 310
			local top = margin + wallet.Size.Y.Offset + (if self.status.Text == "" then 6 else 19)
			shortcuts.Position = UDim2.fromOffset(margin, top)
			shortcuts.Size = UDim2.fromOffset(if short then 158 else 76, if short then 47 else 100)
			menuButton.Position = if short then UDim2.fromOffset(82, 0) else UDim2.fromOffset(0, 53)
		else
			W.anchor(wallet, 0, 1, UDim2.new(0, margin, 1, -margin - 90 * s))
			W.anchor(dock, 0, 1, UDim2.new(0, margin, 1, -margin))
			W.anchor(loc, 0.5, 0, UDim2.new(0.5, 0, 0, margin))
			local rightY = margin + rosterHeight + 7
			W.anchor(taskCard, 1, 0, UDim2.new(1, -10, 0, rightY))
			W.anchor(haul, 1, 0, UDim2.new(1, -10, 0, rightY + 92 * s))
		end
		local touchGui = gui.Parent:FindFirstChild("TouchGui")
		local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
		local validJump = jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.Y > 0
		local jumpTop = if validJump
			then jump.AbsolutePosition.Y - root.AbsolutePosition.Y
			else height - (if height > 500 then 124 else 94)
		local jumpCenter = if validJump
			then jump.AbsolutePosition.X + jump.AbsoluteSize.X * 0.5 - root.AbsolutePosition.X
			else width - 48
		local mineX = math.clamp(jumpCenter, 35, width - 35)
		local mineY = math.clamp(jumpTop - 8, 56, height - 5)
		if mineY < 148 and width > height then
			mineX = math.max(35, mineX - (if validJump then jump.AbsoluteSize.X * 0.5 else 40) - 42)
			mineY = math.clamp(jumpTop + 54, 56, height - 5)
		end
		W.anchor(self.mine, 0.5, 1, UDim2.fromOffset(mineX, mineY))
		self.mine.Visible = self.mobile and playing and not browsing
		local speechWidth = if edge then math.clamp(width - 175, 144, 248) else 320
		speechScale.Scale = s
		speech.Size = UDim2.fromOffset(speechWidth, if edge then 41 else 47)
		speech["Enamel highlight"].Size = UDim2.fromOffset(speechWidth - 22, 2)
		self.message.Size = UDim2.fromOffset(speechWidth - 10, if edge then 21 else 25)
		self.detail.Position = UDim2.fromOffset(5, if edge then 21 else 25)
		self.detail.Size = UDim2.fromOffset(speechWidth - 10, 18)
		meter.Size = UDim2.new(1, -20, 0, 7)
		local footer = if self.mobile and width < height then 136 else margin
		local centerX = if edge then width / 2 else math.max(width / 2, margin + (dockWidth + speechWidth / 2 + 10) * s)
		W.anchor(speech, 0.5, 1, UDim2.fromOffset(centerX, height - footer))
	end
	local function watchJump(button)
		if button.Name == "JumpButton" and button:IsA("GuiObject") then
			button:GetPropertyChangedSignal("AbsolutePosition"):Connect(self.layout)
			button:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.layout)
			task.defer(self.layout)
		end
	end
	gui.Parent.DescendantAdded:Connect(watchJump)
	local touch = gui.Parent:FindFirstChild("TouchGui")
	if touch then
		local jump = touch:FindFirstChild("JumpButton", true)
		if jump then
			watchJump(jump)
		end
	end
	if chatInput then
		chatInput:GetPropertyChangedSignal("IsFocused"):Connect(self.layout)
	end
	self.status:GetPropertyChangedSignal("Text"):Connect(self.layout)
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
	self.edgeCount.Text = W.number(used) .. "/" .. W.number(cap)
	self.edgeCount.TextColor3 = if used >= cap then W.gold else W.white
	self.fill.BackgroundColor3 = if used >= cap then W.gold else W.green
	if used ~= self.lastUsed or cap ~= self.lastCap then
		self.lastUsed, self.lastCap = used, cap
		W.tween(self.fill, 0.15, { Size = UDim2.fromScale(used / cap, 1) })
	end
	local held = Ores.carried(p)
	for _, row in self.rows do
		row.Visible = false
	end
	for i, entry in held do
		local ore = entry.ore
		local row = self.rows[ore.name]
		row.UnitValue.Text = W.number(ore.value * (if p:GetAttribute("DoubleGold") then 2 else 1)) .. " G each"
		row.Quantity.Text = "×" .. entry.amount
		row.Position, row.Visible = UDim2.fromOffset(10, 38 + (i - 1) * 20), true
	end
	local visible = #held
	self.empty.Visible = visible == 0
	local footerY = 39 + math.max(1, visible) * 20
	self.haulValue.Position = UDim2.fromOffset(10, footerY)
	self.haulValue.Text = "Sell value   "
		.. W.number((p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1))
		.. " G"
	if self.haul.Size.Y.Offset ~= footerY + 22 then
		self.haul.Size = UDim2.fromOffset(215, footerY + 22)
		self.layout()
	end
	local status = p:GetAttribute("SaveStatus")
	self.status.Text = if status == "Saving enabled" then "" else status or "Opening pack…"
	local mined = p:GetAttribute("Mined") or 0
	local xp = p:GetAttribute("MiningXP") or 0
	local minerLevel = Expeditions.level(xp)
	local _, rank = Expeditions.rank(minerLevel)
	if self.lastXP ~= xp then
		local start = Expeditions.levelXP(minerLevel)
		local needed = Expeditions.levelXP(minerLevel + 1) - start
		local amount = xp - start
		self.levelLabel.Text = "Lv " .. minerLevel
		self.xpLabel.Text = W.number(amount) .. " / " .. W.number(needed) .. " XP"
		local size = UDim2.fromScale(amount / needed, 1)
		if self.xpTween then
			self.xpTween:Cancel()
		end
		if self.lastXP ~= nil and p:GetAttribute("MenuMotion") ~= false then
			if minerLevel ~= self.lastMinerLevel then
				self.xpFill.Size = UDim2.fromScale(0, 1)
			end
			self.xpTween = W.tween(self.xpFill, 0.25, { Size = size })
		else
			self.xpFill.Size = size
		end
		self.lastXP, self.lastMinerLevel = xp, minerLevel
	end
	local job
	for i, candidate in Expeditions.jobs do
		if not Expeditions.jobClaimed(p:GetAttribute("ClaimedJobs") or 0, i) then
			job = candidate
			break
		end
	end
	self.jobFill.Size = UDim2.fromScale(if job then math.clamp(mined / job.goal, 0, 1) else 1, 1)
	self.job.Text = if job then job.title else rank.name
	self.reward.Text = if job then "+" .. W.number(job.reward) .. " G" else "All done"
	self.jobCount.Text = if job and mined >= job.goal
		then "Claim reward  ›"
		elseif job then string.format("%d / %d blocks mined", mined, job.goal)
		else W.number(mined) .. " blocks mined"
	self.jobCount.TextColor3 = if job and mined >= job.goal then W.green else W.muted
	self.jobBadge.Visible = (p:GetAttribute("SkillPoints") or 0) > 0
	self.edgeAlert.Visible = self.jobBadge.Visible or (job ~= nil and mined >= job.goal)
	for _, key in Upgrades.order do
		self.gearChips[key].Text = (if key == "Capacity" then "Pack" else key) .. " " .. level(key)
	end
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
	if self.edgeMode then
		self:notice(name, kind, color)
		return
	end
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
function Hud:workshop(key, level)
	local tint = Upgrades.items[key].color
	if self.workshopCard then
		self.workshopCard:Destroy()
	end
	local panel = card(self.root, "Upgrade fitted", 0, 0, 278, 68, tint:Lerp(W.ink, 0.32), W.panel)
	panel.ZIndex = 30
	W.anchor(panel, 0.5, 0, UDim2.new(0.5, 0, 0, 9))
	local headline = if key == "Power"
		then Upgrades.pickNames[level]
		elseif key == "Capacity" then "Field pack expanded"
		else "Faster pick swing"
	W.title(panel, headline, 8, 7, 262, 29, 22, W.white)
	W.text(panel, key .. "  Lv " .. level .. "   ·   " .. Upgrades.describe(key, level), 8, 37, 262, 22, 15, W.gold)
	self.workshopCard = panel
	if self.player:GetAttribute("MenuMotion") ~= false then
		local scale = W.scale(panel)
		scale.Scale = 0.78
		W.tween(scale, 0.21, { Scale = 1 })
	end
	task.delay(2.4, function()
		if self.workshopCard == panel then
			panel:Destroy()
			self.workshopCard = nil
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
