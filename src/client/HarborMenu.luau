local Shared = game:GetService("ReplicatedStorage").Shared
local Market = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Upgrades, Expeditions, Ores = require(Shared.Upgrades), require(Shared.Expeditions), require(Shared.Ores)
local Settings = require(script.Parent.Settings)
local Catalog = require(Shared.PassCatalog)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Field = require(script.Parent.FieldPages)
local Guide = require(Shared.FieldGuide)
local Menu = {}
Menu.__index = Menu
Menu.pages = {
	Menu = { name = "Menu", color = W.aqua },
	Inventory = { name = "Inventory", color = W.gold },
	Pets = { name = "Pets", color = W.violet },
	Skills = { name = "Skill tree", color = W.green },
	Achievements = { name = "Achievements", color = W.orange },
	Titles = { name = "Miner titles", color = W.gold },
	Settings = { name = "Settings", color = Color3.fromRGB(120, 185, 255) },
	Gear = { name = "Workshop", color = W.aqua },
	Jobs = { name = "Shift jobs", color = W.violet },
	Book = { name = "Ore index", color = W.green },
	Store = { name = "Outfitters", color = W.pink },
	Pack = { name = "My backpack", color = W.gold },
}
function Menu.new(root, player, net, close)
	local self = setmetatable({ player = player, net = net, prices = {}, updates = {} }, Menu)
	self.preferences = Settings.new(player, net)
	local shade = Instance.new("Frame")
	shade.Name, shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency =
		"ShopOverlay", UDim2.fromScale(1, 1), W.ink, 0.25
	shade.Active, shade.Visible, shade.ZIndex, shade.Parent = true, false, 5, root
	shade.BackgroundTransparency = 1
	self.overlay = shade
	local modal = W.frame(shade, "Harbor menu", 0, 0, 480, 408, W.panel, 18)
	modal.Active = true
	W.stroke(modal, W.ink, 3)
	self.trim = W.enamel(modal, W.grape, W.panel)
	W.anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.scale = W.scale(modal)
	self.modal = modal
	local header = W.frame(modal, "Marquee", 7, 7, 466, 73, W.aqua, 12)
	self.header = header
	W.gradient(header, Color3.new(1, 1, 1), Color3.fromRGB(200, 177, 232), 24)
	for i = 1, 3 do
		local stripe = W.frame(header, "Sunburst", 323 + i * 17, 10, 10, 52, W.white, 4)
		stripe.Rotation, stripe.BackgroundTransparency = 22, 0.76
	end
	self.iconWell = W.frame(header, "Badge", 12, 11, 50, 50, W.white, 12)
	W.stroke(self.iconWell, W.ink, 2)
	self.heading = W.title(header, "", 74, 4, 322, 37, 30, W.ink, true)
	self.sub = W.text(header, "", 76, 39, 329, 23, 15, W.ink, true)
	self.sub.Name = "Summary"
	self.sub.TextScaled = true
	local summaryFont = Instance.new("UITextSizeConstraint")
	summaryFont.MinTextSize, summaryFont.MaxTextSize, summaryFont.Parent = 10, 15, self.sub
	local closeButton = W.button(header, "Close", 404, 9, 55, 55, W.white, "×", "Close")
	self.closeButton = closeButton
	closeButton.TextSize = 25
	closeButton.Activated:Connect(close)
	local list = Instance.new("ScrollingFrame")
	list.Name, list.Position, list.Size = "Listings", UDim2.fromOffset(11, 89), UDim2.fromOffset(458, 273)
	list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness, list.ScrollBarImageColor3 =
		1, 0, 5, W.muted
	list.ScrollingDirection, list.Parent = Enum.ScrollingDirection.Y, modal
	self.list = list
	local footer = W.frame(modal, "Status", 11, 371, 458, 28, W.ink, 8)
	self.footer = footer
	self.status = W.text(footer, "", 8, 0, 442, 28, 14, W.muted)
	local tabs = W.frame(modal, "Inventory tabs", 11, 85, 458, 32, W.ink, 8)
	self.tabs = tabs
	self.tabButtons = {}
	local tabX = 4
	for _, key in { "Inventory", "Pets", "Skills" } do
		local caption = if key == "Inventory" then "Titles" else key
		local width = 147
		local b = W.button(tabs, key, tabX, 2, width, 28, Menu.pages[key].color, caption, "Select")
		tabX += width + 4
		self.tabButtons[key] = b
		b.Activated:Connect(function()
			self:open(key)
		end)
	end
	tabs.Visible = false
	return self
end
function Menu:layout(width, height, touch)
	local designHeight = if touch and width > height then math.clamp(height - 14, 270, 408) else 408
	self.scale.Scale = math.clamp(math.min((width - 18) / 480, (height - 14) / designHeight), 0.3, 1.38)
	self.modal.Size = UDim2.fromOffset(480, designHeight)
	local closeSize = if touch then math.clamp(math.ceil(44 / self.scale.Scale), 48, 72) else 48
	self.closeButton.Size = UDim2.fromOffset(closeSize, closeSize)
	self.closeButton.Position = UDim2.fromOffset(462 - closeSize, (73 - closeSize) / 2)
	local extra = if self.tabs.Visible then 35 else 0
	self.designHeight = designHeight
	self.list.Position = UDim2.fromOffset(11, 89 + extra)
	self.list.Size = UDim2.fromOffset(458, designHeight - (if self.page == "Menu" then 99 else 135) - extra)
	self.footer.Position = UDim2.fromOffset(11, designHeight - 37)
end
function Menu:row(i, name, icon, color)
	local row = W.frame(self.list, name, 1, 1 + (i - 1) * 69, 447, 62, W.card, 10)
	W.enamel(row, color:Lerp(W.panel, 0.55), W.panel)
	W.frame(row, "Color tab", 0, 12, 4, 38, color, 2)
	local plate = W.frame(row, "Badge", 9, 8, 46, 46, color, 9)
	W.stroke(plate, W.ink, 2)
	Icons.draw(plate, icon, 5, 5, 36, color)
	local title = W.title(row, name, 67, 5, 238, 25, 20, W.white, true)
	local detail = W.text(row, "", 67, 32, 253, 21, 14, W.muted, true)
	local cues = { Gear = "Buy", Jobs = "Job", Settings = "Select", Store = "Select" }
	local button = W.button(row, "Action", 322, 12, 113, 38, color, "", cues[self.page])
	return title, detail, button
end
local function setButton(button, caption, tint, enabled)
	button.Text, button.BackgroundColor3 = caption, tint
	button.Interactable, button.AutoButtonColor = enabled, enabled
end
function Menu:gear()
	for i, key in Upgrades.order do
		local item = Upgrades.items[key]
		local title, detail, b = self:row(i, item.label or key, key, item.color)
		b.Activated:Connect(function()
			self.net.Action:FireServer("Buy", key)
		end)
		table.insert(self.updates, function()
			local level = self.player:GetAttribute(key) or 1
			local price = Upgrades.price(key, level)
			title.Text = (item.label or key) .. "  ·  Lv " .. level
			detail.Text = Upgrades.describe(key, level)
				.. (if price then "   →   " .. Upgrades.describe(key, level + 1) else "")
			setButton(
				b,
				if price then W.number(price) .. " G" else "Max level",
				if price and (self.player:GetAttribute("Gold") or 0) >= price then W.green else W.muted,
				price ~= nil
			)
		end)
	end
	return #Upgrades.order
end
function Menu:jobs()
	for i, job in Expeditions.jobs do
		local _, detail, b = self:row(i, job.title, "Jobs", W.gold)
		b.Activated:Connect(function()
			self.net.Action:FireServer("Job", i)
		end)
		table.insert(self.updates, function()
			local mined = self.player:GetAttribute("Mined") or 0
			local claimed = Expeditions.jobClaimed(self.player:GetAttribute("ClaimedJobs") or 0, i)
			local ready = not claimed and mined >= job.goal
			detail.Text =
				string.format("%d / %d mined   •   +%s G", math.min(mined, job.goal), job.goal, W.number(job.reward))
			setButton(
				b,
				if claimed then "Collected" elseif ready then "Claim gold" else "In progress",
				if ready then W.green else W.muted,
				ready
			)
		end)
	end
	return #Expeditions.jobs
end
function Menu:pack()
	local rows = {}
	for i, ore in Ores.list do
		local title, detail, count = self:row(i, ore.name, "Crystal", ore.color)
		count.Interactable = false
		rows[ore.name] = { row = title.Parent, detail = detail, count = count }
	end
	local empty = W.text(self.list, "Your pack is empty", 0, 8, 447, 45, 18, W.muted)
	table.insert(self.updates, function()
		local held = Ores.carried(self.player)
		for _, item in rows do
			item.row.Visible = false
		end
		for i, entry in held do
			local item = rows[entry.ore.name]
			local each = entry.ore.value * (if self.player:GetAttribute("DoubleGold") then 2 else 1)
			item.row.Position, item.row.Visible = UDim2.fromOffset(1, 1 + (i - 1) * 69), true
			item.count.Text = "×" .. entry.amount
			item.detail.Text = string.format("%d G each  ·  %s G in pack", each, W.number(entry.amount * each))
		end
		empty.Visible = #held == 0
		self.list.CanvasSize = UDim2.fromOffset(0, #held * 69)
	end)
	return 0
end
function Menu:store()
	for i, item in Catalog do
		local _, detail, b = self:row(i, item.name, item.icon, item.color)
		detail.Text = item.detail
		local trial = item.id == 0 and RunService:IsStudio() and (game.GameId == 0 or self.player.UserId <= 0)
		b.Activated:Connect(function()
			if self.player:GetAttribute(item.key) then
				return
			end
			if trial then
				self.net.Action:FireServer("PreviewPass", item.key)
			elseif type(self.prices[item.key]) == "number" then
				self.net.Action:FireServer("Pass", item.key)
			end
		end)
		table.insert(self.updates, function()
			local owned, price = self.player:GetAttribute(item.key), self.prices[item.key]
			local sale = type(price) == "number"
			setButton(
				b,
				if owned
					then (if trial then "Trying now" else "Owned")
					elseif trial then "Try in Studio"
					elseif sale then "R$ " .. price
					elseif price == "loading" then "Loading…"
					else "Off sale",
				if owned then W.green elseif trial or sale then item.color else W.muted,
				not owned and (trial or sale)
			)
		end)
		if item.id > 0 and type(self.prices[item.key]) ~= "number" and self.prices[item.key] ~= "loading" then
			self.prices[item.key] = "loading"
			task.spawn(function()
				local ok, info = pcall(Market.GetProductInfoAsync, Market, item.id, Enum.InfoType.GamePass)
				self.prices[item.key] = if ok
						and info.IsForSale
						and type(info.PriceInRobux) == "number"
					then info.PriceInRobux
					else false
				if self.page == "Store" then
					self:refresh()
				end
			end)
		end
	end
	return #Catalog
end
local function shortcuts(self)
	local destinations = { "Inventory", "Skills", "Achievements", "Book", "Jobs", "Settings", "Pets", "Miners" }
	for i, key in destinations do
		local page = Menu.pages[key]
		local color = if page then page.color else W.aqua
		local button = W.button(
			self.list,
			key,
			4 + ((i - 1) % 2) * 224,
			3 + math.floor((i - 1) / 2) * 77,
			214,
			71,
			color,
			"",
			"Select"
		)
		local icon = if key == "Miners" then "Crew" elseif key == "Inventory" then "Pack" else key
		Icons.draw(button, icon, 9, 16, 38, color)
		W.title(button, if page then page.name else "Server miners", 51, 0, 158, 71, 17, W.ink, true)
		button.Activated:Connect(function()
			if key == "Miners" then
				self.showMiners()
			else
				self:open(key)
			end
		end)
	end
	return math.ceil(#destinations / 2)
end
local builders = {
	Menu = shortcuts,
	Gear = Menu.gear,
	Inventory = Field.titles,
	Pets = Field.pets,
	Skills = Field.skills,
	Achievements = Field.achievements,
	Settings = function(self)
		return self.preferences:build(self)
	end,
	Jobs = Menu.jobs,
	Book = Field.index,
	Pack = Menu.pack,
	Store = Menu.store,
}
function Menu:open(key)
	if key == "Titles" then
		key = "Inventory"
	end
	local page = Menu.pages[key]
	if not page then
		return
	end
	self.updates = {}
	self.tabs.Visible = self.tabButtons[key] ~= nil
	for k, b in self.tabButtons do
		b.BackgroundColor3 = if key == k then W.white else Menu.pages[k].color
	end
	local extra = if self.tabs.Visible then 35 else 0
	self.list.Position = UDim2.fromOffset(11, 89 + extra)
	self.list.Size = UDim2.fromOffset(458, (self.designHeight or 408) - (if key == "Menu" then 99 else 135) - extra)
	self.list:ClearAllChildren()
	if self.icon then
		self.icon:Destroy()
	end
	self.page, self.header.BackgroundColor3, self.heading.Text = key, page.color, page.name
	self.trim.Color = ColorSequence.new(page.color:Lerp(W.panel, 0.46), W.panel)
	self.icon = Icons.draw(self.iconWell, key, 5, 5, 40, page.color)
	self.status.Text = if key == "Store"
			and RunService:IsStudio()
			and game.GameId == 0
		then "Studio trials last for this session."
		elseif key == "Menu" then ""
		elseif key == "Inventory" then "Select an unlocked title to wear it."
		elseif key == "Pets" then "Equip one companion at a time."
		elseif key == "Skills" then "Earn one point per level. Follow the connected branches."
		elseif key == "Achievements" then "Mine, explore and try new things. ??? reveals when you find the ore."
		elseif key == "Pack" then "Take your haul to the amber Sell counter."
		elseif key == "Jobs" then "Claim any finished job to collect its gold."
		elseif key == "Settings" then "Changes take effect immediately."
		elseif key == "Book" then "The first two layers are dirt. Odds apply to solid rock."
		elseif key == "Store" then "Permanent passes for this experience."
		else "Upgrades stay equipped between visits."
	local rows = builders[key](self)
	self.footer.Visible = key ~= "Menu"
	self.list.CanvasSize, self.list.CanvasPosition =
		UDim2.fromOffset(0, rows * (if key == "Menu" then 77 else 69)), Vector2.zero
	if self.motion then
		self.motion:Cancel()
	end
	self.closing = false
	self.overlay.Visible = true
	local center = UDim2.fromScale(0.5, 0.5)
	if self.preferences.values.MenuMotion then
		self.modal.Position = UDim2.new(0.5, 0, 0.5, 64 * self.scale.Scale)
		self.motion = W.tween(self.modal, 0.22, { Position = center })
	else
		self.modal.Position = center
	end
	self:refresh()
end
function Menu:close()
	if not self.overlay.Visible or self.closing then
		return
	end
	if self.motion then
		self.motion:Cancel()
	end
	if not self.preferences.values.MenuMotion then
		self.overlay.Visible = false
		return
	end
	self.closing = true
	self.motion = W.tween(self.modal, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 52 * self.scale.Scale) })
	self.motion.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and self.closing then
			self.overlay.Visible = false
			self.closing = false
		end
	end)
end
function Menu:refresh()
	if not self.overlay.Visible then
		return
	end
	local p = self.player
	if self.page == "Menu" then
		self.sub.Text = ""
	elseif self.page == "Inventory" then
		local xp = p:GetAttribute("MiningXP") or 0
		local level = Expeditions.level(xp)
		self.sub.Text = string.format(
			"Level %d    ·    %s / %s XP to level %d",
			level,
			W.number(xp - Expeditions.levelXP(level)),
			W.number(Expeditions.levelXP(level + 1) - Expeditions.levelXP(level)),
			level + 1
		)
	elseif self.page == "Skills" then
		local xp = p:GetAttribute("MiningXP") or 0
		local level = Expeditions.level(xp)
		local start = Expeditions.levelXP(level)
		self.sub.Text = string.format(
			"Lv %d  ·  %d / %d XP  ·  %d points",
			level,
			xp - start,
			Expeditions.levelXP(level + 1) - start,
			p:GetAttribute("SkillPoints") or 0
		)
	elseif self.page == "Pets" then
		self.sub.Text = if p:GetAttribute("Pet") == "Rock"
			then "Equipped   ·   " .. (p:GetAttribute("PetName") or "Pebble")
			else "Your companions"
	elseif self.page == "Achievements" then
		local earned = 0
		for _, award in Guide.achievements do
			if (p:GetAttribute("Award" .. award.id) or 0) >= award.goal then
				earned += 1
			end
		end
		self.sub.Text = string.format("%d / %d earned", earned, #Guide.achievements)
	elseif self.page == "Pack" then
		local cap = Upgrades.items.Capacity.values[p:GetAttribute("Capacity") or 1]
		local value = (p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1)
		self.sub.Text = string.format("%d / %d slots   ·   %s G", p:GetAttribute("Used") or 0, cap, W.number(value))
	elseif self.page == "Gear" then
		self.sub.Text = W.number(p:GetAttribute("Gold") or 0) .. " gold available"
	elseif self.page == "Jobs" then
		self.sub.Text = (p:GetAttribute("Jobs") or 0) .. " / " .. #Expeditions.jobs .. " jobs collected"
	elseif self.page == "Settings" then
		self.sub.Text = p:GetAttribute("SaveStatus") or "Sound and motion"
	elseif self.page == "Book" then
		local found = 0
		for _, ore in Ores.list do
			if p:GetAttribute("Found" .. ore.name) then
				found += 1
			end
		end
		self.sub.Text = found .. " / " .. #Ores.list .. " materials discovered"
	else
		self.sub.Text = "Game passes"
	end
	for _, update in self.updates do
		update()
	end
end
return Menu
