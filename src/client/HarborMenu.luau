local Shared = game:GetService("ReplicatedStorage").Shared
local Market = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Upgrades, Expeditions, Ores = require(Shared.Upgrades), require(Shared.Expeditions), require(Shared.Ores)
local Catalog = require(Shared.PassCatalog)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Menu = {}
Menu.__index = Menu
Menu.pages = {
	Lift = { name = "Mine lift", color = W.aqua },
	Gear = { name = "Workshop", color = W.orange },
	Jobs = { name = "Shift jobs", color = W.gold },
	Book = { name = "Ore index", color = W.green },
	Store = { name = "Outfitters", color = W.pink },
}
function Menu.new(root, player, net, close)
	local self = setmetatable({ player = player, net = net, prices = {}, updates = {} }, Menu)
	local shade = Instance.new("TextButton")
	shade.Name, shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency =
		"ShopOverlay", UDim2.fromScale(1, 1), W.ink, 0.25
	shade.Text, shade.AutoButtonColor, shade.Visible, shade.ZIndex, shade.Parent = "", false, false, 5, root
	shade.BackgroundTransparency = 1
	self.overlay = shade
	local modal = W.frame(shade, "Harbor menu", 0, 0, 480, 408, W.panel, 18)
	modal.Active = true
	W.stroke(modal, W.ink, 3)
	W.anchor(modal, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.scale = W.scale(modal)
	self.modal = modal
	local header = W.frame(modal, "Marquee", 7, 7, 466, 73, W.aqua, 12)
	self.header = header
	W.gradient(header, Color3.new(1, 1, 1), Color3.fromRGB(174, 194, 228), 16)
	self.iconWell = W.frame(header, "Badge", 12, 11, 50, 50, W.white, 12)
	W.stroke(self.iconWell, W.ink, 2)
	self.heading = W.title(header, "", 74, 4, 322, 37, 30, W.ink, true)
	self.sub = W.text(header, "", 76, 39, 329, 23, 15, W.ink, true)
	local closeButton = W.button(header, "Close", 416, 16, 37, 37, W.white, "×")
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
	return self
end
function Menu:layout(width, height, touch)
	local designHeight = if touch and width > height then math.clamp(height - 14, 270, 408) else 408
	self.scale.Scale = math.clamp(math.min((width - 18) / 480, (height - 14) / designHeight), 0.3, 1.2)
	self.modal.Size = UDim2.fromOffset(480, designHeight)
	self.list.Size = UDim2.fromOffset(458, designHeight - 135)
	self.footer.Position = UDim2.fromOffset(11, designHeight - 37)
end
function Menu:row(i, name, icon, color)
	local row = W.frame(self.list, name, 1, 1 + (i - 1) * 69, 447, 62, W.card, 10)
	local plate = W.frame(row, "Badge", 9, 8, 46, 46, color, 9)
	Icons.draw(plate, icon, 5, 5, 36, color)
	local title = W.title(row, name, 67, 5, 238, 25, 20, W.white, true)
	local detail = W.text(row, "", 67, 32, 253, 21, 14, W.muted, true)
	local button = W.button(row, "Action", 322, 12, 113, 38, color, "")
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
function Menu:lift()
	for i, stop in Expeditions.stops do
		local _, detail, b = self:row(i, stop.name, "Lift", stop.color)
		detail.Text = stop.detail
		b.Activated:Connect(function()
			self.net.Action:FireServer("Travel", stop.key)
		end)
		table.insert(self.updates, function()
			local unlocked = (self.player:GetAttribute("Mined") or 0) >= stop.goal
			setButton(
				b,
				if unlocked then "Travel" else stop.goal .. " mined",
				if unlocked then stop.color else W.muted,
				unlocked
			)
		end)
	end
	return #Expeditions.stops
end
function Menu:jobs()
	for i, job in Expeditions.jobs do
		local _, detail, b = self:row(i, job.title, "Jobs", W.gold)
		b.Activated:Connect(function()
			self.net.Action:FireServer("Job", i)
		end)
		table.insert(self.updates, function()
			local mined, done = self.player:GetAttribute("Mined") or 0, self.player:GetAttribute("Jobs") or 0
			local ready = done + 1 == i and mined >= job.goal
			detail.Text =
				string.format("%d / %d mined   •   +%s G", math.min(mined, job.goal), job.goal, W.number(job.reward))
			setButton(
				b,
				if done >= i
					then "Collected"
					elseif ready then "Claim gold"
					elseif i == done + 1 then "In progress"
					else "Upcoming",
				if ready then W.green else W.muted,
				ready
			)
		end)
	end
	return #Expeditions.jobs
end
function Menu:book()
	for i, ore in Ores.list do
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		local card = W.frame(self.list, ore.name, 1 + col * 226, 1 + row * 69, 219, 62, W.card, 11)
		local tile = W.frame(card, "Specimen", 7, 9, 43, 43, ore.color, 9)
		Icons.draw(tile, "Crystal", 5, 5, 33, ore.color:Lerp(W.white, 0.14))
		W.title(card, ore.name, 59, 3, 153, 25, 19, W.white, true)
		local state = W.text(card, "", 60, 26, 151, 16, 13, W.muted, true)
		W.text(card, ore.value .. " G  ·  Power " .. ore.hardness, 60, 43, 152, 15, 12, W.muted, true)
		table.insert(self.updates, function()
			local found = bit32.btest(self.player:GetAttribute("OreIndex") or 0, 2 ^ (i - 1))
			state.Text, state.TextColor3 =
				if found then ore.rarity .. "  ✓" else "Undiscovered", if found then W.green else W.muted
		end)
	end
	return math.ceil(#Ores.list / 2)
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
				local ok = pcall(Market.PromptGamePassPurchase, Market, self.player, item.id)
				if not ok then
					self.status.Text = "Roblox could not open checkout. Try again."
				end
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
local builders = { Gear = Menu.gear, Lift = Menu.lift, Jobs = Menu.jobs, Book = Menu.book, Store = Menu.store }
function Menu:open(key)
	local page = Menu.pages[key]
	if not page then
		return
	end
	self.updates = {}
	self.list:ClearAllChildren()
	if self.icon then
		self.icon:Destroy()
	end
	self.page, self.header.BackgroundColor3, self.heading.Text = key, page.color, page.name
	self.icon = Icons.draw(self.iconWell, key, 5, 5, 40, page.color)
	self.status.Text = if key == "Store"
			and RunService:IsStudio()
			and game.GameId == 0
		then "Studio trials last for this session."
		elseif key == "Jobs" then "Claim each job in order to collect its gold."
		elseif key == "Lift" then "Mine blocks anywhere to unlock more stops."
		elseif key == "Book" then "Mine each ore once to add it to your collection."
		elseif key == "Store" then "Permanent passes for this experience."
		else "Upgrades stay equipped between visits."
	local rows = builders[key](self)
	self.list.CanvasSize, self.list.CanvasPosition = UDim2.fromOffset(0, rows * 69), Vector2.zero
	self.overlay.Visible = true
	self:refresh()
end
function Menu:refresh()
	if not self.overlay.Visible then
		return
	end
	local p = self.player
	local n = p:GetAttribute("Mined") or 0
	if self.page == "Gear" then
		self.sub.Text = W.number(p:GetAttribute("Gold") or 0) .. " gold available"
	elseif self.page == "Jobs" then
		self.sub.Text = (p:GetAttribute("Jobs") or 0) .. " / " .. #Expeditions.jobs .. " jobs collected"
	elseif self.page == "Lift" then
		self.sub.Text = W.number(n) .. " blocks mined"
	elseif self.page == "Book" then
		local found, mask = 0, p:GetAttribute("OreIndex") or 0
		for i in Ores.list do
			if bit32.btest(mask, 2 ^ (i - 1)) then
				found += 1
			end
		end
		self.sub.Text = found .. " / " .. #Ores.list .. " ores discovered"
	else
		self.sub.Text = "Game passes"
	end
	for _, update in self.updates do
		update()
	end
end
return Menu
