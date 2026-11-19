local Config = {
	LandscapeSeed = 73129,
	ResetAfter = 2400,
	ResetWarning = 20,
	-- Grid coordinates are relative to the entrance. One voxel is four studs.
	Cell = 4,
	Chunk = 8,
	FloorY = -48,
	DirtLayers = 3,
	HallHalfWidth = 40,
	HallFront = -80,
	HallBack = -152,
	BenchFront = -120,
	BenchRows = 4,
	MineBlockTag = "EndlessMiningBlockFolder",
	SiteMin = Vector3.new(-96, -112, -168),
	SiteMax = Vector3.new(96, 40, 0),
	SurfaceMin = Vector3.new(-144, -12, -92),
	SurfaceMax = Vector3.new(144, 92, 156),
	-- Fallback origin when the mine is built without an authored surface.
	Origin = Vector3.new(0, 24, 4),
	SurfaceName = "Citrine Cove",
	Reach = 34,
	StoreName = "EndlessMining_v1",
	LeaseSeconds = 180,
	AutosaveSeconds = 45,
	-- Maximum pattern faces checked per second across all players.
	CellBudget = 2400,
	BurstCells = 100,
}
Config.Layers = {
	{
		depthBlocks = 0,
		name = "Sunstone Hollow",
		oreChances = { Coal = 13, Copper = 5 },
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(151, 153, 158),
	},
	{
		depthBlocks = 27,
		name = "Iron Shelf",
		oreChances = { Coal = 6, Copper = 7, Iron = 8, Gold = 1 },
		material = Enum.Material.Rock,
		color = Color3.fromRGB(132, 136, 143),
	},
	{
		depthBlocks = 90,
		name = "Prism Grotto",
		oreChances = { Coal = 3, Copper = 5, Iron = 9, Gold = 6, Diamond = 2 },
		material = Enum.Material.Slate,
		color = Color3.fromRGB(115, 119, 127),
	},
	{
		depthBlocks = 185,
		name = "Emerald Deep",
		oreChances = { Coal = 2, Copper = 3, Iron = 7, Gold = 8, Diamond = 5, Emerald = 2 },
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(96, 100, 108),
	},
}
function Config.depthInBlocks(depthStuds)
	return math.floor(depthStuds / Config.Cell)
end
function Config.blockCoordinates(localPos)
	-- Count rows down from the dig floor so Y = -27 exactly where Iron Shelf begins.
	return Vector3.new(
		math.floor(localPos.X / Config.Cell),
		-Config.depthInBlocks(Config.FloorY - localPos.Y),
		math.floor(localPos.Z / Config.Cell)
	)
end
function Config.layer(depthStuds)
	local depthBlocks = Config.depthInBlocks(depthStuds)
	for i = #Config.Layers, 1, -1 do
		if depthBlocks >= Config.Layers[i].depthBlocks then
			return Config.Layers[i]
		end
	end
	return Config.Layers[1]
end
function Config.blockCenter(origin, position, normal)
	-- Step just inside the struck brick, including bricks that span several cells.
	local point = position - origin - normal * (Config.Cell * 0.01)
	return origin + ((point / Config.Cell):Floor() + Vector3.one * 0.5) * Config.Cell
end
-- Hardness increases for all materials, including ordinary stone.
Config.HardnessDepths = { 0, 27, 60, 90, 140, 185 }
function Config.strength(localY)
	local depth = Config.depthInBlocks(Config.FloorY - localY)
	for tier = #Config.HardnessDepths, 2, -1 do
		if depth >= Config.HardnessDepths[tier] then
			return tier
		end
	end
	return 1
end
function Config.inHall(p)
	return math.abs(p.X) < Config.HallHalfWidth and p.Z >= Config.HallBack and p.Z < Config.HallFront
end
function Config.inMine(p)
	if p.Y < Config.FloorY then
		return true
	end
	if Config.inHall(p) then
		return p.Y < Config.FloorY + 16
	end
	return p.Z <= 0
		and p.Z >= Config.HallFront
		and math.abs(p.X) < 9
		and math.abs(p.Y - p.Z * Config.FloorY / Config.HallFront - 4) < 8
end
return Config
