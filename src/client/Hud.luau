local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local StarterGui = game:GetService("StarterGui")
local Upgrades = require(Shared.Upgrades)
local W = require(script.Parent.Widgets)
local Hud = {}
Hud.__index = Hud
local function anchor(obj, x, y, pos)
	obj.AnchorPoint, obj.Position = Vector2.new(x, y), pos
end
function Hud.new(player, net, mobile)
	local self = setmetatable({}, Hud)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.ScreenInsets, gui.ZIndexBehavior =
		"QuarryHUD", false, Enum.ScreenInsets.CoreUISafeInsets, Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = W.frame(gui, "SafeArea", 0, 0, 1, 1, W.ink)
	root.Size, root.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	local cash = W.frame(root, "Pack", 12, 8, 223, 92, W.chrome, 5)
	self.cash = cash
	W.stroke(cash, W.ink, 2)
	W.bevel(cash)
	local counter = W.frame(cash, "Gold counter", 6, 6, 211, 40, W.ink, 3)
	W.goldBrick(counter, 10, 15)
	self.gold = W.text(counter, "0", 54, 0, 151, 40, 29, W.gold, true)
	self.gold.Font = Enum.Font.RobotoMono
	self.pack = W.text(cash, "BACKPACK", 12, 48, 199, 24, 16, W.ink, true)
	local track = W.frame(cash, "Capacity", 12, 74, 199, 10, W.ink, 2)
	self.fill = W.frame(track, "Ore", 0, 0, 0, 10, W.green, 2)
	for i = 1, 7 do
		local tick = W.frame(track, "Division", 0, 0, 2, 10, W.ink)
		tick.Position, tick.ZIndex = UDim2.fromScale(i / 8, 0), 2
	end
	self.sell = W.button(cash, "Sell", 0, 100, 108, 42, W.gold, "SELL")
	self.shop = W.button(cash, "Shop", 115, 100, 108, 42, W.aqua, "UPGRADES")
	self.status = W.text(cash, "", 0, 147, 223, 22, 12, W.white, true)
	self.status.TextStrokeTransparency = 0.25
	local info = W.frame(root, "Depth", 0, 0, 193, 97, W.panel, 5)
	self.info = info
	W.stroke(info, W.ink, 2)
	W.bevel(info)
	local strip = W.frame(info, "Layer strip", 4, 4, 185, 22, W.blue, 2)
	self.layer = W.text(strip, string.upper(Config.SurfaceName), 4, 0, 177, 22, 13, W.white)
	self.depth = W.text(info, "Surface", 8, 26, 177, 31, 23, W.white)
	self.stats = W.text(info, "", 3, 55, 187, 39, 14, W.muted)
	self.surface = W.button(info, "Surface", 53, 105, 140, 40, W.white, "↑  SURFACE")
	self.mine = W.button(root, "Mine", 0, 0, 95, 52, W.aqua, "HOLD MINE")
	anchor(self.mine, 1, 0.5, UDim2.new(1, -16, 0.54, 0))
	self.mine.Visible = mobile

	local speech = W.frame(root, "Message", 0, 0, 350, 52, W.ink, 5)
	anchor(speech, 0.5, 1, UDim2.new(0.5, 0, 1, -14))
	speech.BackgroundTransparency = 0.10
	self.message = W.text(speech, "", 8, 3, 334, 26, 18, W.white)
	self.detail = W.text(speech, "", 8, 28, 334, 18, 13, W.muted)
	self.speech = speech
	local aimGui = Instance.new("ScreenGui")
	aimGui.Name, aimGui.ResetOnSpawn, aimGui.ScreenInsets = "QuarryAim", false, Enum.ScreenInsets.None
	aimGui.Parent = gui.Parent
	local reticle = W.frame(aimGui, "Aim", 0, 0, 8, 8, W.white, 4)
	anchor(reticle, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.stroke(reticle, W.ink, 1.6)
	self.reticle = reticle
	reticle.Visible = false
	-- Capture input across the whole modal, including the gaps between rows.
	local shade = Instance.new("TextButton")
	shade.Name, shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency =
		"ShopOverlay", UDim2.fromScale(1, 1), W.ink, 0.22
	shade.Text, shade.AutoButtonColor, shade.Visible, shade.ZIndex, shade.Parent = "", false, false, 5, root
	local modal = W.frame(shade, "Workshop", 0, 0, 454, 396, W.chrome, 6)
	modal.Active = true
	anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.stroke(modal, W.ink, 3)
	W.bevel(modal)
	local header = W.frame(modal, "Title bar", 6, 6, 442, 48, W.blue, 3)
	W.text(header, "WORKSHOP", 12, 0, 235, 48, 23, W.white, true).Font = Enum.Font.Arcade
	self.wallet = W.text(header, "", 239, 0, 144, 48, 16, W.gold)
	local close = W.button(header, "Close", 392, 6, 43, 36, W.card, "×")
	close.TextSize = 25
	self.rows = {}
	for i, key in Upgrades.order do
		local item = Upgrades.items[key]
		local row = W.frame(modal, key, 12, 65 + (i - 1) * 76, 430, 69, W.card, 4)
		W.stroke(row, W.line, 1)
		local tile = W.frame(row, "Icon", 10, 12, 43, 43, item.color, 4)
		W.bevel(tile)
		W.text(tile, item.icon, 0, 0, 43, 43, 29, W.ink)
		local title = W.text(row, key, 65, 7, 242, 24, 20, W.ink, true)
		local benefit = W.text(row, "", 65, 35, 251, 22, 15, W.panel, true)
		local buy = W.button(row, "Purchase", 320, 12, 99, 40, W.green, "")
		buy.Activated:Connect(function()
			net.Action:FireServer("Buy", key)
		end)
		self.rows[key] = { title = title, benefit = benefit, buy = buy }
	end
	self.shopMessage = W.text(modal, "", 12, 367, 430, 23, 14, W.ink)
	self.overlay = shade
	self.shop.Activated:Connect(function()
		self:setShop(true)
	end)
	close.Activated:Connect(function()
		self:setShop(false)
	end)
	self.sell.Activated:Connect(function()
		net.Action:FireServer("Sell")
	end)
	self.surface.Activated:Connect(function()
		net.Action:FireServer("Surface")
	end)
	local hudScales = { W.scale(cash), W.scale(info), W.scale(speech) }
	local shopScale = W.scale(modal)
	local function layout()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		local scale = math.clamp(math.min((width - 34) / 430, height / 465), 0.54, 1.14)
		for _, s in hudScales do
			s.Scale = scale
		end
		shopScale.Scale = math.clamp(math.min((width - 24) / 454, (height - 18) / 396), 0.40, 1.18)
		local crowded = not self.mobile and width < 806 * scale
		local margin = if self.mobile then 120 * scale elseif crowded then 172 * scale else 14
		speech.Position = UDim2.new(0.5, 0, 1, -margin)
	end
	self.layout = layout
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	self.player, self.net, self.mobile = player, net, mobile
	self:placePanels(mobile)
	local function refresh()
		self:refresh()
	end
	player.AttributeChanged:Connect(refresh)
	net:GetAttributeChangedSignal("Ready"):Connect(refresh)
	self:refresh()
	return self
end

function Hud:placePanels(touch)
	if touch then
		anchor(self.cash, 0, 0, UDim2.fromOffset(12, 8))
		self.sell.Position, self.shop.Position = UDim2.fromOffset(0, 100), UDim2.fromOffset(115, 100)
		self.status.Position = UDim2.fromOffset(0, 147)
		anchor(self.info, 0.5, 1, UDim2.new(0.5, 0, 1, -8))
		self.surface.Parent = self.cash
		self.surface.Position = UDim2.fromOffset(0, 173)
	else
		anchor(self.cash, 0, 1, UDim2.new(0, 12, 1, -12))
		self.sell.Position, self.shop.Position = UDim2.fromOffset(0, -50), UDim2.fromOffset(115, -50)
		self.status.Position = UDim2.fromOffset(0, -75)
		anchor(self.info, 1, 1, UDim2.new(1, -12, 1, -12))
		self.surface.Parent = self.info
		self.surface.Position = UDim2.fromOffset(53, -49)
	end
	self.layout()
end
function Hud:setShop(open)
	if self.overlay.Visible == open then
		return
	end
	if open then
		self.restoreList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	elseif self.restoreList then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end
	self.overlay.Visible = open
	self.shopMessage.Text = ""
	self.mine.Visible = self.mobile and not open
	self.reticle.Visible = false
end
function Hud:refresh()
	local p = self.player
	local gold, used = p:GetAttribute("Gold") or 0, p:GetAttribute("Used") or 0
	local function level(k)
		return p:GetAttribute(k) or 1
	end
	local function stat(k)
		return Upgrades.items[k].values[level(k)]
	end
	local capacity = stat("Capacity")
	self.gold.Text = W.number(gold)
	self.wallet.Text = W.number(gold) .. " GOLD"
	self.pack.Text = string.format("PACK     %s / %s", W.number(used), W.number(capacity))
	self.fill.BackgroundColor3 = if used >= capacity then W.gold else W.green
	W.tween(self.fill, 0.15, { Size = UDim2.new(used / capacity, 0, 1, 0) })
	self.sell.Text = if used > 0
		then "SELL  " .. W.number(p:GetAttribute("BagValue") or 0) .. " G"
		else "SELL"
	self.stats.Text = string.format(
		"Radius %d    ·    Power %d\nPulse every %.2fs",
		stat("Radius"),
		stat("Power"),
		stat("Speed")
	)
	self.status.Text = p:GetAttribute("SaveStatus") or "Opening pack…"
	if self.status.Text == "Saving enabled" then
		self.status.Text = ""
	end
	for key, row in self.rows do
		local lvl = level(key)
		local price = Upgrades.price(key, lvl)
		row.title.Text = key .. "   ·   Lv " .. lvl
		row.benefit.Text = Upgrades.describe(key, lvl)
			.. (if price then "  →  " .. Upgrades.describe(key, lvl + 1) else "")
		row.buy.Text = if price then W.number(price) .. " G" else "MAX"
		row.buy.BackgroundColor3 = if price and gold >= price then W.green else W.chrome
		row.buy.Active = price ~= nil
	end
end
function Hud:notice(title, detail, color)
	self.untilTime = os.clock() + 2.1
	self.message.Text, self.message.TextColor3, self.detail.Text = title, color or W.white, detail or ""
	if self.overlay.Visible then
		self.shopMessage.Text = title
	end
	self.message.TextTransparency = 0.32
	W.tween(self.message, 0.16, { TextTransparency = 0 })
end
function Hud:guide(t, sub, visible)
	if os.clock() < (self.untilTime or 0) then
		self.speech.Visible = true
		return
	end
	self.speech.Visible = visible
	self.message.Text, self.message.TextColor3, self.detail.Text = t, W.white, sub
end
return Hud
