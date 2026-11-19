local rgb = Color3.fromRGB
-- Weight is the relative chance of a vein nucleus at its preferred depth.
-- Stone fills the remaining host rock. Hardness is the minimum power tier.
local list = {
	{
		name = "Stone",
		rarity = "Common",
		value = 2,
		hardness = 1,
		weight = 0,
		min = 0,
		preferred = 0,
		material = Enum.Material.Concrete,
		color = rgb(213, 156, 111),
		flash = "Stone",
	},
	{
		name = "Coal",
		rarity = "Common",
		value = 5,
		hardness = 1,
		weight = 75,
		min = 0,
		preferred = 16,
		material = Enum.Material.Asphalt,
		color = rgb(62, 69, 89),
		flash = "Coal seam",
	},
	{
		name = "Copper",
		rarity = "Uncommon",
		value = 12,
		hardness = 2,
		weight = 42,
		min = 0,
		preferred = 58,
		material = Enum.Material.Ground,
		color = rgb(236, 128, 77),
		flash = "Native copper",
	},
	{
		name = "Iron",
		rarity = "Uncommon",
		value = 24,
		hardness = 3,
		weight = 38,
		min = 64,
		preferred = 128,
		material = Enum.Material.Limestone,
		color = rgb(172, 187, 199),
		flash = "Iron vein",
	},
	{
		name = "Gold",
		rarity = "Rare",
		value = 80,
		hardness = 4,
		weight = 17,
		min = 112,
		preferred = 290,
		material = Enum.Material.Sand,
		color = rgb(255, 206, 62),
		flash = "Gold strike!",
	},
	{
		name = "Diamond",
		rarity = "Epic",
		value = 260,
		hardness = 5,
		weight = 8,
		min = 280,
		preferred = 505,
		material = Enum.Material.Glacier,
		color = rgb(85, 223, 255),
		flash = "Diamond discovery!",
	},
	{
		name = "Emerald",
		rarity = "Legendary",
		value = 720,
		hardness = 6,
		weight = 3,
		min = 640,
		preferred = 880,
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
	byMaterial[m] = list[1]
end
return { list = list, byName = byName, byMaterial = byMaterial }
