-- The same ramp endpoints drive the permanent floor, the tunnel excavation and its signs.
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Stops = require(Shared.Expeditions).stops
local Descent = { runs = {}, turns = {} }
local corners = { Vector3.new(12, 0, -36), Vector3.new(12, 0, -88), Vector3.new(68, 0, -88), Vector3.new(68, 0, -36) }
local lastDepth = -Stops[#Stops].floor.Y
local function run(a, b, width)
	table.insert(Descent.runs, { a = a, b = b, width = width })
end
local function turn(point)
	table.insert(Descent.turns, point)
end
-- The right-hand passage leaves the starter coal face open.
run(Vector3.new(7, 0, -20), Vector3.new(12, 0, -20), 9)
run(Vector3.new(12, 0, -16), corners[1], 10)
for step = 0, lastDepth / 16 - 1 do
	local a = corners[step % 4 + 1] - Vector3.yAxis * (16 * step)
	local b = corners[(step + 1) % 4 + 1] - Vector3.yAxis * (16 * (step + 1))
	local dir = ((b - a) * Vector3.new(1, 0, 1)).Unit
	turn(a)
	run(a + dir * 6, b - dir * 6, 12)
end
turn(corners[1] - Vector3.yAxis * lastDepth)
for _, stop in Stops do
	if stop.floor then
		run(stop.floor + Vector3.new(2, 0, 0), corners[1] + Vector3.yAxis * stop.floor.Y, 10)
	end
end

local function carveRun(grid, a, b, width)
	local dx, dz = b.X - a.X, b.Z - a.Z
	local length = math.sqrt(dx * dx + dz * dz)
	local ux, uz = dx / length, dz / length
	local cell = Config.Cell
	local half = width / 2 + cell / 2
	local function snap(n)
		return (math.floor(n / cell) + 0.5) * cell
	end
	for x = snap(math.min(a.X, b.X) - half), math.max(a.X, b.X) + half, cell do
		for z = snap(math.min(a.Z, b.Z) - half), math.max(a.Z, b.Z) + half, cell do
			local along = (x - a.X) * ux + (z - a.Z) * uz
			if along < -2 or along > length + 2 or math.abs((x - a.X) * uz - (z - a.Z) * ux) > half then
				continue
			end
			local floor = a.Y + (b.Y - a.Y) * math.clamp(along / length, 0, 1)
			for y = snap(floor - 3.5), floor + 13, cell do
				local p = ((Vector3.new(x, y, z) - Config.Min) / cell):Floor()
				buffer.writeu8(grid.cells, grid.index(p.X, p.Y, p.Z), 0)
			end
		end
	end
end
function Descent.carve(grid)
	for _, segment in Descent.runs do
		carveRun(grid, segment.a, segment.b, segment.width)
	end
	for _, point in Descent.turns do
		carveRun(grid, point - Vector3.xAxis * 6, point + Vector3.xAxis * 6, 12)
	end
end

local slate, brass = Color3.fromRGB(57, 71, 91), Color3.fromRGB(255, 193, 91)
local function part(parent, name, size, cf, color, solid, glow)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.Size, p.CFrame = name, true, size, cf
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = solid, solid, false, solid
	p.Color, p.Material = color, if glow then Enum.Material.Neon else Enum.Material.Plastic
	p.Parent = parent
	return p
end
local function sign(p, title, tint)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size, gui.MaxDistance, gui.LightInfluence = "Wayfinding", UDim2.fromScale(12, 2), 38, 0
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency, text.TextScaled = UDim2.fromScale(1, 1), 1, true
	text.Text, text.Font, text.TextColor3 = title, Enum.Font.FredokaOne, tint
	text.TextStrokeTransparency, text.TextStrokeColor3 = 0.12, slate
	text.Parent, gui.Parent = gui, p
end
local function tintAt(depth)
	for i = #Stops, 2, -1 do
		if depth >= -Stops[i].floor.Y then
			return Stops[i].color
		end
	end
	return brass
end
function Descent.build(map, origin)
	local group = Instance.new("Model")
	group.Name = "Deep mine trail"
	local fork = part(
		group,
		"Trail entrance",
		Vector3.new(0.36, 0.12, 2.4),
		CFrame.new(origin + Vector3.new(7.3, 0.17, -17)),
		brass,
		false,
		true
	)
	sign(fork, "Deep trail  →", brass)
	for _, s in Descent.runs do
		local a, b = origin + s.a, origin + s.b
		local cf = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude
		local floor = part(
			group,
			"Haul road",
			Vector3.new(s.width + 4, 1.1, length + 0.12),
			cf * CFrame.new(0, -0.47, 0),
			slate,
			true,
			false
		)
		floor.TopSurface = Enum.SurfaceType.Studs
		local color = tintAt(-s.b.Y)
		for _, side in { -1, 1 } do
			part(
				group,
				"Inlaid guide",
				Vector3.new(0.22, 0.06, length),
				cf * CFrame.new(side * (s.width / 2 - 0.52), 0.12, 0),
				color,
				false,
				true
			)
		end
	end
	for i, point in Descent.turns do
		local cf = CFrame.new(origin + point)
		local tint = tintAt(-point.Y)
		local landing =
			part(group, "Switchback", Vector3.new(16, 0.68, 16), cf * CFrame.new(0, -0.22, 0), slate, true, false)
		landing.TopSurface = Enum.SurfaceType.Studs
		local plate = part(
			group,
			"Depth marker",
			Vector3.new(1.3, 0.2, 1.3),
			cf * CFrame.new(-4.65, 0.25, 4.65),
			tint,
			false,
			true
		)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Parent = tint, 22, 0.75, plate
		if i > 1 and (i - 1) % 4 == 0 then
			local title = tostring(-point.Y) .. " studs  ↓"
			for _, stop in Stops do
				if stop.floor and stop.floor.Y == point.Y then
					title = "←  " .. stop.name
					break
				end
			end
			sign(plate, title, tint)
		end
	end
	group.Parent = map
end
return Descent
