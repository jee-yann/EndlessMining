local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Locator = {}
Locator.__index = Locator

local ceiling = {}
for _, layer in Config.Layers do
	for name in layer.oreChances do
		ceiling[name] = ceiling[name] or -1 - math.max(Config.DirtLayers, layer.depthBlocks)
	end
end

-- Visit each cell of successively larger shells once, starting at a depth
-- that can contain this mineral. A search can resume on the next owner poll.
local function search(grid, ore, start, top)
	return coroutine.wrap(function()
		local checked = 0
		local function visit(x, y, z)
			local p = start + Vector3.new(x, y, z)
			if grid:oreAt(p) == ore then
				return p
			end
			checked += 1
			if checked == 256 then
				checked = 0
				coroutine.yield()
			end
			return nil
		end
		local radius = 0
		while true do
			for y = -radius, math.min(radius, top - start.Y) do
				for z = -radius, radius do
					local boundary = math.abs(y) == radius or math.abs(z) == radius
					local step = if boundary then 1 else 2 * radius
					for x = -radius, radius, step do
						local match = visit(x, y, z)
						if match then
							return match
						end
					end
				end
			end
			radius += 1
		end
	end)
end

function Locator.new()
	return setmetatable({ tracks = {}, cursor = 0 }, Locator)
end

function Locator:locate(grid, center, mask)
	local waiting, positions = {}, {}
	for _, ore in Ores.list do
		local name, top = ore.name, ceiling[ore.name]
		if not top or not bit32.btest(mask, ore.visionBit) then
			self.tracks[name] = nil
			continue
		end
		local start = Vector3.new(center.X, math.min(center.Y, top), center.Z)
		local track = self.tracks[name]
		if not track or (start - track.start).Magnitude > 64 or (track.cell and grid:oreAt(track.cell) ~= ore) then
			track = { start = start, nextBatch = search(grid, ore, start, top) }
			self.tracks[name] = track
		end
		if track.cell then
			positions[name] = grid:center(track.cell)
		else
			table.insert(waiting, name)
		end
	end
	-- Share at most 2,048 lookups per poll across every enabled ore.
	for _ = 1, 8 do
		if #waiting == 0 then
			break
		end
		self.cursor = self.cursor % #waiting + 1
		local name = waiting[self.cursor]
		local track = self.tracks[name]
		local cell = track.nextBatch()
		if cell then
			track.cell, track.nextBatch = cell, nil
			positions[name] = grid:center(cell)
			table.remove(waiting, self.cursor)
			self.cursor -= 1
		end
	end
	return positions
end
return Locator
