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
assert(Profile.buy(p, "Radius") and p.gold == 11 and Profile.stat(p, "Radius") == 2)
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
local legacy = Profile.new()
legacy.jobs, legacy.discoveries, legacy.bag, legacy.mined = nil, nil, { Coal = 3 }, 36
local upgraded = Data.claim({ profile = legacy }, "harbor", 0).profile
assert(upgraded.discoveries.Coal and upgraded.jobs == 0)
assert(not Profile.claimJob(upgraded, 2))
assert(Profile.claimJob(upgraded, 1).reward == 25 and not Profile.claimJob(upgraded, 1))
assert(Profile.claimJob(upgraded, 2).reward == 80 and not Profile.claimJob(upgraded, 3))
assert(Profile.sell(upgraded, 2) == 30 and upgraded.gold == 135 and upgraded.discoveries.Coal)
local snapshot = Data.commit({ owner = "harbor" }, "harbor", upgraded, 100, true)
local loaded = Data.claim(snapshot, "again", 101).profile
assert(Profile.valid(loaded) and loaded.jobs == 2 and loaded.discoveries.Coal)
print("PASS legacy ore collection, job order, duplicate claims, doubled sales and reload")

local hashes = {}
for _, seed in { 11, 73129, 91003, 73129 } do
	local geo = Geology.new(seed)
	local hash, seen, lodes = 0, {}, 0
	for x = Config.Min.X + 2, Config.Max.X - 1, 8 do
		for z = Config.Min.Z + 2, Config.Max.Z - 1, 8 do
			for y = Config.Min.Y + 2, -2, 8 do
				local mat = geo:sample(x, y, z)
				local ore = Ores.byMaterial[mat]
				if ore then
					assert(-y >= ore.min)
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
	assert(lodes > 0)
	if hashes[seed] then
		assert(hashes[seed] == hash)
	end
	hashes[seed] = hash
	print("PASS seed", seed, "sample hash", hash, "rich pockets", lodes)
end
assert(hashes[11] ~= hashes[73129] and hashes[91003] ~= hashes[73129])

local surface = workspace.CitrineCove
local world = World.new(Config.Seed, surface)
local mapCopy = surface:Clone()
local site = require(Server.Quarry).bind(mapCopy, world)
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
for _, name in { "Jobs", "Book", "Store", "Lift" } do
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
for _, key in { "Lift", "Jobs", "Store", "Book" } do
	local stall = site.stations[key].Parent.Parent
	assert(stall:FindFirstChildWhichIsA("BillboardGui", true) and stall:FindFirstChildWhichIsA("PointLight", true))
end
for _, stop in require(Shared.Expeditions).stops do
	if stop.floor then
		local base = world.origin + stop.floor
		local hit = workspace:Raycast(base + Vector3.new(0, 5, 2), -Vector3.yAxis * 7, onMap)
		assert(hit and math.abs(hit.Position.Y - base.Y) < 1, stop.name .. " floor")
		assert((site.stations["Lift" .. stop.key].Parent.Position - base).Magnitude < 9)
		local geology = Geology.new(Config.Seed)
		assert(geology:sample(stop.floor.X + 2, stop.floor.Y + 6, stop.floor.Z + 2) == Enum.Material.Air)
		assert(geology:sample(stop.floor.X + 2, stop.floor.Y + 6, stop.floor.Z - 22) == Ores.byName[stop.ore].material)
	end
end
mapCopy:Destroy()
print("PASS harbor paths, 360 rock rim rays, lit service pads, bridge crossing and edit-face removal")
local terrainCells = workspace.Terrain:CountCells()
world:generate()
local bricks = world.grid.folder:GetChildren()
assert(#bricks > 0 and #bricks < 3500, "Starting brick count: " .. #bricks)
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
head.Name, head.Anchored, head.Position, head.Parent = "Head", true, world.origin + Vector3.new(0, 6, -8), rig
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
local first, mask = Mining.selection(world, rig, anchor, normal, 1, 1, 36)
assert(#first == 1 and first[1] == anchor and mask == 1)
local full, fullMask = Mining.selection(world, rig, anchor, normal, 4, 6, 36)
assert(#full == 4 and fullMask == 15, "2x2 at the starter face")
local limited, limitedMask = Mining.selection(world, rig, anchor, normal, 4, 6, 2)
assert(#limited == 2 and limitedMask ~= fullMask)
local one, oneMask = Mining.selection(world, rig, anchor, normal, 4, 6, 36, 2)
assert(#one == 1 and oneMask == 2 and one[1] ~= anchor)
local sideLoot = world:excavate(one)
assert(next(sideLoot) and not next(world:excavate(one)))
local stale, staleMask = Mining.selection(world, rig, anchor, normal, 4, 6, 36, limitedMask)
assert(staleMask == 1 and #stale == 1, "Stale preview must not substitute other blocks")
local loot = world:excavate(stale)
assert(loot.Coal == 1 and world:oreAt(anchor) == nil)
local deeper = workspace:Raycast(head.Position, (anchor + normal * 2 - head.Position).Unit * 45)
assert(deeper and deeper.Instance.Parent == world.grid.folder and deeper.Position.Z < face.Position.Z - 3)
assert(world:oreAt(anchor - normal * Config.Cell) ~= nil, "One hit takes just the highlighted layer")
human.Health = 0
assert(not Mining.target(world, rig, anchor, normal))
rig:Destroy()
print("PASS part raycasts, power and pack limits, 2x2 faces, exact masks and shared depletion")

local stats = require(Shared.Upgrades).items.Radius.values
for _, n in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
	for _, count in stats do
		local center = world.origin + Vector3.new(2, -82, -98)
		local offsets, bits = Pattern.select(world.origin, center, n, count, 6, 7200, nil, function()
			return Ores.byName.Stone
		end)
		assert(#offsets == count and bits == 2 ^ count - 1 and offsets[1] == center)
		local unique = {}
		for _, pos in offsets do
			assert((pos - center):Dot(n) == 0 and not unique[pos])
			unique[pos] = true
		end
		local permitted, permMask, locked = Pattern.select(world.origin, center, n, count, 1, 7200, nil, function()
			return Ores.byName.Diamond
		end)
		assert(#permitted == 0 and permMask == 0 and locked == Ores.byName.Diamond)
	end
end
-- Exercise the largest pattern on successive, exposed floors across chunk boundaries.
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
	local batch = Pattern.select(world.origin, c, Vector3.yAxis, 25, 6, 7200, nil, function(pos)
		if Pattern.visiblePart(eye, pos, Vector3.yAxis, params) then
			return world:oreAt(pos)
		end
		return nil
	end)
	assert(#batch == 25, "Expected contiguous 5x5 floor at step " .. i .. ", got " .. #batch)
	local yield = world:excavate(batch)
	local amount = 0
	for _, n in yield do
		amount += n
	end
	assert(amount == 25)
	local elapsed = (os.clock() - t) * 1000
	worst, total = math.max(worst, elapsed), total + elapsed
end
print(string.format("PASS 20 successive 5x5 cuts; mean %.2f ms, max %.2f ms", total / 20, worst))
print("QUARRY_TESTS_PASSED")
