local Config = {
	LandscapeSeed = 73129,
	ResetAfter = 2400,
	ResetWarning = 20,
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
		depthBlocks = 0,
		name = "Sunstone Hollow",
		oreChances = { Coal = 25, Copper = 9 },
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(151, 153, 158),
	},
	{
		depthBlocks = 27,
		name = "Iron Shelf",
		oreChances = { Coal = 9, Copper = 12, Iron = 15, Gold = 2 },
		material = Enum.Material.Rock,
		color = Color3.fromRGB(132, 136, 143),
	},
	{
		depthBlocks = 90,
		name = "Prism Grotto",
		oreChances = { Coal = 4, Copper = 7, Iron = 15, Gold = 11, Diamond = 4 },
		material = Enum.Material.Slate,
		color = Color3.fromRGB(115, 119, 127),
	},
	{
		depthBlocks = 185,
		name = "Emerald Deep",
		oreChances = { Coal = 3, Copper = 4, Iron = 11, Gold = 12, Diamond = 10, Emerald = 3 },
		material = Enum.Material.Basalt,
		color = Color3.fromRGB(96, 100, 108),
	},
}
function Config.ridgeHeight(seed, x, z)
	-- The bluffs taper into the lagoon. The deeper ore field continues under the water.
	local ridge = 16 + 3 * math.sin(x / 23 + seed % 11) + 2 * math.cos(z / 31)
	ridge -= 7 * math.clamp((math.abs(x) - 12) / 15, 0, 1)
	local shore = math.max(math.clamp((math.abs(x) - 69) / 23, 0, 1), math.clamp((-z - 37) / 48, 0, 1))
	local top = ridge + (-9 - ridge) * shore
	-- Keep the voxel roof below the walkable surface of the authored ridge trail.
	if z <= -24 and z >= -105 and x >= -79 and x < 79 then
		local trailTop
		if z >= -53 then
			trailTop = if x >= -12 and x < 19.5 then 16.4 - (-z - 23) * 2.4 / 30 else 1.6 + (-z - 24) * 10.35 / 29
		elseif x >= -12 and x < 19.5 and z >= -63 then
			trailTop = 14 - (-z - 53) * 2.05 / 10
		else
			trailTop = 11.95
		end
		top = math.min(top, trailTop - Config.Cell / 2 - 0.1)
	end
	return top
end
function Config.depthInBlocks(depthStuds)
	return math.floor(depthStuds / Config.Cell)
end
function Config.blockCoordinates(localPos)
	-- Count rows down from the entrance so Y = -27 exactly where Iron Shelf begins.
	return Vector3.new(
		math.floor(localPos.X / Config.Cell),
		-Config.depthInBlocks(-localPos.Y),
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
function Config.inside(p)
	return p.X >= Config.Min.X
		and p.X < Config.Max.X
		and p.Y >= Config.Min.Y
		and p.Y < Config.Max.Y
		and p.Z >= Config.Min.Z
		and p.Z < Config.Max.Z
end
function Config.inMine(p)
	return Config.inside(p) and (p.Y < -8 or (math.abs(p.X) <= 8.5 and p.Z >= -48 and p.Y < 12))
end
return Config
