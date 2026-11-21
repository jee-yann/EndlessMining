-- Run with Lune from the repository root. Sample the actual cliff footings so
-- that both the photographic set and the playable coast use the same shore.
local R, fs = require("@lune/roblox"), require("@lune/fs")
local V, CF, rgb, I, E = R.Vector3.new, R.CFrame, R.Color3.fromHex, R.Instance, R.Enum
local map = R.deserializeModel(fs.readFile("map/CitrineCove.rbxmx"))[1]
local shelf = I.new("Model")
shelf.Name = "TideCoast"
local function part(parent, class, name, size, cf, color, material)
	local p = I.new(class)
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = E.SurfaceType.Smooth, E.SurfaceType.Smooth
	p.CastShadow, p.Parent = false, parent
	return p
end
local gate = map["Sand path and bridge"]["Portal paving"]
local pivot = part(
	shelf,
	"Part",
	"Portal datum",
	V(0.05, 0.05, 0.05),
	CF.new(gate.CFrame.Position + V(0, gate.Size.Y / 2, 0)),
	rgb("FFFFFF"),
	E.Material.SmoothPlastic
)
pivot.Transparency, shelf.PrimaryPart = 1, pivot

local function face(parent, a, b, c, color)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	for i, p in { b, c } do
		local depth = math.abs((p - a):Dot(along))
		if depth > 0.035 then
			local sign = if i == 1 then 1 else -1
			part(
				parent,
				"WedgePart",
				"Wave-cut bedding",
				V(0.07, math.max(0.02, math.abs(ab:Dot(up))), depth),
				CF.fromMatrix((a + p) * 0.5, normal * sign, up, along * sign),
				color,
				E.Material.Slate
			)
		end
	end
end
local center, water = V(0, 0, 33), 20.4
local profile = {}
for _, p in map["Citrine Highlands"]["Rock rim"]:GetChildren() do
	if p.Name == "Coastal escarpment" then
		local at = V(p.CFrame.Position.X, 0, p.CFrame.Position.Z)
		local radial = (at - center).Unit
		table.insert(profile, { at = at, radial = radial, angle = math.atan2(radial.Z, radial.X) })
	end
end
table.sort(profile, function(a, b)
	return a.angle < b.angle
end)
-- The southwestern wave-cut platform and the eastern spit are longer and
-- lower than the narrow shingle beneath the head of the mine.
local function banks(p, i)
	local a = p.angle
	local swell = (1 + math.cos(3 * a - 0.86)) * 0.5
	local promontory = 6 + 15 * swell ^ 2 + 9 * ((1 + math.sin(5 * a - 0.63)) * 0.5) ^ 3
	local dip = 1.1 * math.sin(7 * a + 0.73)
	local function at(d, h)
		return p.at + p.radial * d + V(0, water + h, 0)
	end
	return {
		at(1.15, 4.0 + dip + 1.8 * swell),
		at(promontory * 0.53, 1.45 + dip * 0.54),
		at(promontory * 0.74, 1.13 + dip * 0.64),
		at(promontory, -0.87 + 0.61 * math.cos(i * 1.71)),
	}
end
local coast = I.new("Model")
coast.Name, coast.Parent = "Intertidal ledges", shelf
for i, p in profile do
	local j = i % #profile + 1
	local a, b = banks(p, i), banks(profile[j], j)
	for k, ink in { "817D86", "B29C80", "7C8688" } do
		local tint = rgb(ink):Lerp(rgb("78939A"), 0.12 + 0.075 * math.sin(i * 1.79))
		face(coast, a[k], b[k], a[k + 1], tint)
		face(coast, b[k], b[k + 1], a[k + 1], tint:Lerp(rgb("6F757B"), 0.09))
	end
end
-- Rock remnants sit on their own submerged plinths. Cliff, ledge and skerry
-- have a continuous foundation down through the waterline.
for i, p in profile do
	if i % 4 ~= 1 and i % 7 ~= 2 then
		continue
	end
	local foot = banks(p, i)[4] + p.radial * (1.6 + math.abs(math.sin(i)) * 4)
	local axis = CF.lookAt(V(foot.X, water, foot.Z), V(foot.X, water, foot.Z) + p.radial)
	local size = 3.2 + 2.9 * (1 + math.cos(i * 1.4)) / 2
	for j = 1, 3 do
		local width = size * (1.7 - j * 0.27)
		local height = size * (0.35 + 0.06 * math.sin(i + j))
		local at = axis
			* CF.new((j - 2) * size * 0.43, (j - 2) * 0.44, j * 0.43)
			* CF.Angles(-0.15, 0.38 * math.sin(i * 2.1 + j), 0.07)
		part(
			coast,
			"WedgePart",
			"Tilted rock bed",
			V(width, height, size * 1.48),
			at,
			rgb(if j == 2 then "92918C" else "747783"),
			E.Material.Slate
		)
		part(
			coast,
			"Part",
			"Wet plinth",
			V(width * 0.87, 2.15, size * 1.07),
			at * CF.new(0, -1.22, 0.5),
			rgb("60747B"),
			E.Material.Slate
		)
	end
end
fs.writeFile("map/TideCoast.rbxm", R.serializeModel({ shelf }))

-- Continue the four existing lagoon plates to the horizon. The center tile is
-- supplied by the original map and retains its opening beneath the mine.
local sea = I.new("Model")
sea.Name = "Offshore water"
sea.ModelStreamingMode = E.ModelStreamingMode.Persistent
local original = map["Island and lagoon"]:FindFirstChild("Lagoon")
for x = -4, 4 do
	for z = -4, 4 do
		if x ~= 0 or z ~= 0 then
			local tile = part(
				sea,
				"Part",
				"Open strait",
				V(1200, 1, 1200),
				CF.new(x * 1200, 19.88, -26 + z * 1200),
				original.Color,
				original.Material
			)
			tile.Reflectance, tile.Transparency = original.Reflectance, original.Transparency
		end
	end
end
fs.writeFile("map/OffshoreWater.rbxm", R.serializeModel({ sea }))
