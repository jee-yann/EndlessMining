-- Studio CLI RunScript test. Run in the local build. All changes are in memory.
local Server = game:GetService("ServerScriptService").Server
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology, World = require(Server.Geology), require(Server.MineWorld)
local Pattern = require(Shared.BlockPattern)
local Profile = require(Server.Profile)
assert(Profile.valid(Profile.new()))
local Data = require(Server.DataService)
local stored = Data.claim(nil, "first", 1000)
stored.profile.gold = 137
assert(not Data.claim(stored, "second", 1001))
assert(not Data.claim({ profile = { version = 99 } }, "second", 1001))
local transferred = Data.claim(stored, "second", stored.expires + 1)
assert(transferred.profile.gold == 137)
assert(not Data.commit(transferred, "first", Profile.new(), 2000, false))
local released = Data.commit(transferred, "second", transferred.profile, 2000, true)
assert(not released.owner and Data.claim(released, "third", 2001).profile.gold == 137)
print("PASS save ownership, expired lease, incompatible record, stale writer and release")
local p = Profile.new()
assert(not Profile.buy(p, "Radius"))
p.bag = { Stone = 4, Coal = 3, Copper = 1 }
assert(Profile.used(p) == 8 and Profile.sell(p) == 35 and Profile.used(p) == 0)
assert(Profile.buy(p, "Capacity") and p.gold == 11 and Profile.stat(p, "Capacity") == 80)
p.gold = 1e7
for _, key in require(Shared.Upgrades).order do
	while Profile.buy(p, key) do
	end
	assert(p.levels[key] == #require(Shared.Upgrades).items[key].values)
end
assert(Profile.stat(p, "Speed") == 0.20 and Profile.stat(p, "Power") == 6 and Profile.stat(p, "Capacity") == 7200)
p.bag.Stone = 7201
assert(not Profile.valid(p))
print("PASS sale, costs, level caps, upgrade effects, profile capacity validation")
local retired = Profile.new()
retired.levels.Radius = 4
assert(Data.claim({ profile = retired }, "migration", 0).profile.gold == 234)
assert(retired.levels.Radius == nil and Profile.upgradeSave(retired).gold == 234)
local legacy = Profile.new()
legacy.jobs, legacy.discoveries, legacy.bag, legacy.mined = nil, nil, { Coal = 3 }, 36
legacy.preferences = nil
legacy.bestDepth = 361
local upgraded = Data.claim({ profile = legacy }, "harbor", 0).profile
assert(upgraded.discoveries.Coal and upgraded.jobs == 0)
assert(not Profile.claimJob(upgraded, 2))
assert(Profile.claimJob(upgraded, 1).reward == 25 and not Profile.claimJob(upgraded, 1))
assert(Profile.claimJob(upgraded, 2).reward == 80 and not Profile.claimJob(upgraded, 3))
assert(Profile.sell(upgraded, 2) == 30 and upgraded.gold == 135 and upgraded.discoveries.Coal)
assert(upgraded.preferences.MusicVolume == 55 and upgraded.preferences.SfxVolume == 80)
upgraded.preferences.MusicVolume, upgraded.preferences.MenuMotion = 0, false
local snapshot = Data.commit({ owner = "harbor" }, "harbor", upgraded, 100, true)
local loaded = Data.claim(snapshot, "again", 101).profile
assert(loaded.bestDepth == 361 and Config.depthInBlocks(loaded.bestDepth) == 90)
assert(loaded.preferences.MusicVolume == 0 and not loaded.preferences.MenuMotion)
assert(Profile.valid(loaded) and loaded.jobs == 2 and loaded.discoveries.Coal)
print("PASS legacy ore collection, job order, duplicate claims, doubled sales and reload")

local rimGeo = Geology.new(Config.Seed)
for x = -34, 34, 4 do
	for z = -54, -2, 4 do
		for y = 2, 26, 4 do
			assert(rimGeo:sample(x, y, z) ~= Enum.Material.Grass, "Turf intruded into the pithead")
		end
	end
end
local hashes = {}
assert(Config.blockCoordinates(Vector3.zero) == Vector3.zero)
assert(Config.blockCoordinates(Vector3.new(-0.1, -3.9, 4)) == Vector3.new(-1, 0, 1))
assert(Config.blockCoordinates(Vector3.new(7.9, -4, -4.1)) == Vector3.new(1, -1, -2))
for i = 2, #Config.Layers do
	local layer = Config.Layers[i]
	local boundary = layer.depthBlocks * Config.Cell
	assert(Config.layer(boundary - 0.1) == Config.Layers[i - 1] and Config.layer(boundary) == layer)
	assert(Config.blockCoordinates(Vector3.new(0, -boundary, 0)).Y == -layer.depthBlocks)
end
for _, seed in { 11, 73129, 91003, 73129 } do
	local geo = Geology.new(seed)
	local hash, seen, lodes = 0, {}, 0
	local rich, solid = 0, 0
	for x = Config.Min.X + 2, Config.Max.X - 1, 8 do
		for z = Config.Min.Z + 2, Config.Max.Z - 1, 8 do
			for y = Config.Min.Y + 2, -2, 8 do
				local mat = geo:sample(x, y, z)
				local ore = Ores.byMaterial[mat]
				if ore and y < -12 then
					solid += 1
					if not ore.host then
						rich += 1
					end
				end
				if ore then
					assert(ore.host or Config.layer(-y).veinWeights[ore.name], "Ore outside its region")
					if ore.name == "Dirt" then
						assert(-y <= Config.DirtMaxDepth)
					end
					seen[ore.name] = true
				end
				hash = (hash * 31 + mat.Value) % 1000000007
			end
		end
	end
	for _, v in geo.veins do
		if v.lode then
			lodes += 1
		end
	end
	for _, ore in Ores.list do
		assert(seen[ore.name], ore.name)
	end
	assert(lodes > 0 and rich / solid > 0.20 and rich / solid < 0.55)
	print("ORE_DENSITY", seed, rich / solid)
	if hashes[seed] then
		assert(hashes[seed] == hash)
	end
	hashes[seed] = hash
	print("PASS seed", seed, "sample hash", hash, "rich pockets", lodes)
end
assert(hashes[11] ~= hashes[73129] and hashes[91003] ~= hashes[73129])

for _, layer in Config.Layers do
	local counts, total, weightSum = {}, 0, 0
	for _, w in layer.veinWeights do
		weightSum += w
	end
	for seed = 1, 45 do
		local geo = Geology.new(seed)
		for x = -3, 2 do
			for z = -7, -1 do
				local vein = geo:vein(x, math.floor(-(layer.depthBlocks * Config.Cell + 50) / 32), z)
				counts[vein.ore.name] = (counts[vein.ore.name] or 0) + 1
				total += 1
			end
		end
	end
	for name, weight in layer.veinWeights do
		assert(
			math.abs((counts[name] or 0) / total - weight / weightSum) < 0.05,
			layer.name .. " " .. name .. " vein frequency"
		)
	end
end
print("PASS region-specific vein odds")
local surface = workspace.CitrineCove
local world = World.new(Config.Seed, surface)
local mapCopy = surface:Clone()
local site = require(Server.MineSite).bind(mapCopy, world)
assert(mapCopy.PrimaryPart and not mapCopy:FindFirstChild("EditFace"))
assert(site.spawn:IsA("SpawnLocation") and site.spawn.Neutral)
assert(site.stations.Sell:IsA("ProximityPrompt") and site.stations.Shop:IsA("ProximityPrompt"))
mapCopy.Parent = workspace
local onMap = RaycastParams.new()
onMap.FilterType = Enum.RaycastFilterType.Include
onMap.FilterDescendantsInstances = { mapCopy }
onMap.RespectCanCollide = true
local function floorAt(x, z)
	return workspace:Raycast(world.origin + Vector3.new(x, 4, z), Vector3.new(0, -7, 0), onMap)
end
for _, x in { -3, 0, 3 } do
	local lastY = world.origin.Y
	for z = (site.spawn.Position - world.origin).Z, 0, -0.5 do
		local floor = floorAt(x, z)
		assert(floor and math.abs(floor.Position.Y - lastY) < 1, "Landing-to-mine path at " .. z)
		lastY = floor.Position.Y
	end
end
local highlands = mapCopy["Citrine Highlands"]
local rimParams = RaycastParams.new()
rimParams.FilterType = Enum.RaycastFilterType.Include
rimParams.FilterDescendantsInstances = { highlands["Rock rim"] }
rimParams.RespectCanCollide = true
for angle = 0, 359 do
	local theta = math.rad(angle)
	local hit = workspace:Raycast(
		world.origin + Vector3.new(0, 7, 52),
		Vector3.new(math.sin(theta), 0, math.cos(theta)) * 230,
		rimParams
	)
	assert(hit, "Open shoreline at " .. angle .. " degrees")
end
for _, cell in
	{ Vector2.new(0, 125), Vector2.new(-83, 76), Vector2.new(88, 96), Vector2.new(-80, 31), Vector2.new(81, 31) }
do
	assert(floorAt(cell.X, cell.Y), "Outer promenade floor at " .. tostring(cell))
end
for _, name in { "Exchange lights", "Workshop lights" } do
	local lamps = highlands[name]
	assert(
		lamps:FindFirstChildWhichIsA("PointLight", true) and lamps:FindFirstChildWhichIsA("SurfaceLight", true),
		name
	)
end
for _, x in { -41, 41 } do
	for z = 20, 42 do
		assert(floorAt(x, z), "Incomplete creek crossing")
	end
end
assert(not mapCopy["Harbor Plaza"]:FindFirstChild("Core samples"))
local exhibit = mapCopy["Harbor Plaza"].Book
for _, ore in Ores.list do
	assert(exhibit:FindFirstChild(ore.name .. " sample") and exhibit:FindFirstChild(ore.name .. " label"))
end
assert(not floorAt(10, 32), "The inlet should pass completely under the bridge")
assert(not floorAt(0, -10), "The gallery floor must be excavatable")
assert(
	not workspace:Raycast(world.origin + Vector3.new(0, 6, -6), Vector3.new(0, 0, -42), onMap),
	"The starter seam must be clear of scenery"
)
for _, name in { "Sell", "Shop" } do
	local prompt = site.stations[name]
	local pad = prompt.Parent.Position - world.origin
	assert(floorAt(pad.X, pad.Z) and math.abs(pad.Z - 15) < prompt.MaxActivationDistance)
end
for _, name in { "Jobs", "Book", "Store" } do
	local pad = site.stations[name].Parent.Position - world.origin
	assert(floorAt(pad.X, pad.Z), name)
end
for _, key in { "Server", "Friends" } do
	local panel = site.court[key].Standings
	assert(panel.Position.Z > site.spawn.Position.Z + 20)
	assert(panel.Lettering.Row5:IsA("TextLabel"))
end
local ranks = require(Server.Standings).top({
	[8] = { name = "Later", score = 40 },
	[1] = { name = "Earlier", score = 40 },
	[3] = { name = "Deep", score = 90 },
})
assert(#ranks == 3 and ranks[1]:find("Deep") and ranks[2]:find("Earlier"))
for _, pair in { { "Sell", "Exchange lights" }, { "Shop", "Workshop lights" } } do
	local group = site.stations[pair[1]].Parent.Parent
	assert(group["Name tag"]:FindFirstChildOfClass("BillboardGui"))
	assert(highlands[pair[2]]:FindFirstChildWhichIsA("PointLight", true).Brightness < 0.5)
end
for _, key in { "Jobs", "Store", "Book" } do
	local stall = site.stations[key].Parent.Parent
	assert(stall:FindFirstChildWhichIsA("BillboardGui", true) and stall:FindFirstChildWhichIsA("PointLight", true))
end
local back = highlands["Cableway trail"]
local groundParams = RaycastParams.new()
groundParams.FilterType, groundParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { back }
for _, pos in { Vector2.new(-89, -57), Vector2.new(-29, -65), Vector2.new(35, -63), Vector2.new(91, -53) } do
	local foot = workspace:Raycast(world.origin + Vector3.new(pos.X, 13, pos.Y), -Vector3.yAxis * 2, groundParams)
	assert(foot and foot.Instance.Name == "Tower footing", "Unsupported tram tower")
end
for _, side in { -1, 1 } do
	local path = {
		Vector2.new(116, 7),
		Vector2.new(116, -38),
		Vector2.new(105, -50),
		Vector2.new(83, -65),
		Vector2.new(73, -73),
		Vector2.new(0, -73),
	}
	local prev
	for i = 2, #path do
		local steps = math.ceil((path[i] - path[i - 1]).Magnitude)
		for t = 0, steps do
			local at = path[i - 1]:Lerp(path[i], t / steps)
			local height = math.min(11.95, -0.05 + (9 - at.Y) * 12 / 62)
			local feet = world.origin + Vector3.new(side * at.X, height, at.Y)
			local hit = workspace:Raycast(feet + Vector3.yAxis * 2, -Vector3.yAxis * 4, onMap)
			assert(hit and (not prev or math.abs(hit.Position.Y - prev) < 0.8), "Ridge trail gap at " .. tostring(at))
			assert(
				not workspace:Raycast(feet + Vector3.yAxis * 0.9, Vector3.yAxis * 6, onMap),
				"Ridge trail clearance at " .. tostring(at)
			)
			prev = hit.Position.Y
		end
	end
end
print("PASS harbor paths, 360 rock rim rays, lit service pads, bridge crossing and edit-face removal")
local terrainCells = workspace.Terrain:CountCells()
world:generate()
assert(workspace.FallenPartsDestroyHeight < world.origin.Y + Config.Min.Y)
assert(
	not mapCopy["Harbor Plaza"]:FindFirstChild("Lift")
		and not mapCopy:FindFirstChild("Lift Landings")
		and not mapCopy:FindFirstChild("Deep mine trail")
)
for _, depth in { 128, 448, 1024 } do
	assert(
		world:oreAt(world.origin + Vector3.new(-14, -depth + 6, -34)),
		"Former station should contain mineable blocks"
	)
end
local roof
for _, part in world.grid.folder:GetChildren() do
	if part.Name == "Turf" then
		roof = Config.blockCenter(world.origin, part.Position + Vector3.yAxis * part.Size.Y * 0.5, Vector3.yAxis)
		break
	end
end
assert(roof and not world:oreAt(roof) and not next((world:excavate({ roof }))), "Landscape turf was mined")
local hostCells = {}
for _, part in world.grid.folder:GetChildren() do
	if
		(part.Name == "Stone" or part.Name == "Dirt")
		and math.abs(part.Position.X - world.origin.X) > 25
		and not hostCells[part.Name]
	then
		hostCells[part.Name] =
			Config.blockCenter(world.origin, part.Position + Vector3.yAxis * part.Size.Y * 0.5, Vector3.yAxis)
	end
	if hostCells.Dirt and hostCells.Stone then
		break
	end
end
assert(hostCells.Dirt and hostCells.Stone)
local hostLoot, hostFinds = world:excavate({ hostCells.Dirt, hostCells.Stone })
assert(hostLoot.Dirt == 1 and hostLoot.Stone == 1 and not next(hostFinds), "Base materials filled an ore popup")
mapCopy:Destroy()
local bricks = world.grid.folder:GetChildren()
assert(#bricks > 0 and #bricks < 5800, "Starting brick count: " .. #bricks)
for _, part in bricks do
	assert(part:IsA("Part") and part.Material == Enum.Material.Plastic and part.Anchored and part.CanCollide)
	assert(part.TopSurface == Enum.SurfaceType.Studs and part.BackSurface == Enum.SurfaceType.Studs)
end
assert(workspace.Terrain:CountCells() == terrainCells)
print("PASS studded plastic mine with", #bricks, "starting parts")
local Mining = require(Server.MiningService)
local rig = Instance.new("Model")
local human = Instance.new("Humanoid")
human.Parent = rig
local head = Instance.new("Part")
head.Name, head.Anchored, head.Position, head.Parent = "Head", true, world.origin + Vector3.new(-3, 6, -8), rig
rig.Parent = workspace
local face = workspace:Raycast(head.Position + Vector3.new(0, 0, -2), Vector3.new(0, 0, -32))
assert(face and face.Instance.Parent == world.grid.folder)
local anchor = Config.blockCenter(world.origin, face.Position, face.Normal)
local normal = face.Normal
assert(Mining.target(world, rig, anchor, normal))
assert(not Mining.target(world, rig, world.origin + Vector3.new(0, 0, -100), normal))
assert(not Mining.target(world, rig, anchor, -normal))
assert(not Mining.target(world, rig, anchor, Vector3.one))
local post = Instance.new("Part")
post.Size, post.Position, post.Anchored, post.Parent =
	Vector3.new(5, 8, 2), head.Position + Vector3.new(0, 0, -5), true, workspace
assert(not Mining.target(world, rig, anchor, normal))
post:Destroy()
local first = Mining.selection(world, rig, anchor, normal, 1, 36)
assert(#first == 1 and first[1] == anchor)
assert(#Mining.selection(world, rig, anchor, normal, 1, 0) == 0)
local loot, finds = world:excavate(first)
assert(not next((world:excavate(first))))
assert(finds.Coal == anchor and not finds.Stone and not finds.Dirt)
assert(loot.Coal == 1 and world:oreAt(anchor) == nil)
local deeper = workspace:Raycast(head.Position, (anchor + normal * 2 - head.Position).Unit * 45)
assert(deeper and deeper.Instance.Parent == world.grid.folder and deeper.Position.Z < face.Position.Z - 3)
assert(world:oreAt(anchor - normal * Config.Cell) ~= nil, "One hit takes just the highlighted layer")
human.Health = 0
assert(not Mining.target(world, rig, anchor, normal))
rig:Destroy()
print("PASS single-block cut, capacity, reach, obstructions and shared depletion")
local selected, locked =
	Pattern.select(world.origin, world.origin + Vector3.new(2, -82, -98), Ores.byName.Diamond, 1, 36)
assert(#selected == 0 and locked == Ores.byName.Diamond)
-- Cut straight down through chunk boundaries.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { world.grid.folder }
local Blocks = require(Server.MineBlocks)
local top = Vector3.new(-42, -82, -98)
local mid = ((top - Config.Min) / Config.Cell):Floor()
local low, high = mid - Vector3.new(3, 20, 3), mid + Vector3.new(3, 4, 3)
for z = low.Z, high.Z do
	for y = low.Y, high.Y do
		local id = if y > mid.Y then 0 else Blocks.codes[Ores.byName.Diamond.material]
		buffer.fill(world.grid.cells, Blocks.index(low.X, y, z), id, 7)
	end
end
world.grid:refresh(low, high)
local start = world.origin + top + Vector3.yAxis * 14
local worst, total = 0, 0
for i = 1, 20 do
	local floor = workspace:Raycast(start, -Vector3.yAxis * 180, params)
	assert(floor and floor.Normal == Vector3.yAxis)
	local c = Config.blockCenter(world.origin, floor.Position, floor.Normal)
	local eye = c + Vector3.yAxis * 16
	local t = os.clock()
	assert(Pattern.visiblePart(eye, c, Vector3.yAxis, params))
	local batch = Pattern.select(world.origin, c, world:oreAt(c), 6, 1)
	assert(#batch == 1 and batch[1] == c)
	local yield = world:excavate(batch)
	local amount = 0
	for _, n in yield do
		amount += n
	end
	assert(amount == 1)
	local elapsed = (os.clock() - t) * 1000
	worst, total = math.max(worst, elapsed), total + elapsed
end
print(string.format("PASS 20 successive single-block cuts; mean %.2f ms, max %.2f ms", total / 20, worst))
print("MINING_TESTS_PASSED")
