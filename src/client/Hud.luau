local Shared = game:GetService("ReplicatedStorage").Shared
local StarterGui = game:GetService("StarterGui")
local Upgrades, Expeditions = require(Shared.Upgrades), require(Shared.Expeditions)
local W, Icons, Menu = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.HarborMenu)
local Hud = {}
Hud.__index = Hud
local function card(parent, name, x, y, w, h)
	local f = W.frame(parent, name, x, y, w, h, W.panel, 13)
	W.stroke(f, W.ink, 2)
	W.gradient(f, Color3.new(1, 1, 1), Color3.fromRGB(201, 216, 232), 20)
	return f
end
function Hud.new(player, net, mobile)
	local self = setmetatable({ player = player, net = net, mobile = mobile }, Hud)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.ScreenInsets, gui.ZIndexBehavior =
		"QuarryHUD", false, Enum.ScreenInsets.CoreUISafeInsets, Enum.ZIndexBehavior.Sibling
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
	local wallet = card(root, "Wallet", 0, 0, 211, 79)
	Icons.draw(wallet, "Coins", 9, 5, 38)
	self.gold = W.title(wallet, "0", 52, 0, 151, 40, 31, W.gold, true)
	Icons.draw(wallet, "Capacity", 12, 45, 24)
	self.pack = W.text(wallet, "", 45, 39, 154, 19, 15, W.white, true)
	local track = W.frame(wallet, "Capacity", 46, 63, 151, 7, W.ink, 4)
	self.fill = W.frame(track, "Ore", 0, 0, 0, 7, W.green, 4)
	self.status = W.text(wallet, "", 0, 80, 211, 15, 12, W.white, true)
	self.status.TextStrokeTransparency = 0.2
	local taskCard = card(root, "Current job", 0, 0, 215, 79)
	W.anchor(taskCard, 1, 0, UDim2.new(1, -12, 0, 9))
	Icons.draw(taskCard, "Jobs", 8, 7, 27)
	W.text(taskCard, "SHIFT JOB", 42, 5, 96, 22, 13, W.gold, true)
	self.reward = W.text(taskCard, "", 139, 5, 67, 22, 13, W.green)
	self.job = W.title(taskCard, "", 12, 29, 193, 25, 20, W.white, true)
	self.jobCount = W.text(taskCard, "", 12, 55, 190, 19, 14, W.muted, true)
	self.ribbon = card(taskCard, "Discovery", 0, 88, 215, 52)
	self.ribbon.Visible = false
	self.ribbonType = W.text(self.ribbon, "", 12, 4, 192, 17, 12, W.aqua, true)
	self.ribbonName = W.title(self.ribbon, "", 12, 22, 192, 25, 20, W.white, true)
	local jobTap = Instance.new("TextButton")
	jobTap.Name, jobTap.Text, jobTap.AutoButtonColor, jobTap.BackgroundTransparency = "OpenJob", "", false, 1
	jobTap.Size, jobTap.ZIndex, jobTap.Parent = UDim2.fromScale(1, 1), 2, taskCard
	jobTap.Activated:Connect(function()
		self:openPage("Jobs")
	end)
	local loc = card(root, "Location", 0, 0, 211, 76)
	self.layer = W.text(loc, "CITRINE COVE", 10, 3, 186, 19, 13, W.aqua, true)
	self.depth = W.title(loc, "Surface", 10, 24, 91, 26, 20, W.white, true)
	self.surface = W.button(loc, "Surface", 105, 22, 92, 27, W.aqua, "↑ Harbor")
	self.surface.TextSize = 14
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	self.stats = W.text(loc, "", 10, 53, 194, 18, 12, W.muted, true)
	local dock = W.frame(root, "Action dock", 0, 0, 441, 64, W.ink)
	dock.BackgroundTransparency = 1
	self.nav = {}
	for i, key in { "Lift", "Gear", "Jobs", "Book", "Store", "Sell" } do
		local tint = if key == "Sell" then W.green else Menu.pages[key].color
		local b = W.button(dock, key, (i - 1) * 74, 0, 69, 61, tint, "")
		local icon = Icons.draw(b, key, 19, 2, 31, tint)
		icon.Rotation = if i % 2 == 0 then 4 else -4
		self.nav[key] = W.title(b, if key == "Book" then "Index" else key, 1, 32, 67, 25, 17, W.ink)
		if key == "Jobs" then
			self.jobBadge = W.frame(b, "Reward ready", 53, -5, 20, 20, W.pink, 10)
			W.stroke(self.jobBadge, W.ink, 2)
			W.title(self.jobBadge, "!", 0, 0, 20, 20, 15, W.ink)
		end
		b.Activated:Connect(function()
			if key == "Sell" then
				net.Action:FireServer("Sell")
			else
				self:openPage(key)
			end
		end)
	end
	self.mine = W.button(root, "Mine", 0, 0, 98, 46, W.aqua, "Hold mine")
	W.anchor(self.mine, 1, 0.5, UDim2.new(1, -12, 0.54, 0))
	self.mine.Visible = mobile
	local speech = card(root, "Feedback", 0, 0, 320, 47)
	self.message = W.title(speech, "", 5, 1, 310, 25, 18, W.white)
	self.detail = W.text(speech, "", 5, 25, 310, 18, 13, W.muted)
	self.speech = speech
	local aimGui = Instance.new("ScreenGui")
	aimGui.Name, aimGui.ResetOnSpawn, aimGui.ScreenInsets = "QuarryAim", false, Enum.ScreenInsets.None
	aimGui.Parent = gui.Parent
	self.reticle = W.frame(aimGui, "Aim", 0, 0, 8, 8, W.white, 4)
	W.anchor(self.reticle, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.stroke(self.reticle, W.ink, 1.6)
	self.reticle.Visible = false
	self.menu = Menu.new(root, player, net, function()
		self:setShop(false)
	end)
	self.overlay = self.menu.overlay
	self.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		local open = self.overlay.Visible
		backdrop.Enabled = open
		for _, panel in { wallet, taskCard, loc, dock } do
			panel.Visible = not open
		end
		self.speech.Visible = false
	end)
	local walletScale, taskScale, locScale, dockScale, speechScale, mineScale =
		W.scale(wallet), W.scale(taskCard), W.scale(loc), W.scale(dock), W.scale(speech), W.scale(self.mine)
	self.layout = function()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if width < 2 or height < 2 then
			return
		end
		local s = math.clamp(math.min((width - 28) / 450, height / 510), 0.55, 1.14)
		local ds = math.min(s, (width - 16) / 441)
		local portrait = self.mobile and width < height
		if self.mobile and not portrait then
			ds = math.min(math.max(ds, 0.78), math.max(0.56, (width - 195) / 441))
		end
		walletScale.Scale, taskScale.Scale, locScale.Scale = s, s, s
		dockScale.Scale, speechScale.Scale, mineScale.Scale = ds, math.min(s, (width - 20) / 320), math.max(0.88, s)
		self.menu:layout(width, height, self.mobile)
		W.anchor(wallet, 0, 0, UDim2.fromOffset(10, 9))
		W.anchor(taskCard, 1, 0, UDim2.new(1, -10, 0, 9))
		W.anchor(loc, 0, 0, UDim2.fromOffset(10, 12 + 96 * s))
		local dockOffset = if portrait then 110 else 7
		W.anchor(dock, 0.5, 1, UDim2.new(0.5, 0, 1, -dockOffset))
		W.anchor(speech, 0.5, 1, UDim2.new(0.5, 0, 1, -dockOffset - 71 * ds))
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
		self.overlay.Visible = false
		self.mine.Visible = self.mobile
	end
end
function Hud:refresh()
	local p = self.player
	local function level(key)
		return p:GetAttribute(key) or 1
	end
	local used, cap = p:GetAttribute("Used") or 0, Upgrades.items.Capacity.values[level("Capacity")]
	self.gold.Text = W.number(p:GetAttribute("Gold") or 0)
	self.pack.Text = "Pack   " .. W.number(used) .. " / " .. W.number(cap)
	self.fill.BackgroundColor3 = if used >= cap then W.gold else W.green
	if used ~= self.lastUsed or cap ~= self.lastCap then
		self.lastUsed, self.lastCap = used, cap
		W.tween(self.fill, 0.15, { Size = UDim2.fromScale(used / cap, 1) })
	end
	local value = (p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1)
	self.nav.Sell.Text = if used > 0 then "Sell " .. W.number(value) else "Sell"
	self.nav.Sell.TextSize = if #self.nav.Sell.Text > 7 then 13 else 17
	local status = p:GetAttribute("SaveStatus")
	self.status.Text = if status == "Saving enabled" then "" else status or "Opening pack…"
	local mined, done = p:GetAttribute("Mined") or 0, p:GetAttribute("Jobs") or 0
	local _, rank = Expeditions.rank(mined)
	local job = Expeditions.jobs[done + 1]
	self.job.Text = if job then job.title else rank.name
	self.reward.Text = if job then "+" .. W.number(job.reward) .. " G" else "All done"
	self.jobCount.Text = if job and mined >= job.goal
		then "Claim reward  ›"
		elseif job then string.format("%d / %d blocks mined", mined, job.goal)
		else W.number(mined) .. " blocks mined"
	self.jobCount.TextColor3 = if job and mined >= job.goal then W.green else W.muted
	self.jobBadge.Visible = job ~= nil and mined >= job.goal
	self.stats.Text = string.format(
		"%s  ·  %s  ·  Power %d  ·  %.2fs",
		rank.name,
		Upgrades.describe("Radius", level("Radius")),
		level("Power"),
		Upgrades.items.Speed.values[level("Speed")]
	)
	self.menu:refresh()
end
function Hud:milestone(kind, name, color)
	local serial = (self.ribbonSerial or 0) + 1
	self.ribbonSerial = serial
	self.ribbonType.Text, self.ribbonType.TextColor3, self.ribbonName.Text = kind, color:Lerp(W.white, 0.36), name
	self.ribbon.Visible = true
	self.ribbon.Position = UDim2.fromOffset(18, 88)
	W.tween(self.ribbon, 0.2, { Position = UDim2.fromOffset(0, 88) })
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
