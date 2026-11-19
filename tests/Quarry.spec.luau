-- Studio CLI RunScript test. Run in the local build. All changes are in memory.
local Server = game:GetService("ServerScriptService").Server
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology, World = require(Server.Geology), require(Server.MineWorld)
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
assert(Profile.buy(p, "Radius") and p.gold == 11 and Profile.stat(p, "Radius") == 7)
p.gold = 1e7
for _, key in require(Shared.Upgrades).order do
	while Profile.buy(p, key) do
	end
	assert(p.levels[key] == #require(Shared.Upgrades).items[key].values)
end
assert(
	Profile.stat(p, "Speed") == 0.20
		and Profile.stat(p, "Power") == 6
		and Profile.stat(p, "Capacity") == 7200
)
p.bag.Stone = 7201
assert(not Profile.valid(p))
print("PASS sale, costs, level caps, upgrade effects, profile capacity validation")

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
	for z = 53, 0, -0.5 do
		local floor = floorAt(x, z)
		assert(floor and math.abs(floor.Position.Y - lastY) < 1, "Landing-to-mine path at " .. z)
		lastY = floor.Position.Y
	end
end
assert(not floorAt(10, 32), "The inlet should pass completely under the bridge")
assert(not floorAt(0, -10), "The gallery floor must be excavatable terrain")
assert(
	not workspace:Raycast(world.origin + Vector3.new(0, 6, -6), Vector3.new(0, 0, -42), onMap),
	"The starter seam must be clear of scenery"
)
for _, prompt in site.stations do
	local pad = prompt.Parent.Position - world.origin
	assert(floorAt(pad.X, pad.Z) and math.abs(pad.Z - 15) < prompt.MaxActivationDistance)
end
mapCopy:Destroy()
print("PASS authored surface, continuous bridge crossing, both service pads and edit-face removal")
world:generate()
local Mining = require(Server.MiningService)
local rig = Instance.new("Model")
local human = Instance.new("Humanoid")
human.Parent = rig
local head = Instance.new("Part")
head.Name, head.Anchored, head.Position, head.Parent =
	"Head", true, world.origin + Vector3.new(0, 6, -8), rig
rig.Parent = workspace
local face = workspace:Raycast(head.Position + Vector3.new(0, 0, -2), Vector3.new(0, 0, -32))
assert(face and face.Instance == workspace.Terrain and Mining.target(world, rig, face.Position))
assert(not Mining.target(world, rig, world.origin + Vector3.new(0, 0, -100)))
local post = Instance.new("Part")
post.Size, post.Position, post.Anchored, post.Parent =
	Vector3.new(5, 8, 2), head.Position + Vector3.new(0, 0, -5), true, workspace
assert(not Mining.target(world, rig, face.Position))
post:Destroy()
human.Health = 0
assert(not Mining.target(world, rig, face.Position))
rig:Destroy()
print("PASS server reach, solid obstructions and character state")
local function dig(localPoint, r, power, space)
	return world:excavate(world.origin + localPoint, r, power, space)
end
local center = Vector3.new(2, -82, -98)
local region =
	Region3.new(world.origin + center - Vector3.one * 34, world.origin + center + Vector3.one * 34)
workspace.Terrain:FillRegion(region, 4, Ores.byName.Diamond.material)
local closed, hard = dig(center, 28, 4, 7200)
assert(not next(closed) and hard.name == "Diamond")
local partial = dig(center, 28, 5, 7)
assert(partial.Diamond == 7)
local counted = 0
for x = -7, 7 do
	for y = -7, 7 do
		for z = -7, 7 do
			if x * x + y * y + z * z <= 49 then
				counted += 1
			end
		end
	end
end
local rest = dig(center, 28, 5, 7200)
assert(rest.Diamond == counted - 7)
assert(not next(dig(center, 28, 6, 7200)))
assert(not next(dig(center, 28, 6, 0)))
print("PASS shared depletion, hardness, remaining capacity and exact sphere", counted, "cells")
local worst, total = 0, 0
for _ = 1, 20 do
	workspace.Terrain:FillRegion(region, 4, Ores.byName.Diamond.material)
	local t = os.clock()
	assert(dig(center, 28, 6, 7200).Diamond == counted)
	local elapsed = (os.clock() - t) * 1000
	worst = math.max(worst, elapsed)
	total += elapsed
end
print(
	string.format(
		"PASS 20 maximum-radius operations; mean %.2f ms, max %.2f ms (local Studio)",
		total / 20,
		worst
	)
)
print("QUARRY_TESTS_PASSED")
