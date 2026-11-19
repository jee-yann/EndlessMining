local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Physics = game:GetService("PhysicsService")
local Geology = require(script.Parent.Geology)
local Blocks = {}
Blocks.__index = Blocks
local edge, cell = Config.Chunk, Config.Cell
-- Order matches Enum.NormalId so the client can paint only uncovered faces.
local directions = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.yAxis, -Vector3.zAxis }
local air = Enum.Material.Air
for _, name in { "MineRock", "MinerHead" } do
	if not Physics:IsCollisionGroupRegistered(name) then
		Physics:RegisterCollisionGroup(name)
	end
end
for _, group in Physics:GetRegisteredCollisionGroups() do
	Physics:CollisionGroupSetCollidable("MinerHead", group.name, group.name == "MineRock")
end
function Blocks.new(origin, parent)
	local folder = Instance.new("Folder")
	folder.Name = "MineBlocks"
	folder:AddTag(Config.MineBlockTag)
	folder.Parent = parent
	return setmetatable({ folder = folder, top = origin + Vector3.yAxis * Config.FloorY, chunks = {} }, Blocks)
end
function Blocks:reset(seed)
	self.folder:ClearAllChildren()
	self.chunks = {}
	self.geology = Geology.new(seed)
end
function Blocks:cellAt(point)
	return ((point - self.top) / cell):Floor()
end
function Blocks:center(p)
	return self.top + (p + Vector3.one * 0.5) * cell
end
-- Each chunk stores just explored air (false) and exposed solids (Parts).
-- Buried and distant cells cost no instances or per-cell storage.
function Blocks:slot(p, create)
	local key = (p / edge):Floor()
	local chunk = self.chunks[key]
	if not chunk and create then
		chunk = {}
		self.chunks[key] = chunk
	end
	local i = p - key * edge
	return chunk, 1 + i.X + edge * (i.Z + edge * i.Y)
end
function Blocks:oreAt(p)
	local chunk, index = self:slot(p, false)
	local value = chunk and chunk[index]
	if value == false or p.Y >= 0 then
		return nil
	end
	if value then
		return Ores.byName[value.Name]
	end
	return Ores.byMaterial[self.geology:material(p)]
end
local function brick(self, p, material)
	local ore = Ores.byMaterial[material]
	local part = Instance.new("Part")
	part.Name = if ore then ore.name else "Packed earth"
	local tint = if ore
		then (if ore.name == "Stone" then Config.layer((-p.Y - 0.5) * cell).color else ore.color)
		else Color3.fromRGB(111, 77, 59)
	local grain = (p.X * 7 + p.Y * 3 + p.Z * 11) % 5
	part.Color = tint:Lerp(if grain < 2 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1), math.abs(grain - 2) * 0.016)
	part.Material = if not ore
		then Enum.Material.SmoothPlastic
		elseif ore.hardness >= 5 then Enum.Material.Neon
		else Enum.Material.Plastic
	local face = if ore then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	part.TopSurface, part.BottomSurface, part.LeftSurface, part.RightSurface, part.FrontSurface, part.BackSurface =
		face, face, face, face, face, face
	part.Anchored, part.CanTouch, part.CastShadow = true, false, true
	part.CollisionGroup = "MineRock"
	part.Size, part.Position = Vector3.one * cell, self:center(p)
	if ore then
		part:SetAttribute("Hardness", Config.strength(Config.FloorY + (p.Y + 0.5) * cell))
	end
	return part
end
function Blocks:expose(p, face, open)
	if p.Y >= 0 then
		return
	end
	local chunk, i = self:slot(p, true)
	local part = chunk[i]
	if part == false then
		return
	end
	if not part then
		local material = self.geology:material(p)
		if material == air then
			chunk[i] = false
			table.insert(open, p)
			return
		end
		part = brick(self, p, material)
		chunk[i] = part
	end
	local mask = bit32.bor(part:GetAttribute("OpenFaces") or 0, bit32.lshift(1, face))
	part:SetAttribute("OpenFaces", mask)
	if not part.Parent then
		part.Parent = self.folder
	end
end
function Blocks:openNeighbours(open)
	local n = 1
	while n <= #open do
		local p = open[n]
		for j, delta in directions do
			self:expose(p + delta, (j + 2) % 6, open)
		end
		n += 1
	end
end
function Blocks:openHall()
	local open = {}
	for x = -Config.HallHalfWidth / cell, Config.HallHalfWidth / cell - 1 do
		for z = Config.HallBack / cell, Config.HallFront / cell - 1 do
			self:expose(Vector3.new(x, -1, z), Enum.NormalId.Top.Value, open)
		end
	end
end
function Blocks:take(p)
	local chunk, i = self:slot(p, false)
	local part = chunk and chunk[i]
	local ore = if part then Ores.byName[part.Name] else nil
	if not ore then
		return nil
	end
	chunk[i] = false
	part:Destroy()
	self:openNeighbours({ p })
	return ore
end
return Blocks
