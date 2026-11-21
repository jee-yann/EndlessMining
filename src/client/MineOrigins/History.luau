-- Staged exposures for the private island, measured at eight photographs per second.
local P, Atlas = require(script.Parent.Props), require(script.Parent.HistoryAtlas)
local Island, Worksite = require(script.Parent.HistoryIsland), require(script.Parent.HistoryWorksite)
local V, CF = Vector3.new, CFrame.new
local History = {}
History.__index = History
History.rate, History.duration = 8, 17

local materials, surfaces, finishes, rotations = {}, {}, {}, {}
for _, v in Enum.Material:GetEnumItems() do
	materials[v.Value] = v
end
for _, v in Enum.SurfaceType:GetEnumItems() do
	surfaces[v.Value] = v
end
for i, style in Atlas.finishes do
	finishes[i] = {
		shape = style[1],
		tint = Color3.fromHex(style[2]),
		material = materials[style[3]],
		top = surfaces[style[4]],
		bottom = surfaces[style[5]],
		transparency = style[6],
	}
end
for i, angles in Atlas.orientations do
	rotations[i] = CF(0, 0, 0, table.unpack(angles))
end

local function lettering(part)
	local face = Instance.new("SurfaceGui")
	face.Name, face.Face, face.CanvasSize, face.LightInfluence =
		"Lettering", Enum.NormalId.Back, Vector2.new(256, 70), 0
	face.Parent = part
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextScaled, label.Font = "MINE", true, Enum.Font.FredokaOne
	label.TextColor3, label.Parent = Color3.fromHex("FFF9DB"), face
end

local function piece(model, row, base)
	local style = finishes[row[1]]
	local p = Instance.new(if style.shape == 3 then "WedgePart" else "Part")
	if style.shape == 0 then
		p.Shape = Enum.PartType.Ball
	elseif style.shape == 2 then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Color, p.Material, p.Transparency = style.tint, style.material, style.transparency
	p.TopSurface, p.BottomSurface = style.top, style.bottom
	p.Size = V(row[5], row[6], row[7])
	p.CFrame = base * CF(row[2], row[3], row[4]) * (rotations[row[8]] or CFrame.identity)
	if row[9] then
		lettering(p)
	end
	p.Parent = model
	return p
end

function History.new(stage, base)
	local parked = Instance.new("Folder")
	local self = setmetatable({
		base = base,
		stage = stage,
		shelf = parked,
		root = P.model(parked, "Citrine through time"),
		starts = {},
		containers = {},
		ends = {},
		scene = {},
		frame = -1,
		surfaceCursor = 1,
		readyThrough = -1,
		skyline = {},
		reclaimed = {},
		weathering = 0,
	}, History)
	self.loader = coroutine.create(function()
		local function spent(n)
			self.budget -= n
			if self.budget <= 0 then
				coroutine.yield()
			end
		end
		local function register(model, first, last, authoredLocal, container)
			if authoredLocal then
				model:PivotTo(base)
			end
			local a = math.max(0, math.floor(first * History.rate + 0.5))
			local b = if last then math.floor(last * History.rate + 0.5) else 10000
			table.insert(self.scene, { model, a, b })
			self.starts[a] = self.starts[a] or {}
			table.insert(self.starts[a], model)
			if last then
				self.ends[b] = self.ends[b] or {}
				table.insert(self.ends[b], model)
			end
			self.containers[model] = container
			if self.frame >= a and self.frame < b then
				model.Parent = container or self.root
			end
		end
		local function buildShot(shot)
			local group = P.model(parked, shot[2])
			for _, shape in shot[3] do
				local p = piece(group, shape, base)
				if shot[1] == 0 then
					local key = shape[1]
					local pigment = self.skyline[key]
					if not pigment then
						local color = p.Color
						local old = if color.G > color.R then Color3.fromHex("867C76") else Color3.fromHex("726875")
						pigment = { old = old, new = color, parts = {} }
						self.skyline[key] = pigment
					end
					p.Color = pigment.old
					table.insert(pigment.parts, p)
				elseif shot[2] == "Terraced shore fill" and p.Color.G > p.Color.R and p.Color.G > p.Color.B then
					local key = shot[1] * 1000 + shape[1]
					local soil = self.reclaimed[key]
					if not soil then
						soil = {
							start = shot[1] / History.rate,
							old = Color3.fromHex("A28665"),
							new = p.Color,
							parts = {},
						}
						self.reclaimed[key] = soil
					end
					p.Color = soil.old
					table.insert(soil.parts, p)
				end
				spent(1)
			end
			register(group, shot[1] / History.rate, nil, false)
		end
		for _, shot in Atlas.exposures do
			if shot[1] == 0 then
				buildShot(shot)
			end
		end
		self.island = Island.build(parked, register, spent)
		self.readyThrough = 1.25
		coroutine.yield()
		local coast = game:GetService("ReplicatedStorage").Shared:FindFirstChild("TideCoast")
		if coast then
			local shelf = coast:Clone()
			shelf.Parent = parked
			shelf:PivotTo(base)
			local stretches = {}
			for _, p in shelf:GetDescendants() do
				if not p:IsA("BasePart") or p == shelf.PrimaryPart then
					continue
				end
				local at = base:PointToObjectSpace(p.Position)
				local front = math.clamp(0.44 + at.X / 318 - at.Z / 430, 0, 1)
				local age = if at.Z < -25 then 3.92 + front * 0.6 else 7.53 + front * 1.68
				local key = math.floor(age * History.rate + 0.5)
				local section = stretches[key]
				if not section then
					section = P.model(parked, "Tidal shore below the new bank")
					stretches[key] = section
				end
				p.Parent = section
				spent(1)
			end
			register(shelf, 3.75, nil, false)
			for exposure, section in stretches do
				register(section, exposure / History.rate, nil, false, shelf)
			end
		end
		for _, shot in Atlas.exposures do
			if shot[1] > 0 and shot[1] < 26 then
				self.readyThrough = (shot[1] - 1) / History.rate
				buildShot(shot)
			end
		end
		self.readyThrough = 3.14
		self.work = Worksite.build(parked, register, spent, self.island.dock)
		Island.plant(self.island, parked, register, spent)
		for _, shot in Atlas.exposures do
			if shot[1] >= 26 then
				self.readyThrough = (shot[1] - 1) / History.rate
				buildShot(shot)
			end
		end
		self.readyThrough = math.huge
	end)
	return self
end

function History:prepare(budget, underground)
	-- Once the deep bed fills the screen, the unseen surface can join the
	-- renderer a few parcels at a time. Submitting the whole island on the
	-- first aerial photograph adds a frame stall even if every part exists.
	if underground and self.frame < 0 then
		local queue = self.starts[0] or {}
		local allowance = 6 * budget
		self.root.Parent = self.stage
		while self.surfaceCursor <= #queue and allowance > 0 do
			local group = queue[self.surfaceCursor]
			allowance -= 1 + #group:GetDescendants()
			group.Parent = self.root
			self.surfaceCursor += 1
		end
	end
	if not self.loader then
		return
	end
	self.budget = budget
	local ok, err = coroutine.resume(self.loader)
	if not ok then
		error(err, 2)
	end
	if coroutine.status(self.loader) == "dead" then
		self.loader = nil
	end
end

function History:draw(t)
	t = math.clamp(t, 0, History.duration)
	if self.loader then
		local elapsed = math.clamp(t - (self.previousAge or t), 1 / 60, 0.13)
		self:prepare(math.ceil(620 * elapsed))
		while self.loader and self.readyThrough < t do
			self:prepare(64)
		end
		self.previousAge = t
	end
	if self.root.Parent ~= self.stage then
		self.root.Parent = self.stage
	end
	local frame = math.clamp(math.floor(t * History.rate + 0.00001), 0, History.duration * History.rate)
	if frame == self.frame then
		return
	end
	if frame < self.frame then
		for _, shot in self.scene do
			shot[1].Parent = if frame >= shot[2] and frame < shot[3]
				then self.containers[shot[1]] or self.root
				else self.shelf
		end
	else
		for i = self.frame + 1, frame do
			for _, m in self.ends[i] or {} do
				m.Parent = self.shelf
			end
			for _, m in self.starts[i] or {} do
				local destination = self.containers[m] or self.root
				if m.Parent ~= destination then
					m.Parent = destination
				end
			end
		end
	end
	self.frame = frame
	local age = frame / History.rate
	local weathering = math.clamp(math.floor((age - 1.75) * 2.5), 0, 8)
	if weathering ~= self.weathering then
		for _, band in self.skyline do
			local color = band.old:Lerp(band.new, weathering / 8)
			for _, p in band.parts do
				p.Color = color
			end
		end
		self.weathering = weathering
	end
	if age >= 6.8 and age <= 12 or self.soilAge == nil or self.soilAge <= 12 or age < self.soilAge then
		for _, bed in self.reclaimed do
			local step = math.clamp(math.floor((age - bed.start - 0.23) * 3), 0, 7)
			if bed.step ~= step then
				bed.step = step
				local tint = bed.old:Lerp(bed.new, step / 7)
				for _, p in bed.parts do
					p.Color = tint
				end
			end
		end
	end
	self.soilAge = age
	Island.expose(self.island, age)
	if self.work then
		Worksite.expose(self.work, age, self.base)
	end
end

function History:Destroy()
	if not self.shelf then
		return
	end
	if self.loader then
		coroutine.close(self.loader)
		self.loader = nil
	end
	self.root:Destroy()
	self.shelf:Destroy()
	self.shelf = nil
end

return History
