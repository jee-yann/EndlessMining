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

local titles = require(Shared.Expeditions)
local oldMiner = Profile.new()
oldMiner.xp, oldMiner.mined = nil, 38
assert(Data.claim({ profile = oldMiner }, "xp", 0).profile.xp == 76)
for i, title in titles.ranks do
	local level = titles.level(titles.levelXP(title.level))
	assert(level == title.level and titles.rank(level) == i)
end
local hashes = {}
for _, seed in { 11, 73129, 91003, 73129 } do
	local geo = Geology.new(seed)
	local hash = 0
	for _, layer in Config.Layers do
		local counts, total = {}, 0
		for x = -65, 65 do
			for z = -33, 33 do
				for row = 0, 2 do
					assert(geo:material(Vector3.new(x, -row - 1, z)) == Ores.byName.Dirt.material)
				end
				local mat = geo:material(Vector3.new(x, -layer.depthBlocks - 9, z))
				local ore = Ores.byMaterial[mat]
				if ore then
					assert(ore.name ~= "Dirt")
					counts[ore.name] = (counts[ore.name] or 0) + 1
					total += 1
				end
				hash = (hash * 31 + mat.Value) % 1000000007
			end
		end
		assert(counts.Stone / total > 0.70, layer.name)
		for name, chance in layer.oreChances do
			assert(math.abs((counts[name] or 0) / total - chance / 100) < 0.025, name)
		end
	end
	if hashes[seed] then
		assert(hashes[seed] == hash)
	end
	hashes[seed] = hash
end
assert(hashes[11] ~= hashes[73129] and hashes[91003] ~= hashes[73129])
assert(Config.blockCoordinates(Vector3.new(-0.1, Config.FloorY - 108.5, -9)) == Vector3.new(-1, -27, -3))
print("PASS three dirt layers, independent regional odds, repeatable fields and saved title levels")
local surface = workspace.CitrineCove
local world = World.new(Config.LandscapeSeed, surface)
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
for z = -2, -79, -1 do
	local grade = 0.6 * z
	for _, x in { -5, 0, 5 } do
		local base = world.origin + Vector3.new(x, grade, z)
		local floor = workspace:Raycast(base + Vector3.yAxis * 1.2, -Vector3.yAxis * 2.4, onMap)
		assert(
			floor and floor.Instance.Name == "Entrance grade",
			"Ramp at " .. z .. " " .. (floor and floor.Instance.Name or "gap")
		)
		local overhead = workspace:Raycast(base + Vector3.yAxis * 0.4, Vector3.yAxis * 7, onMap)
		assert(not overhead, "Headroom at " .. z .. " " .. (overhead and overhead.Instance.Name or ""))
	end
end
for k, prompt in site.stations do
	assert(prompt.Parent["Interaction pad"].Frame.Shine:FindFirstChildOfClass("UIGradient"), k)
end
for _, part in mapCopy["Island and lagoon"]:GetDescendants() do
	if part:IsA("Part") and (part.Name == "Distant grass" or part.Name == "Distant sandbar") then
		assert(part.TopSurface == Enum.SurfaceType.Studs and part.Material == Enum.Material.Plastic, part.Name)
	elseif part:IsA("WedgePart") and (part.Name == "Distant grass" or part.Name == "Distant sandbar") then
		assert(
			(if part.CFrame.RightVector.Y > 0 then part.RightSurface else part.LeftSurface) == Enum.SurfaceType.Studs,
			part.Name
		)
	end
end
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
local grid = world.grid
local count = #grid.folder:GetChildren()
assert(count > 300 and count < 700, "Starting shell parts: " .. count)
local function center(x, y, z)
	return grid:center(Vector3.new(x, y, z))
end
local function entry(x, y, z)
	local chunk, i = grid:slot(Vector3.new(x, y, z), false)
	return chunk and chunk[i]
end
local function cut(x, y, z)
	local target = center(x, y, z)
	local original = world:oreAt(target)
	assert(original and entry(x, y, z), "Unexposed target " .. tostring(target))
	local loot = world:excavate({ target })
	assert(loot[original.name] == 1 and world:oreAt(target) == nil)
	return original.name
end
-- A player can go from the path to either end of the actual work floor.
local allFloor = RaycastParams.new()
allFloor.FilterType = Enum.RaycastFilterType.Include
allFloor.FilterDescendantsInstances = { mapCopy, grid.folder }
for z = -80, -150, -1 do
	local height = if z >= -120 then -48 elseif z <= -144 then -64 else -48 + (z + 120) * 16 / 24
	local hit = workspace:Raycast(world.origin + Vector3.new(33, height + 1.5, z), -Vector3.yAxis * 3, allFloor)
	assert(hit, "Lower workface walking gap at " .. z)
end
local params = RaycastParams.new()
params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { grid.folder }
assert(not entry(0, -25, -700) and not entry(2, -7, -44), "Untouched caves or distant ore replicated")
for row = 1, 4 do
	local name = cut(-3, -row, -24)
	assert((name == "Dirt") == (row <= 3))
end
-- Reveal the starter cavern through a real cut. Only its discovered shell appears.
for row = 5, 7 do
	if entry(2, -row, -37) then
		cut(2, -row, -37)
	end
end
for z = -38, -45, -1 do
	local p = entry(2, -7, z)
	if p then
		cut(2, -7, z)
	end
end
assert(entry(2, -7, -44) == false and not world:oreAt(center(2, -7, -44)), "Starter cave did not open")
local ceiling = workspace:Raycast(center(2, -7, -44), Vector3.yAxis * 40, params)
local floor = workspace:Raycast(center(2, -7, -44), -Vector3.yAxis * 40, params)
assert(floor and ceiling and ceiling.Position.Y - floor.Position.Y >= 12, "Walkable cavern with a solid shell")
-- Extend a level heading far outside the old island bounds and then cut sideways.
for z = -39, -142, -1 do
	cut(-5, -3, z)
end
for x = -4, 58 do
	cut(x, -3, -142)
end
assert(not entry(1000, -3, -1300), "Generated an untouched chunk")
local target = center(58, -3, -143)
local Mining = require(Server.MiningService)
local rig = Instance.new("Model")
local human = Instance.new("Humanoid")
human.Parent = rig
local head = Instance.new("Part")
head.Name, head.Size, head.Anchored, head.Position, head.Parent =
	"Head", Vector3.one, true, center(58, -3, -142) + Vector3.zAxis, rig
rig.Parent = workspace
assert(Mining.target(world, rig, target, Vector3.zAxis))
assert(not Mining.target(world, rig, target, -Vector3.zAxis) and not Mining.target(world, rig, target, Vector3.one))
local post = Instance.new("Part")
post.Anchored, post.Size, post.Position, post.Parent =
	true, Vector3.one * 0.65, center(58, -3, -142) - Vector3.zAxis * 0.4, workspace
assert(not Mining.target(world, rig, target, Vector3.zAxis))
post:Destroy()
assert(#Mining.selection(world, rig, target, Vector3.zAxis, 1, 0) == 0)
assert(#Mining.selection(world, rig, target, Vector3.zAxis, 1, 1) == 1)
assert(world:excavate({ target }).Dirt == 1 and not next((world:excavate({ target }))))
rig:Destroy()
for _, ore in Ores.list do
	local hard = center(0, -61, 0)
	local selected, locked, required = Pattern.select(world.origin, hard, ore, 1, 1)
	assert(#selected == 0 and locked == ore and required >= 3)
	assert(Ores.cutTime(0.8, ore, 3) > Ores.cutTime(0.8, ore, 1))
end
assert(workspace.Terrain:CountCells() == terrainCells)
local old = world.generation
world.seed = 90237
world:generate()
assert(world.generation == old + 1 and world.removed == 0 and world:oreAt(center(-3, -1, -24)).name == "Dirt")
assert(not entry(58, -3, -142) and not entry(2, -7, -44))
print("PASS cave discovery, wide floor, clearance, depth gates, distant chunk cuts, shared depletion and reset")
print("MINING_TESTS_PASSED")
