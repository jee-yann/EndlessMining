local Config = {
	Seed = 73129,
	-- Grid coordinates are relative to the entrance. One voxel is four studs.
	Cell = 4,
	Chunk = 8,
	DirtThickness = 8,
	DirtMaxDepth = 12,
	MineBlockTag = "EndlessMiningBlockFolder",
	Min = Vector3.new(-96, -1152, -224),
	Max = Vector3.new(96, 40, 0),
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
		depth = 0,
		name = "Sunstone Hollow",
		veinWeights = { Coal = 72, Copper = 28 },
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(151, 153, 158),
	},
	{
		depth = 108,
		name = "Iron Shelf",
		veinWeights = { Coal = 23, Copper = 27, Iron = 44, Gold = 6 },
		material = Enum.Material.Rock,
		color = Color3.fromRGB(132, 136, 143),
	},
	{
		depth = 360,
		name = "Prism Grotto",
		veinWeights = { Coal = 10, Copper = 15, Iron = 36, Gold = 27, Diamond = 12 },
		material = Enum.Material.Slate,
		color = Color3.fromRGB(115, 119, 127),
	},
	{
		depth = 740,
		name = "Emerald Deep",
		veinWeights = { Coal = 6, Copper = 9, Iron = 26, Gold = 28, Diamond = 23, Emerald = 8 },
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(96, 100, 108),
	},
}
function Config.ridgeHeight(seed, x, z)
	-- The bluffs taper into the lagoon. The deeper ore field continues under the water.
	local ridge = 16 + 3 * math.sin(x / 23 + seed % 11) + 2 * math.cos(z / 31)
	ridge -= 7 * math.clamp((math.abs(x) - 12) / 15, 0, 1)
	local shore = math.max(math.clamp((math.abs(x) - 69) / 23, 0, 1), math.clamp((-z - 37) / 48, 0, 1))
	return ridge + (-9 - ridge) * shore
end
function Config.layer(depth)
	for i = #Config.Layers, 1, -1 do
		if depth >= Config.Layers[i].depth then
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
function Config.inside(p)
	return p.X >= Config.Min.X
		and p.X < Config.Max.X
		and p.Y >= Config.Min.Y
		and p.Y < Config.Max.Y
		and p.Z >= Config.Min.Z
		and p.Z < Config.Max.Z
end
return Config
