local Shared = game.ReplicatedStorage.Shared
local E, Guide, Ores, Config =
	require(Shared.Expeditions), require(Shared.FieldGuide), require(Shared.Ores), require(Shared.GameConfig)
local W = require(script.Parent.Widgets)
local Pages = {}
function Pages.titles(menu)
	for i, title in E.ranks do
		local _, detail, b = menu:row(i, title.name, "Titles", W.gold)
		detail.Text = "Level " .. title.level
		b.Activated:Connect(function()
			menu.net.Action:FireServer("Title", i)
		end)
		table.insert(menu.updates, function()
			local owned = (menu.player:GetAttribute("Level") or 1) >= title.level
			local equipped = (menu.player:GetAttribute("EquippedTitle") or 1) == i
			b.Text = if equipped then "Equipped" elseif owned then "Equip" else "Locked"
			b.BackgroundColor3 = if equipped then W.green elseif owned then W.gold else W.muted
			b.Interactable = owned and not equipped
		end)
	end
	return #E.ranks
end
function Pages.pets(menu)
	local _, detail, equip = menu:row(1, "Pocket Rock", "Pets", W.violet)
	equip.Activated:Connect(function()
		menu.net.Action:FireServer("Pet", if menu.player:GetAttribute("Pet") == "Rock" then "" else "Rock")
	end)
	local card = W.frame(menu.list, "Rename", 1, 76, 447, 119, W.card, 12)
	W.title(card, "Companion name", 13, 5, 300, 25, 19, W.white, true)
	local box = Instance.new("TextBox")
	box.Name, box.Position, box.Size = "Name", UDim2.fromOffset(13, 36), UDim2.fromOffset(262, 34)
	box.PlaceholderText, box.ClearTextOnFocus, box.Text = "Choose a name", false, ""
	box.TextSize, box.Font, box.TextColor3, box.BackgroundColor3 = 17, Enum.Font.BuilderSansBold, W.white, W.ink
	W.round(box, 8)
	box.Parent = card
	local rename = W.button(card, "Rename", 287, 36, 144, 34, W.gold, "Save name", "Select")
	rename.Activated:Connect(function()
		if box.Text ~= "" then
			menu.net.Action:FireServer("PetName", box.Text)
		end
	end)
	for i, name in { "Pebble", "Flint", "Chips" } do
		local b = W.button(card, name, 13 + (i - 1) * 91, 81, 83, 26, W.muted, name, "Select")
		b.Activated:Connect(function()
			box.Text = name
		end)
	end
	table.insert(menu.updates, function()
		local active = menu.player:GetAttribute("Pet") == "Rock"
		local name = menu.player:GetAttribute("PetName") or "Pebble"
		detail.Text = name .. "   ·   Cosmetic companion"
		box.PlaceholderText = name
		equip.Text, equip.BackgroundColor3 = if active then "Unequip" else "Equip", if active then W.green else W.violet
	end)
	return 3
end
function Pages.achievements(menu)
	for i, award in Guide.achievements do
		local tint = if award.ore then W.orange else W.aqua
		local title, detail, badge = menu:row(i, award.name, "Achievements", tint)
		menu:watchRow(title.Parent, award.id, function()
			return (menu.player:GetAttribute("Award" .. award.id) or 0) >= award.goal
		end)
		title.Size = UDim2.fromOffset(251, 24)
		title.TextSize = 18
		detail.Position, detail.Size = UDim2.fromOffset(67, 28), UDim2.fromOffset(247, 32)
		detail.TextWrapped = true
		badge.Interactable, badge.AutoButtonColor = false, false
		table.insert(menu.updates, function()
			title.Text, detail.Text = Guide.awardText(award, menu.player)
			local progress = menu.player:GetAttribute("Award" .. award.id) or 0
			badge.Text = if progress >= award.goal then "Earned" else string.format("%d / %d", progress, award.goal)
			badge.BackgroundColor3 = if progress >= award.goal then W.green else W.muted
		end)
	end
	return #Guide.achievements
end

function Pages.index(menu)
	W.title(menu.list, "Collection", 6, 0, 208, 25, 19, W.gold, true)
	W.title(menu.list, "Depth & ore odds", 228, 0, 213, 25, 19, W.aqua, true)
	for i, ore in Ores.list do
		local card = W.frame(menu.list, ore.name, 1, 30 + (i - 1) * 56, 216, 52, W.card, 8)
		menu:watchRow(card, ore.name, function()
			return menu.player:GetAttribute("Found" .. ore.name)
		end)
		local bar = W.frame(card, "Swatch", 5, 7, 6, 38, W.muted, 3)
		local name = W.title(card, "", 17, 1, 193, 21, 16, W.white, true)
		local worth = W.text(card, "", 17, 23, 196, 23, 12, W.muted, true)
		table.insert(menu.updates, function()
			local found = menu.player:GetAttribute("Found" .. ore.name)
			local hidden = ore.secret and not found
			bar.BackgroundColor3 = if hidden then W.muted else ore.color
			name.Text = if hidden then "???" else ore.name .. (if found then "   ✓" else "")
			worth.Text = if hidden
				then "Mine it to identify"
				else string.format(
					"%s G each   ·   %d XP",
					W.number(ore.value * (if menu.player:GetAttribute("DoubleGold") then 2 else 1)),
					ore.xp
				)
		end)
	end
	local y = 30
	for i, layer in Config.Layers do
		local card = W.frame(menu.list, layer.name, 225, y, 222, 106, W.card, 8)
		W.title(card, layer.name, 8, 4, 206, 21, 16, W.white, true)
		local following = Config.Layers[i + 1]
		local start = math.max(Config.DirtLayers, layer.depthBlocks)
		local depth = if following
			then string.format("%d–%d blocks", start, following.depthBlocks - 1)
			else string.format("%d+ blocks", start)
		local d = W.text(card, depth, 8, 25, 202, 17, 13, W.aqua, true)
		d.Name = "Depth"
		local odds = W.text(card, "", 8, 42, 207, 60, 12, W.muted, true)
		odds.TextWrapped = true
		odds.TextYAlignment = Enum.TextYAlignment.Top
		table.insert(menu.updates, function()
			local entries, total = {}, 0
			for _, ore in Ores.list do
				local chance = layer.oreChances[ore.name]
				if chance then
					total += chance
					local label = if ore.secret and not menu.player:GetAttribute("Found" .. ore.name)
						then "???"
						else ore.name
					table.insert(entries, string.format("%s %g%%", label, chance))
				end
			end
			table.insert(entries, 1, string.format("Stone %g%%", 100 - total))
			odds.Text = table.concat(entries, "   ")
		end)
		y += 112
	end
	local card = W.frame(menu.list, "Rock hardness", 225, y, 222, 165, W.card, 8)
	W.title(card, "Stone grades", 8, 3, 203, 23, 16, W.white, true)
	for power, grade in Config.StoneGrades do
		local lineY = 28 + (power - 1) * 22
		W.frame(card, "Swatch", 8, lineY + 3, 15, 15, grade.color, 3)
		W.text(card, grade.name, 29, lineY, 115, 21, 13, W.white, true)
		W.text(card, "P" .. power .. " · " .. grade.depth .. "+", 145, lineY, 70, 21, 12, W.aqua)
	end
	return math.ceil(math.max(30 + #Ores.list * 56, y + 169) / 69)
end
return Pages
