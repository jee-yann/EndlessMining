local Config = {
	Seed = 73129,
	-- Grid coordinates are relative to the entrance. One voxel is four studs.
	Cell = 4,
	Chunk = 8,
	MineBlockTag = "EndlessMiningBlockFolder",
	Min = Vector3.new(-96, -352, -224),
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
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(213, 156, 111),
	},
	{
		depth = 64,
		name = "Iron Shelf",
		material = Enum.Material.Rock,
		color = Color3.fromRGB(126, 139, 157),
	},
	{
		depth = 152,
		name = "Prism Grotto",
		material = Enum.Material.Slate,
		color = Color3.fromRGB(97, 117, 158),
	},
	{
		depth = 252,
		name = "Emerald Deep",
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(87, 90, 127),
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
