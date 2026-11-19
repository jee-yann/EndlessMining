local rgb = Color3.fromRGB
-- GameConfig.Layers supplies each region’s vein weights. Hardness gates the pickaxe.
local list = {
	{
		name = "Dirt",
		rarity = "Common",
		value = 1,
		hardness = 1,
		material = Enum.Material.Mud,
		color = rgb(200, 140, 93),
		flash = "Dirt",
		host = true,
	},
	{
		name = "Stone",
		host = true,
		rarity = "Common",
		value = 2,
		hardness = 1,

		material = Enum.Material.Concrete,
		color = rgb(151, 153, 158),
		flash = "Stone",
	},
	{
		name = "Coal",
		rarity = "Common",
		value = 5,
		hardness = 1,

		material = Enum.Material.Asphalt,
		color = rgb(62, 69, 89),
		flash = "Coal seam",
	},
	{
		name = "Copper",
		rarity = "Uncommon",
		value = 12,
		hardness = 2,

		material = Enum.Material.Ground,
		color = rgb(236, 128, 77),
		flash = "Native copper",
	},
	{
		name = "Iron",
		rarity = "Uncommon",
		value = 24,
		hardness = 3,

		material = Enum.Material.Limestone,
		color = rgb(172, 187, 199),
		flash = "Iron vein",
	},
	{
		name = "Gold",
		rarity = "Rare",
		value = 80,
		hardness = 4,

		material = Enum.Material.Sand,
		color = rgb(255, 206, 62),
		flash = "Gold strike!",
	},
	{
		name = "Diamond",
		rarity = "Epic",
		value = 260,
		hardness = 5,

		material = Enum.Material.Glacier,
		color = rgb(85, 223, 255),
		flash = "Diamond discovery!",
	},
	{
		name = "Emerald",
		rarity = "Legendary",
		value = 720,
		hardness = 6,

		material = Enum.Material.LeafyGrass,
		color = rgb(46, 231, 153),
		flash = "Legendary emerald!",
	},
}
local byName, byMaterial = {}, {}
for _, ore in list do
	byName[ore.name] = ore
	byMaterial[ore.material] = ore
end
for _, m in { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt } do
	byMaterial[m] = byName.Stone
end
return { list = list, byName = byName, byMaterial = byMaterial }
