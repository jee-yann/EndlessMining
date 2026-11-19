local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Blocks = require(script.Parent.MineBlocks)
local Geology = require(script.Parent.Geology)
local World = {}
World.__index = World
local terrain = workspace.Terrain
local cell = Config.Cell
local chunk = Config.Chunk * cell

local function emptyRegion(bottom, top, surface)
	local overlap = OverlapParams.new()
	overlap.MaxParts = 1
	if surface then
		overlap.FilterDescendantsInstances = { surface }
	end
	if #workspace:GetPartBoundsInBox(CFrame.new((bottom + top) / 2), top - bottom, overlap) > 0 then
		return false
	end
	for y = bottom.Y, top.Y - 1, chunk do
		local region =
			Region3.new(Vector3.new(bottom.X, y, bottom.Z), Vector3.new(top.X, math.min(y + chunk, top.Y), top.Z))
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
		if
			emptyRegion(origin + Config.Min, origin + Config.Max, surface)
			and emptyRegion(origin + Config.SurfaceMin, origin + Config.SurfaceMax, surface)
		then
			return setmetatable({
				origin = origin,
				seed = seed,
				ready = false,
				grid = Blocks.new(origin, surface or workspace),
			}, World)
		end
		origin += Vector3.new(512, 0, 0)
	end
	error("Endless Mining needs an empty mine site. Move CitrineCove to an unused area.")
end

function World:generate()
	local geology = Geology.new(self.seed)
	local grid, size = self.grid, Blocks.size
	for z = 0, size.Z - 1 do
		local pz = Config.Min.Z + (z + 0.5) * cell
		for y = 0, size.Y - 1 do
			local py = Config.Min.Y + (y + 0.5) * cell
			local start = Blocks.index(0, y, z)
			for x = 0, size.X - 1 do
				local mat = geology:sample(Config.Min.X + (x + 0.5) * cell, py, pz)
				buffer.writeu8(grid.cells, start + x, Blocks.codes[mat])
			end
		end
		if z % Config.Chunk == Config.Chunk - 1 then
			task.wait()
		end
	end
	for z = 0, math.ceil(size.Z / Config.Chunk) - 1 do
		for y = 0, math.ceil(size.Y / Config.Chunk) - 1 do
			for x = 0, math.ceil(size.X / Config.Chunk) - 1 do
				grid:rebuild(x, y, z)
			end
		end
		task.wait()
	end
	self.ready = true
end

function World:oreAt(point)
	local p = ((point - self.grid.corner) / cell):Floor()
	local kind = Blocks.kinds[buffer.readu8(self.grid.cells, Blocks.index(p.X, p.Y, p.Z))]
	return if kind then kind.ore else nil
end

-- The server has checked the selected faces together in this same, non-yielding pulse.
function World:excavate(selected)
	local loot, lower, upper = {}, Blocks.size, Vector3.zero
	for _, point in selected do
		local p = ((point - self.grid.corner) / cell):Floor()
		local i = Blocks.index(p.X, p.Y, p.Z)
		local kind = Blocks.kinds[buffer.readu8(self.grid.cells, i)]
		if kind then
			buffer.writeu8(self.grid.cells, i, 0)
			local name = kind.ore.name
			loot[name] = (loot[name] or 0) + 1
			lower, upper = lower:Min(p), upper:Max(p)
		end
	end
	if next(loot) then
		self.grid:refresh(lower, upper)
	end
	return loot
end
return World
