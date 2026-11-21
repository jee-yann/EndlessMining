local rgb = Color3.fromRGB
-- GameConfig.Layers supplies each region’s per-block odds. Hardness gates the pickaxe.
local list = {
	{
		name = "Dirt",
		rarity = "Common",
		value = 1,
		xp = 0,
		hardness = 1,
		material = Enum.Material.Mud,
		color = rgb(151, 98, 65),
		flash = "Dirt",
		host = true,
	},
	{
		name = "Stone",
		host = true,
		rarity = "Common",
		value = 2,
		xp = 0,
		hardness = 1,
		material = Enum.Material.Concrete,
		color = rgb(151, 153, 158),
		flash = "Stone",
	},
	{
		name = "Coal",
		rarity = "Common",
		value = 5,
		xp = 3,
		hardness = 1,
		material = Enum.Material.Asphalt,
		color = rgb(79, 82, 95),
		flash = "Coal seam",
	},
	{
		name = "Copper",
		rarity = "Uncommon",
		value = 12,
		xp = 5,
		hardness = 2,
		material = Enum.Material.Ground,
		color = rgb(195, 122, 84),
		flash = "Native copper",
	},
	{
		name = "Iron",
		rarity = "Uncommon",
		value = 24,
		xp = 7,
		hardness = 3,
		material = Enum.Material.Limestone,
		color = rgb(172, 187, 199),
		flash = "Iron vein",
	},
	{
		name = "Gold",
		rarity = "Rare",
		value = 80,
		xp = 9,
		hardness = 4,
		material = Enum.Material.Sand,
		color = rgb(255, 206, 62),
		flash = "Gold strike!",
	},
	{
		name = "Diamond",
		rarity = "Epic",
		value = 260,
		xp = 11,
		hardness = 5,
		material = Enum.Material.Glacier,
		color = rgb(85, 223, 255),
		flash = "Diamond discovery!",
	},
	{
		name = "Emerald",
		rarity = "Legendary",
		value = 720,
		xp = 13,
		hardness = 6,
		material = Enum.Material.LeafyGrass,
		color = rgb(65, 204, 63),
		flash = "Legendary emerald!",
	},
	{
		name = "Amethyst",
		rarity = "Mythic",
		value = 1700,
		xp = 29,
		hardness = 6,
		material = Enum.Material.Glass,
		color = rgb(154, 74, 219),
		flash = "Amethyst geode",
		secret = true,
	},
	{
		name = "Sapphire",
		rarity = "Mythic",
		value = 2400,
		xp = 36,
		hardness = 6,
		material = Enum.Material.Marble,
		color = rgb(54, 98, 243),
		flash = "Sapphire crystal",
		secret = true,
	},
	{
		name = "Emberglass",
		rarity = "Mythic",
		value = 3600,
		xp = 48,
		hardness = 6,
		material = Enum.Material.CrackedLava,
		color = rgb(255, 86, 128),
		flash = "Emberglass",
		secret = true,
	},
	{
		name = "Starfall",
		rarity = "Celestial",
		value = 14000,
		xp = 160,
		hardness = 6,
		material = Enum.Material.Foil,
		color = rgb(181, 133, 255),
		flash = "Starfall",
		secret = true,
	},
}
local byName, byMaterial = {}, {}
for _, ore in list do
	byName[ore.name] = ore
	byMaterial[ore.material] = ore
end
for _, m in { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Ice } do
	byMaterial[m] = byName.Stone
end
local effort = {
	Dirt = 0.72,
	Stone = 1,
	Coal = 1.15,
	Copper = 1.4,
	Iron = 1.7,
	Gold = 2.05,
	Diamond = 2.5,
	Emerald = 3,
	Amethyst = 3.4,
	Sapphire = 3.75,
	Emberglass = 4,
	Starfall = 5.5,
}
local function cutTime(base, ore, strength, charges, temperMultiplier)
	local tempered = (charges or 0) > 0 and math.max(strength or 1, ore.hardness) >= 2
	return base * effort[ore.name] * (1 + 0.45 * ((strength or 1) - 1)) * (if tempered
		then temperMultiplier or 0.8
		else 1),
		tempered
end
local rarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Celestial = 7 }
local function carried(player)
	local entries = {}
	for _, ore in list do
		local amount = player:GetAttribute("Held" .. ore.name) or 0
		if amount > 0 then
			table.insert(entries, { ore = ore, amount = amount })
		end
	end
	table.sort(entries, function(a, b)
		if a.ore.rarity ~= b.ore.rarity then
			return rarityRank[a.ore.rarity] > rarityRank[b.ore.rarity]
		end
		if a.amount ~= b.amount then
			return a.amount > b.amount
		end
		return a.ore.value > b.ore.value
	end)
	return entries
end
return { list = list, byName = byName, byMaterial = byMaterial, cutTime = cutTime, carried = carried }
