local Lighting = game:GetService("Lighting")
local P, Atlas, Worksite =
	require(script.Parent.Props), require(script.Parent.HistoryAtlas), require(script.Parent.HistoryWorksite)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local ease, rgb = P.ease, Color3.fromHex

local History = {}
History.__index = History

local materials, surfaces = {}, {}
for _, material in Enum.Material:GetEnumItems() do
	materials[material.Value] = material
end
for _, surface in Enum.SurfaceType:GetEnumItems() do
	surfaces[surface.Value] = surface
end
local finishes, orientations = {}, {}
for i, style in Atlas.finishes do
	finishes[i] = {
		shape = style[1],
		tint = rgb(style[2]),
		material = materials[style[3]],
		surface = surfaces[style[4]],
		bottom = surfaces[style[5]],
		transparency = style[6],
	}
end
for i, rot in Atlas.orientations do
	orientations[i] = CF(0, 0, 0, table.unpack(rot))
end

local rising = { Distant = 66, Highland = 74, Bluff = 47, Bedrock = 27, Gallery = 27 }
local trees = { Tree = true, Pioneer = true, BluffTree = true, MesaTree = true }
local natural = { Distant = true, Highland = true, Bluff = true, Bedrock = true, Soil = true }
local permanent =
	{ Water = true, Soil = true, Distant = true, Highland = true, Bluff = true, Bedrock = true, Gallery = true }
local ash = rgb("9A817B")
local ancientWater = { Lagoon = rgb("31586F"), ["Shallow water"] = rgb("527585"), ["Water glint"] = rgb("86A0A7") }

local function addWater(self, kind, part)
	local band = self.water[kind]
	if not band then
		band = { old = ancientWater[kind], new = part.Color, parts = {} }
		self.water[kind] = band
	end
	table.insert(band.parts, part)
end

local function inscription(part)
	local surface = Instance.new("SurfaceGui")
	surface.Name, surface.Face = "Lettering", Enum.NormalId.Back
	surface.SizingMode, surface.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(256, 70)
	surface.LightInfluence, surface.Parent = 0, part
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Text, text.TextScaled, text.Font = "MINE", true, Enum.Font.FredokaOne
	text.TextColor3, text.Parent = rgb("FFF9DB"), surface
end

local function makePiece(parent, home, row)
	local style = finishes[row[1]]
	local part = Instance.new(if style.shape == 3 then "WedgePart" else "Part")
	if style.shape == 0 then
		part.Shape = Enum.PartType.Ball
	elseif style.shape == 2 then
		part.Shape = Enum.PartType.Cylinder
	end
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Size, part.CFrame =
		V(row[5], row[6], row[7]), home * CF(row[2], row[3], row[4]) * (orientations[row[8]] or CFrame.identity)
	part.Material, part.TopSurface, part.BottomSurface = style.material, style.surface, style.bottom
	part.Color, part.Transparency, part.Parent = style.tint, style.transparency, parent
	return part, style
end

local function buildFormation(self, formation, spent)
	local m = P.model(self.shelf, formation.name)
	local mode = formation.motion
	local lower = V(math.huge, math.huge, math.huge)
	local upper = -lower
	local front, signFace
	for _, row in formation.pieces do
		local part, style = makePiece(m, self.base, row)
		local water = Atlas.water[row[1]]
		if mode == "Water" and water then
			addWater(self, water, part)
		end
		local at, half = V(row[2], row[3], row[4]), V(row[5], row[6], row[7]) * 0.5
		lower, upper = lower:Min(at - half), upper:Max(at + half)
		if mode == "Gallery" and formation.name == "Authored dig floor" then
			local depth = math.clamp((-at.Z - 9) / 46, 0, 1)
			part.Color = style.tint:Lerp(rgb("433C4B"), 0.25 + depth * 0.67)
		end
		if mode == "Sign" and (not front or row[4] > front) then
			signFace, front = part, row[4]
		end
		if natural[mode] then
			local band = math.clamp(math.floor((row[2] * 0.48 + row[4] * 0.24 + 35) / 23), 0, 4)
			local key = row[1] * 5 + band
			local ink = self.pigments[key]
			if not ink then
				local gray = 0.24 * style.tint.R + 0.62 * style.tint.G + 0.14 * style.tint.B
				local warm = ash:Lerp(Color3.new(gray, gray * 0.92, gray * 0.97), 0.46)
				ink = { old = warm, new = style.tint, band = band, parts = {} }
				self.pigments[key] = ink
			end
			part.Color = ink.old
			table.insert(ink.parts, part)
		end
		spent(1)
	end
	if signFace then
		inscription(signFace)
	end
	local pivot = (lower + upper) * 0.5
	if trees[mode] then
		local trunk = formation.pieces[1]
		pivot = V(trunk[2], trunk[3] - trunk[6] * 0.5, trunk[4])
	elseif mode == "Raise" or mode == "Tram" then
		pivot = V(pivot.X, lower.Y, pivot.Z)
	end
	m.WorldPivot = self.base * CF(pivot)
	table.insert(self.tracks, {
		model = m,
		home = m.WorldPivot,
		pos = pivot,
		kind = mode,
		start = formation.start,
		duration = formation.duration,
	})
end

-- Cut faces protecting the gallery before the excavation. They meet on the
-- same fracture vertices, then break out toward the staging track one by one.
local function makeFace(shelf)
	local chunks = {}
	local seams = { -12.6, -7.1, -2.7, 1.2, 6.3, 12.6 }
	for i = 1, #seams - 1 do
		local m = P.model(shelf, "Uncut basalt")
		local x, x2 = seams[i], seams[i + 1]
		local function edge(k, side)
			local shift = if k == 1 or k == #seams then 0 else 0.69 * math.sin(k * 2.8)
			return {
				V(side, -0.48, 4.00),
				V(side + shift, 6.45, 4.32 + math.cos(k) * 0.48),
				V(side - shift * 0.6, 15.48 + 0.62 * math.cos(k), 3.23 + 0.37 * math.sin(k)),
				V(side - 0.18, 14.60, -3.42),
			}
		end
		local a, b = edge(i, x), edge(i + 1, x2)
		for k, tone in { "896E66", "A58270", "997E6D" } do
			P.face(m, a[k], b[k], a[k + 1], rgb(tone))
			P.face(m, b[k], b[k + 1], a[k + 1], rgb(tone))
		end
		P.face(m, a[1], a[2], a[4], rgb("695B60"))
		P.face(m, a[2], a[3], a[4], rgb("796467"))
		P.face(m, b[1], b[2], b[4], rgb("695B60"))
		P.face(m, b[2], b[3], b[4], rgb("796467"))
		local hinge = V((x + x2) * 0.5, -0.36, 2.15)
		m.WorldPivot = CF(hinge)
		table.insert(chunks, { model = m, hinge = hinge })
	end
	return chunks
end

function History.new(stage, gateBase)
	local shelf = Instance.new("Folder")
	shelf.Name = "History scenery offstage"
	local self = setmetatable({
		stage = stage,
		base = gateBase,
		shelf = shelf,
		root = P.model(shelf, "Citrine through time"),
		tracks = {},
		pigments = {},
		water = {},
	}, History)
	self.loader = coroutine.create(function()
		local function spent(amount)
			self.budget -= amount
			if self.budget <= 0 then
				coroutine.yield()
			end
		end
		for _, formation in Atlas.formations do
			buildFormation(self, formation, spent)
		end
		self.crater = Worksite.crater(shelf, spent)
		self.clouds = Worksite.weather(shelf, spent)
		self.face = makeFace(shelf)
		-- The playable lagoon leaves a rectangular opening under the mine for
		-- its dig volume. The sea crosses this area before the island rises.
		local strait =
			P.box(self.root, "Water beneath the rising headland", V(0, -4.37, -113.25), V(192.2, 1, 224.4), "39C5DD")
		strait.CFrame = self.base * strait.CFrame
		strait.CastShadow = false
		addWater(self, "Lagoon", strait)
		self.throat = P.model(shelf, "Shadow inside the working gallery")
		P.box(self.throat, "Portal footwall", V(0, -0.52, -4.2), V(60, 0.60, 7.8), "92765F", nil, Enum.Material.Slate)
		P.box(
			self.throat,
			"Rear wall in shadow",
			V(0, 5.46, -66.6),
			V(61, 11.36, 0.23),
			"433D4B",
			nil,
			Enum.Material.Slate
		)
		-- Sloping rock behind the piers closes the short gap between their faces
		-- and the broader authored gallery, including rays from high on the bridge.
		for _, side in { -1, 1 } do
			P.box(
				self.throat,
				"Inner jamb",
				V(side * 10.36, 5.55, -0.38),
				V(2.34, 11.65, 7.6),
				"675C58",
				nil,
				Enum.Material.Slate
			)
		end
		self.builders = Worksite.builders(shelf)
	end)
	return self
end

function History:prepare(pieceBudget)
	if not self.loader then
		return
	end
	self.budget = pieceBudget
	local ok, problem = coroutine.resume(self.loader)
	if not ok then
		error(problem, 2)
	end
	if coroutine.status(self.loader) == "dead" then
		self.loader = nil
	end
end

local function poseTrack(v, t, root, shelf)
	local kind, model = v.kind, v.model
	local u = if v.duration > 0 then ease(t, v.start, v.start + v.duration) else 1
	if kind == "Pioneer" then
		u *= 1 - ease(t, 9.7 + math.abs(v.pos.X) * 0.035, 11.2 + math.abs(v.pos.X) * 0.035)
	end
	local visible = permanent[kind] or (t >= v.start and u > 0.0001)
	if kind == "Wagon" then
		visible = t >= v.start and t < 18.50
	end
	if kind == "Sign" then
		visible = t >= v.start
	end
	local container = if visible then root else shelf
	if model.Parent ~= container then
		model.Parent = container
	end
	if not visible then
		return
	end
	local ground = 0
	if kind == "MesaTree" then
		ground = -rising.Highland * (1 - ease(t, 1.5, 6.5))
	elseif kind == "BluffTree" then
		local start = if v.pos.X < 0 then 2.9 else 2.3
		ground = -rising.Bluff * (1 - ease(t, start, start + 3.5))
	end
	if v.last == u and v.ground == ground and kind ~= "Wagon" and kind ~= "Cabins" then
		return
	end
	v.last, v.ground = u, ground
	local home = v.home
	local rem = 1 - u
	if rising[kind] then
		model:PivotTo(home - home.UpVector * rising[kind] * rem)
	elseif trees[kind] then
		model:ScaleTo(math.max(0.018, u * (1 + 0.16 * math.sin(u * math.pi))))
		model:PivotTo(home * CF(0, ground, 0) * A(0, 0, math.sin(u * math.pi) * 0.10))
	elseif kind == "Board" then
		model:PivotTo(home * CF(-0.38 * rem, 2.85 * rem, 1.15 * rem) * A(-0.93 * rem, 0.19 * rem, 0.085 * rem))
	elseif kind == "Raise" or kind == "Tram" then
		model:ScaleTo(math.max(0.018, u))
		model:PivotTo(home * A(rem * 0.18, 0, 0))
	elseif kind == "Pave" then
		model:ScaleTo(math.max(0.018, u))
	elseif kind == "Mason" then
		model:PivotTo(home * CF(2.3 * rem, 4.1 * rem, -1.1 * rem) * A(0, rem * 0.29, rem * 0.11))
	elseif kind == "Awning" then
		model:PivotTo(home * CF(0, 1.1 * rem, -1.03 * rem) * A(-1.14 * rem, 0, 0))
		model:ScaleTo(math.max(0.06, u))
	elseif kind == "Furniture" or kind == "Lights" then
		model:ScaleTo(math.max(0.018, u))
		model:PivotTo(home * CF(0, -1.32 * rem, 0))
	elseif kind == "Sign" then
		model:PivotTo(home * CF(Worksite.signOffset(t)) * A(0, 0.10 * rem, 0.045 * math.sin(u * math.pi)))
	elseif kind == "Wagon" then
		local trip = ease(t, 12.55, 15.30)
		local homeward = ease(t, 16.55, 18.50)
		model:PivotTo(home * CF(0, 0.10 + 0.14 * math.sin(trip * math.pi), 32 * (1 - trip) - 35 * homeward))
	elseif kind == "Cabins" then
		model:PivotTo(home * CF(4.6 * (1 - ease(t, 16.1, 19)), 0, 0))
	end
end

local function daylight(t, motion, clock)
	local sky = if motion
		then 7.45 + 12.2 * ease(t, 0, 3.42) + 13.15 * ease(t, 3.05, 5.24) + 10.4 * ease(t, 5.18, 7.25) + 13.7 * ease(
			t,
			6.98,
			9.45
		)
		else 8.1 + 3.2 * ease(t, 0, 9.5)
	sky = sky % 24
	if t > 9.45 then
		local morning = if motion then 8.90 else 11.3
		local evening = morning + (17.85 - morning) * ease(t, 9.45, 16.81)
		sky = (evening + ((clock - evening + 12) % 24 - 12) * ease(t, 16.81, 19)) % 24
	end
	return sky
end

local function frame(t, motion)
	local near, focus = V(4.8, 6.25, -27.05), V(0, -0.25, -37.25)
	local overview, coast = V(-38, 43.5, 102), V(0, 15.0, -16.0)
	local construction, gate = V(-22, 18.2, 45), V(0.8, 5.1, 10)
	local last, target = V(-32, 29, 66), V(5, 8, 1)
	if not motion then
		if t < 1.7 then
			return near, focus, 44, 0
		end
		if t < 10.0 then
			return overview, coast, 59, 0
		end
		if t < 16.8 then
			return construction, gate, 52, 0
		end
		return last, target, 57, 0
	end
	local pull = ease(t, 0.18, 3.85)
	local lean = ease(t, 8.85, 12.78)
	local reveal = ease(t, 15.25, 19)
	-- Rise before crossing the future gallery roof. The same cleft stays in the
	-- upper middle of the frame as the bridge takes shape in front of it.
	local eye = near:Lerp(overview, pull) + V(0, 11 * math.sin(pull * math.pi), 0)
	eye = eye:Lerp(construction, lean):Lerp(last, reveal)
	local look = focus:Lerp(coast, pull):Lerp(gate, lean):Lerp(target, reveal)
	local fov = 44 + 15 * pull - 7 * lean + 5 * reveal
	return eye, look, fov, -0.035 * reveal
end

function History:draw(t, motion, clock)
	self:prepare(math.huge)
	t = math.clamp(t, 0, 19)
	if self.root.Parent ~= self.stage then
		self.root.Parent = self.stage
	end
	Lighting.ClockTime = daylight(t, motion, clock)
	-- A completed private cove can stay behind the modern actors while the
	-- playable entrance streams. Leave every part still between frames.
	if self.last ~= t then
		self.last = t
		for _, track in self.tracks do
			poseTrack(track, t, self.root, self.shelf)
		end
		-- The camera leaves the impact ocean at dawn. Its mineral-blue water
		-- clears as sunlight returns and the first plants take root on the banks.
		local clear = ease(t, 2.25, 4.95)
		if self.clear ~= clear then
			self.clear = clear
			for _, band in self.water do
				local color = band.old:Lerp(band.new, clear)
				for _, part in band.parts do
					part.Color = color
					part.Reflectance = 0.09 * (1 - clear)
				end
			end
		end
		local pigmentStep = math.clamp(math.floor(t * 15), 0, 117)
		if self.pigmentStep ~= pigmentStep then
			self.pigmentStep = pigmentStep
			for _, ink in self.pigments do
				local amount = ease(t, 2.95 + ink.band * 0.32, 5.9 + ink.band * 0.41)
				if ink.amount ~= amount then
					ink.amount = amount
					local color = ink.old:Lerp(ink.new, amount)
					for _, part in ink.parts do
						part.Color = color
					end
				end
			end
		end
		self.throat.Parent = self.root
		self.throat:PivotTo(self.base * CF(0, -27 * (1 - ease(t, 2.4, 6.9)), 0))
		for i, chunk in self.face do
			local cut = ease(t, 12.3 + 0.27 * math.abs(i - 3), 13.69 + 0.34 * math.abs(i - 3))
			local visible = cut < 0.998
			local parent = if visible then self.root else self.shelf
			if chunk.model.Parent ~= parent then
				chunk.model.Parent = parent
			end
			if visible then
				local hill = ease(t, 2.4, 6.9)
				local step = V((i - 3) * cut * 1.3, -27 * (1 - hill) - cut * 12, 1.7 * math.sin(cut * math.pi))
				chunk.model:PivotTo(self.base * CF(chunk.hinge + step) * A(-0.44 * cut, 0, 0.13 * (i - 3) * cut))
			end
		end
		Worksite.drawCrater(self.crater, self.root, self.shelf, self.base, t)
		Worksite.drawWeather(self.clouds, self.root, self.shelf, self.base, t, motion)
		Worksite.drawBuilders(self.builders, self.root, self.shelf, self.base, t)
	end
	return frame(t, motion)
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
