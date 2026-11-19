local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Ores = require(Shared.Ores)
local Geology = require(script.Parent.Geology)
local World = {}
World.__index = World
local terrain = workspace.Terrain
local cell = Config.Cell
local chunk = Config.Chunk * cell
local brush = {}

local function emptySite(origin, surface)
	local bottom = origin + Config.Min
	local top = origin + Vector3.new(96, 72, 100)
	local overlap = OverlapParams.new()
	overlap.MaxParts = 1
	if surface then
		overlap.FilterDescendantsInstances = { surface }
	end
	if #workspace:GetPartBoundsInBox(CFrame.new((bottom + top) / 2), top - bottom, overlap) > 0 then
		return false
	end
	for y = bottom.Y, top.Y - 1, chunk do
		local region = Region3.new(
			Vector3.new(bottom.X, y, bottom.Z),
			Vector3.new(top.X, math.min(y + chunk, top.Y), top.Z)
		)
		local _, occupancy = terrain:ReadVoxels(region, cell)
		-- ReadVoxels includes a named Size field alongside its indexed X planes.
		for _, plane in ipairs(occupancy) do
			for _, row in plane do
				for _, v in row do
					if v > 0 then
						return false
					end
				end
			end
		end
	end
	return true
end

function World.new(seed, surface)
	local origin = if surface
		then (surface:GetPivot().Position / cell + Vector3.one * 0.5):Floor() * cell
		else Config.Origin
	for _ = 1, 32 do
		if emptySite(origin, surface) then
			return setmetatable({ origin = origin, seed = seed, ready = false }, World)
		end
		origin += Vector3.new(512, 0, 0)
	end
	error("Endless Mining needs an empty mine site. Move CitrineCove to an unused area.")
end

function World:generate()
	local geology = Geology.new(self.seed)
	for x = Config.Min.X, Config.Max.X - 1, chunk do
		for z = Config.Min.Z, Config.Max.Z - 1, chunk do
			for y = Config.Min.Y, Config.Max.Y - 1, chunk do
				local lower = Vector3.new(x, y, z)
				local upper = (lower + Vector3.one * chunk):Min(Config.Max)
				local size = (upper - lower) / cell
				local mats, fill = table.create(size.X), table.create(size.X)
				for i = 1, size.X do
					mats[i], fill[i] = table.create(size.Y), table.create(size.Y)
					for j = 1, size.Y do
						local row, density = table.create(size.Z), table.create(size.Z)
						mats[i][j], fill[i][j] = row, density
						for k = 1, size.Z do
							row[k], density[k] = geology:sample(
								x + (i - 0.5) * cell,
								y + (j - 0.5) * cell,
								z + (k - 0.5) * cell
							)
						end
					end
				end
				terrain:WriteVoxels(Region3.new(self.origin + lower, self.origin + upper), cell, mats, fill)
				task.wait()
			end
		end
	end
	self.ready = true
end

local function stencil(radius)
	if brush[radius] then
		return brush[radius]
	end
	local extent = math.floor(radius / cell)
	local offsets = {}
	for x = -extent, extent do
		for y = -extent, extent do
			for z = -extent, extent do
				local d = x * x + y * y + z * z
				if d * cell * cell <= radius * radius then
					table.insert(offsets, { x = x, y = y, z = z, d = d })
				end
			end
		end
	end
	table.sort(offsets, function(a, b)
		return a.d < b.d
	end)
	brush[radius] = offsets
	return offsets
end

-- A single non-yielding read/modify/write transaction. The native material
-- grid doubles as the resource cache and the record of what's already gone.
function World:excavate(point, radius, power, space)
	local p = point - self.origin
	local loot, locked = {}, nil
	if space <= 0 or not Config.inside(p) then
		return loot, locked
	end
	local center = (p / cell):Floor() * cell
	local extent = math.floor(radius / cell) * cell
	local lower = (center - Vector3.one * extent):Max(Config.Min)
	local upper = (center + Vector3.one * (extent + cell)):Min(Config.Max)
	local region = Region3.new(self.origin + lower, self.origin + upper)
	local mats, fill = terrain:ReadVoxels(region, cell)
	local index = (center - lower) / cell + Vector3.one
	local taken = 0
	for _, o in stencil(radius) do
		local i, j, k = index.X + o.x, index.Y + o.y, index.Z + o.z
		local x, y, z = center.X + o.x * cell, center.Y + o.y * cell, center.Z + o.z * cell
		-- Leave one cell of bedrock around the sides, back, bottom and buried front.
		if
			x > Config.Min.X
			and x < Config.Max.X - cell
			and y > Config.Min.Y
			and y < upper.Y
			and z > Config.Min.Z
			and z < upper.Z
			and (z < -cell or y >= -cell)
		then
			local row = mats[i] and mats[i][j]
			local ore = row and Ores.byMaterial[row[k]]
			if ore and fill[i][j][k] > 0 then
				if ore.hardness <= power then
					loot[ore.name] = (loot[ore.name] or 0) + 1
					row[k], fill[i][j][k] = Enum.Material.Air, 0
					taken += 1
					if taken >= space then
						break
					end
				elseif not locked or ore.hardness < locked.hardness then
					locked = ore
				end
			end
		end
	end
	if taken > 0 then
		terrain:WriteVoxels(region, cell, mats, fill)
	end
	return loot, locked
end
return World
