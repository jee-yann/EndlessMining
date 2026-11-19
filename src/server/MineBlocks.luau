--!optimize 2
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)

local Blocks = {}
Blocks.__index = Blocks
local cell, edge = Config.Cell, Config.Chunk
local size = (Config.Max - Config.Min) / cell
-- One padding cell on every side makes all six neighbour reads valid at the border.
local row = size.X + 2
local plane = row * (size.Y + 2)
local function index(x, y, z)
	return 1 + x + (1 + y) * row + (1 + z) * plane
end
Blocks.size, Blocks.index = size, index

-- Geology material IDs describe ore distribution. Each physical brick is Plastic.
local codes, kinds = {}, {}
local function register(material, name, color, ore)
	local id = codes[material] or (#kinds + 1)
	codes[material] = id
	kinds[id] = {
		name = name,
		ore = ore,
		colors = {
			color,
			color:Lerp(Color3.fromRGB(255, 249, 226), 0.085),
			color:Lerp(Color3.fromRGB(49, 46, 69), 0.09),
		},
	}
end
for _, ore in Ores.list do
	register(ore.material, ore.name, ore.color, ore)
end
for _, layer in Config.Layers do
	register(layer.material, "Stone", layer.color, Ores.byName.Stone)
end
register(Enum.Material.Grass, "Turf", Color3.fromRGB(124, 204, 84), nil)
register(Enum.Material.Cobblestone, "Caprock", Color3.fromRGB(173, 151, 130), nil)
codes[Enum.Material.Air] = 0
Blocks.codes, Blocks.kinds = codes, kinds

function Blocks.new(origin, parent)
	local folder = Instance.new("Folder")
	folder.Name = "MineBlocks"
	folder:AddTag(Config.MineBlockTag)
	folder.Parent = parent
	local cells = buffer.create(plane * (size.Z + 2))
	-- The exterior below the island is unreachable. Treat that padding as solid so
	-- only the inward-facing bedrock uncovered by miners needs physical bricks.
	local buriedRows = math.floor((-32 - Config.Min.Y) / cell)
	for z = -1, size.Z do
		buffer.fill(cells, index(-1, -1, z), 1, row)
		if z == -1 or z == size.Z then
			buffer.fill(cells, index(-1, 0, z), 1, buriedRows * row)
		else
			for y = 0, buriedRows - 1 do
				buffer.writeu8(cells, index(-1, y, z), 1)
				buffer.writeu8(cells, index(size.X, y, z), 1)
			end
		end
	end
	return setmetatable({
		folder = folder,
		corner = origin + Config.Min,
		cells = cells,
		chunks = {},
	}, Blocks)
end

local function exposed(cells, i)
	return buffer.readu8(cells, i - 1) == 0
		or buffer.readu8(cells, i + 1) == 0
		or buffer.readu8(cells, i - row) == 0
		or buffer.readu8(cells, i + row) == 0
		or buffer.readu8(cells, i - plane) == 0
		or buffer.readu8(cells, i + plane) == 0
end

local function newBrick()
	local p = Instance.new("Part")
	p.Anchored, p.CanTouch = true, false
	p.Material = Enum.Material.Plastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
	p.FrontSurface, p.BackSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
	p.LeftSurface, p.RightSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
	return p
end

local function matches(mask, start, width, depth, style)
	for z = 0, depth - 1 do
		for x = 0, width - 1 do
			if buffer.readu8(mask, start + x + z * edge) ~= style then
				return false
			end
		end
	end
	return true
end

-- Rebuild just this chunk's visible skin. A brick may cover several matching
-- cells. Its bounds are exact, so raycasts and character collision use the same wall.
function Blocks:rebuild(cx, cy, cz)
	local x0, y0, z0 = cx * edge, cy * edge, cz * edge
	local nx, ny, nz = math.min(edge, size.X - x0), math.min(edge, size.Y - y0), math.min(edge, size.Z - z0)
	local mask = buffer.create(edge ^ 3)
	local count = 0
	local key = Vector3.new(cx, cy, cz)
	local parts = self.chunks[key]
	for y = 0, ny - 1 do
		for z = 0, nz - 1 do
			local gy, gz = y0 + y, z0 + z
			local first = index(x0, gy, gz)
			for x = 0, nx - 1 do
				local id = buffer.readu8(self.cells, first + x)
				if id ~= 0 and exposed(self.cells, first + x) then
					local gx = x0 + x
					local shade = 0
					-- Offset courses on cave faces. The outer bedrock can merge into large slabs.
					if gx > 0 and gx < size.X - 1 and gy > 0 and gz > 0 and gz < size.Z - 1 then
						if Config.Min.Y + gy * cell < -64 then
							-- Broad strata let long underground passage walls share a brick.
							shade = (cx + cz + math.floor(gy / 4)) % 3
						else
							local stagger = 2 * (gy % 2)
							shade = (math.floor((gx + stagger) / 4) + math.floor((gz + stagger) / 4) + gy) % 3
						end
					end
					buffer.writeu8(mask, x + z * edge + y * edge * edge, id * 3 + shade)
					count += 1
				end
			end
		end
	end
	if count == 0 and not parts then
		return
	end
	parts = parts or {}
	local used = 0
	for y = 0, ny - 1 do
		for z = 0, nz - 1 do
			local x = 0
			while x < nx do
				local i = x + z * edge + y * edge * edge
				local style = buffer.readu8(mask, i)
				if style == 0 then
					x += 1
					continue
				end
				local w, d, h = 1, 1, 1
				while x + w < nx and buffer.readu8(mask, i + w) == style do
					w += 1
				end
				while z + d < nz and matches(mask, i + d * edge, w, 1, style) do
					d += 1
				end
				while y + h < ny and matches(mask, i + h * edge * edge, w, d, style) do
					h += 1
				end
				for dy = 0, h - 1 do
					for dz = 0, d - 1 do
						buffer.fill(mask, i + dy * edge * edge + dz * edge, 0, w)
					end
				end
				used += 1
				local p = parts[used] or newBrick()
				local kind = kinds[math.floor(style / 3)]
				p.Name, p.Color = kind.name, kind.colors[style % 3 + 1]
				p.Size = Vector3.new(w, h, d) * cell
				p.Position = self.corner + Vector3.new(x0 + x + w / 2, y0 + y + h / 2, z0 + z + d / 2) * cell
				if not parts[used] then
					p.Parent, parts[used] = self.folder, p
				end
				x += w
			end
		end
	end
	for i = #parts, used + 1, -1 do
		parts[i]:Destroy()
		parts[i] = nil
	end
	self.chunks[key] = if used > 0 then parts else nil
end

-- Edits can expose a neighbour in an adjoining chunk.
function Blocks:refresh(lower, upper)
	local first = ((lower - Vector3.one):Max(Vector3.zero) / edge):Floor()
	local last = ((upper + Vector3.one):Min(size - Vector3.one) / edge):Floor()
	for z = first.Z, last.Z do
		for y = first.Y, last.Y do
			for x = first.X, last.X do
				self:rebuild(x, y, z)
			end
		end
	end
end
return Blocks
