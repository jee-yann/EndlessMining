local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local Rig = require(script.Parent.RobloxRig)
local Crew = {}
Crew.__index = Crew
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local hot, violet, teal = rgb("FFF0AA"), rgb("C885FF"), rgb("52F5D8")
local neon = Enum.Material.Neon
local stoneAt, jewelAt = V(0.05, 0.96, 4.65), V(0.05, 1.53, 4.65)
local breaksAt, answersAt = Beats.pick, Beats.answer

-- Small head and shoulder accents land on the two voiced syllables of each line.
local function speechAccent(t, speaker)
	for _, line in Beats.dialogue do
		local age = t - line[1] - 0.06
		if speaker == line[3] and age >= 0 and age < 0.44 then
			if age < 0.15 then
				return math.sin(math.pi * age / 0.15)
			end
			return 0.66 * math.sin(math.pi * math.clamp((age - 0.205) / 0.21, 0, 1))
		end
	end
	return 0
end

local function receiver(parent)
	local root = P.model(parent, "Echo receiver")
	P.box(root, "Rubber case", V(0, 0, 0), V(1.27, 0.92, 0.35), "24374B")
	P.box(root, "Amber shell", V(0, 0.015, 0.046), V(1.16, 0.84, 0.31), "F3A64C")
	P.box(root, "Screen bezel", V(-0.08, 0.064, 0.21), V(0.91, 0.54, 0.085), "273849")
	P.box(root, "Phosphor glass", V(-0.08, 0.062, 0.26), V(0.82, 0.445, 0.028), "132E3B")
	P.box(root, "Zero line", V(-0.08, 0.059, 0.281), V(0.79, 0.012, 0.012), "29606A")
	for i = 1, 3 do
		P.box(root, "Scale division", V(-0.49 + i * 0.2, 0.062, 0.279), V(0.008, 0.42, 0.013), "294F5B")
	end
	local trace = {}
	for i = 1, 12 do
		trace[i] = P.box(root, "Signal trace", Vector3.zero, V(0.022, 0.022, 0.085), "74F8D6", nil, neon)
	end
	local pips = {}
	for i = 1, 3 do
		pips[i] = P.box(root, "Echo " .. i, V(-0.33 + (i - 1) * 0.24, -0.285, 0.217), V(0.15, 0.063, 0.043), "483B53")
	end
	for i = 1, 2 do
		P.box(root, "Rocker", V(0.47, 0.20 - (i - 1) * 0.29, 0.20), V(0.125, 0.18, 0.09), "516477")
	end
	P.rod(root, "Whip aerial", V(0.43, 0.38, 0), V(0.52, 1.14, 0), 0.057, rgb("536575"))
	P.sphere(root, "Aerial tip", V(0.52, 1.14, 0), V(0.10, 0.11, 0.10), "FFA84F")
	P.box(root, "Carry grip", V(0, -0.52, -0.03), V(0.48, 0.29, 0.22), "34475A")
	return root, trace, pips
end

local function pickaxe(parent)
	local root = P.model(parent, "Harbor pick")
	P.rod(root, "Hickory shaft", V(0, -0.52, 0), V(0, 1.94, 0), 0.17, rgb("C48954"))
	P.box(root, "Wrapped grip", V(0, 0.02, 0), V(0.23, 0.66, 0.22), "35485B")
	for i = 1, 3 do
		P.box(root, "Grip band", V(0, -0.30 + i * 0.15, 0), V(0.24, 0.04, 0.23), "657B80")
	end
	P.box(root, "Brass socket", V(0, 1.84, 0), V(0.39, 0.45, 0.40), "F2B950")
	for _, s in { -1, 1 } do
		P.rod(root, "Forged shoulder", V(s * 0.1, 1.94, 0), V(s * 0.64, 1.89, 0), 0.245, rgb("B6D0D1"))
		P.rod(root, "Tapered beak", V(s * 0.64, 1.89, 0), V(s * 1.02, 1.57, 0), 0.148, rgb("E4F4ED"))
	end
	return root
end
local bit = V(-1.02, 1.57, 0)

local function nodule(parent)
	local root = P.model(parent, "Signal stone")
	local halves = {}
	for i, s in { -1, 1 } do
		local half = P.model(root, "Fracture half")
		-- Broken ends share a rough cut down the middle. The outer stone
		-- bulges over the warm inclusion until the pick pulls the shell apart.
		local ring, shoulder = {}, {}
		for j = 1, 9 do
			local a = (j - 1) * 2 * math.pi / 9
			local y = math.max(-0.96, math.cos(a) * 1.08)
			ring[j] = V(0.08 * math.sin(a * 3), y, math.sin(a) * 0.91)
			shoulder[j] = V(
				s * (0.70 + 0.13 * math.sin(j * 3 + i)),
				math.max(-0.95, y * (0.70 + 0.12 * math.cos(j + i)) - 0.13),
				ring[j].Z * (0.82 + 0.14 * math.sin(j))
			)
		end
		local outside = V(s * 1.19, -0.20 + 0.12 * i, -0.16 + 0.12 * i)
		local skin = { "303638", "44484A", "292E32", "535758" }
		for j = 1, #ring do
			local nextJ = j % #ring + 1
			local a, b, c, d = ring[j], ring[nextJ], shoulder[j], shoulder[nextJ]
			local shade = rgb(skin[(i + j) % #skin + 1])
			P.face(half, a, b, c, shade)
			P.face(half, b, c, d, if j == 2 + i then rgb("8F948A") else shade)
			P.face(half, c, d, outside, rgb(skin[(2 * i + j) % #skin + 1]))
			P.face(half, a, b, V(s * 0.05, 0, 0), rgb(if j % 4 == 0 then "A5A59B" else "5D6462"))
		end
		for _, p in half:GetChildren() do
			p.Material = Enum.Material.Slate
		end
		halves[i] = half
	end
	local heart = P.crystal(root, Vector3.zero, 0.63)
	heart.Name = "Starfall inclusion"
	local light = P.light(heart:FindFirstChildWhichIsA("BasePart"), "AD82EC", 5.7, 0)
	local crumbs = {}
	for i = 1, 10 do
		local shard = P.sphere(
			root,
			"Basalt chip",
			Vector3.zero,
			V(0.13 + (i % 3) * 0.05, 0.13, 0.18),
			"515657",
			Enum.Material.Slate
		)
		table.insert(crumbs, shard)
	end
	local wave = P.model(parent, "Returned signal")
	local arcs = {}
	for i = 1, 24 do
		arcs[i] = P.box(wave, "Echo arc", Vector3.zero, V(0.12, 0.08, 0.2), "E9B4FF", nil, neon)
	end
	return root, halves, heart, light, crumbs, arcs
end

function Crew.new(shelf, character)
	local self = setmetatable({}, Crew)
	self.root = P.model(shelf, "The knocking crew")
	self.operator = Rig.new(self.root, "Survey operator")
	self.player = Rig.new(self.root, "Expedition miner", character, true)
	self.receiver, self.trace, self.pips = receiver(self.root)
	self.pick = pickaxe(self.root)
	self.stone, self.halves, self.heart, self.light, self.crumbs, self.arcs = nodule(self.root)
	self.facets = {}
	for _, part in self.heart:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Facet" then
			local litEdge = math.floor(#self.facets / 4) % 3 == 1
			table.insert(self.facets, { part = part, color = part.Color, litEdge = litEdge })
		end
	end
	return self
end

local function stick(part, start, finish, width)
	local length = (finish - start).Magnitude
	part.CFrame = CFrame.lookAt((start + finish) * 0.5, finish)
	part.Size = V(width, width, length)
end

function Crew:scan(t, base, motion)
	local pulse = 0
	local answerCount = 0
	for _, beat in Beats.returned do
		if t >= beat then
			answerCount += 1
			pulse = math.max(pulse, math.exp(-(t - beat) * 5.7))
		end
	end
	local speaking = speechAccent(t, "SURVEY LEAD")
	local notice = ease(t, 29.1, 30.67)
	local point = ease(t, 32.8, 34.08)
	local duck = ease(t, 37.39, 37.69) * (1 - ease(t, 37.75, 38.75))
	local relax = ease(t, 39.55, 41.75)
	local shake = if motion then pulse * math.sin(t * 22) else 0
	local receiverAt = V(-3.16, 3.21, 6.77):Lerp(V(-3.12, 3.76, 6.91), notice) - V(0.12, 0.34, 0.11) * point
	local device = base * CF(receiverAt) * A(-0.21 + 0.10 * notice, 0.075 + 0.11 * point, -0.07 + 0.045 * shake)
	self.receiver:PivotTo(device)
	local left = (device * CF(-0.04, -0.40, -0.13)).Position
	local gesture = V(-5.00, 2.40, 5.80):Lerp(V(-4.75, 4.05, 6.29), notice)
	gesture += V(0, 0.12 * speaking, -0.06 * speaking)
	gesture = gesture:Lerp(V(-3.24, 2.0, 6.65), point):Lerp(V(-4.66, 3.74, 6.65), duck)
	self.operator:pose(base * CF(-3.90, 0, 5.40) * A(0, math.pi + 0.55 - 0.88 * point, 0), {
		bob = 0.035 * math.sin(t * 2.4) - 0.27 * duck,
		RootJoint = A(-0.06 + 0.18 * duck, -0.07 * point, 0.04 * shake),
		Neck = A(
			-0.36 * notice + 0.29 * point + 0.27 * duck + 0.077 * speaking,
			-0.28 + 0.71 * point - 0.35 * relax,
			-0.11 * notice + 0.16 * point
		),
		LeftTarget = left,
		RightTarget = base:PointToWorldSpace(gesture),
		LeftHip = A(-0.055, 0, 0.07),
		RightHip = A(0.055, 0, -0.07),
	})
	local previous
	for i = 0, #self.trace do
		local x = i / #self.trace
		local quiet = math.sin(x * 11 + t * 5) * 0.016
		local high = pulse * 0.17 * math.sin(x * 20 - t * 17) * math.sin(math.pi * x)
		local at = (device * CF(-0.478 + 0.797 * x, 0.060 + quiet + high, 0.292)).Position
		if previous then
			local mark = self.trace[i]
			stick(mark, previous, at, 0.019)
			mark.Color = teal:Lerp(violet, pulse)
		end
		previous = at
	end
	for i, pip in self.pips do
		pip.Material = if i <= answerCount then neon else Enum.Material.SmoothPlastic
		pip.Color = if i <= answerCount then hot:Lerp(violet, 0.6) else rgb("483B53")
	end
	self.receiverAim = (device * CF(-0.05, 0.12, 0.26)).Position
end

local function pickFrame(grip, aim, facing)
	local up = (aim - grip).Unit
	local side = up:Cross(facing)
	if side.Magnitude < 0.02 then
		side = up:Cross(Vector3.xAxis)
	end
	side = side.Unit
	-- Map the actual curved steel tip onto the animated swing direction.
	local plane = CFrame.fromMatrix(grip, side, up, side:Cross(up))
	return plane * A(0, 0, -math.atan2(-bit.X, bit.Y))
end

function Crew:mine(t, base)
	local speaking = speechAccent(t, "YOU")
	local alert = ease(t, 29.35, 30.85)
	local gather = ease(t, 34.35, 35.43)
	local windup = ease(t, 35.39, 36.87)
	local chop = ease(t, 36.91, breaksAt)
	local recoil = ease(t, breaksAt, 37.87)
	local listen = ease(t, 38.11, 38.91)
	local reply = ease(t, 38.93, 39.29)
	local run = ease(t, 40.1, 45)
	local settle = ease(t, 39.61, 40.58)
	local gait = math.sin((t - 40.3) * 10.5) * ease(t, 40.25, 41.05)
	local x = 2 - 0.68 * chop + 0.32 * recoil - 1.68 * run
	local z = 6.25 - 0.44 * chop + 0.21 * recoil - 12.2 * run
	local yaw = 0.83 * (1 - settle) + 0.08
	local foot = base * CF(x, 0, z) * A(0, yaw, 0)
	local grip = V(2.91, 2.34, 5.81):Lerp(V(2.68, 3.39, 5.77), gather):Lerp(V(2.51, 5.27, 6.52), windup)
	grip = grip:Lerp(V(1.47, 2.61, 5.12), chop):Lerp(V(1.85, 2.86, 5.59), recoil)
	grip = grip:Lerp(V(2.15, 2.43, 5.52), listen):Lerp(V(2.42, 3.15, 5.78), reply)
	local runningGrip = (foot * CF(0.98, 2.81 - 0.32 * gait, -0.35 + 0.66 * gait)).Position
	local palmAim = base:PointToWorldSpace(grip):Lerp(runningGrip, settle)
	local other = V(1.15, 2.32, 6.71):Lerp(V(0.98, 3.36, 5.77), gather):Lerp(V(0.87, 3.96, 6.14), windup)
	other = other:Lerp(V(0.53, 2.86, 5.5), chop):Lerp(V(0.67, 3.33, 5.39), reply)
	local strideArm = (foot * CF(-1.13, 2.83 + 0.2 * gait, -0.42 - 0.76 * gait)).Position
	local lean = 0.18 * windup - 0.45 * chop + 0.26 * recoil - 0.10 * settle
	local turn = -0.20 * windup + 0.42 * chop - 0.20 * recoil
	self.player:pose(foot, {
		bob = -0.20 * gather + 0.17 * windup - 0.35 * chop + 0.25 * recoil + 0.145 * math.abs(gait),
		RootJoint = A(lean, turn, 0),
		Root = A(lean * 0.6, turn * 0.55, 0),
		Waist = A(lean * 0.4, turn * 0.45, 0),
		Neck = A(
			-0.23 * alert + 0.32 * windup - 0.40 * chop + 0.14 * reply + 0.18 * settle + 0.085 * speaking,
			-0.3 * alert + 0.37 * gather,
			0
		),
		LeftHip = A(0.58 * gait - 0.12 * (chop - recoil), 0, -0.02),
		RightHip = A(-0.58 * gait + 0.12 * (chop - recoil), 0, 0.02),
		LeftKnee = A(-0.60 * math.max(gait, 0), 0, 0),
		RightKnee = A(-0.60 * math.max(-gait, 0), 0, 0),
		RightTarget = palmAim,
		LeftTarget = base:PointToWorldSpace(other):Lerp(strideArm, settle),
	})
	local palm = self.player:palm("Right")
	local aim = V(3.31, 3.85, 4.55):Lerp(V(2.85, 5.12, 5.53), gather):Lerp(V(2.58, 6.72, 7.85), windup)
	aim = aim:Lerp(V(0.18, 1.55, 4.80), chop):Lerp(V(0.48, 2.09, 4.8), recoil):Lerp(V(3.03, 4.62, 5.91), reply)
	local aimWorld = base:PointToWorldSpace(aim)
		:Lerp(palm + foot:VectorToWorldSpace(V(0.38, 1.8, 0.35 + 0.25 * gait)), settle)
	local tool = pickFrame(palm, aimWorld, foot.LookVector)
	self.pick:PivotTo(tool)
	self.playerAim = self.player.head.Position + Vector3.yAxis * (self.player.headroom * 0.30)
	self.pickTip = (tool * CF(bit)).Position
end

function Crew:fracture(t, base)
	local open = ease(t, breaksAt, 38.09)
	local age = math.max(0, t - breaksAt)
	local answerAge = t - answersAt
	local echo = if answerAge >= 0 then math.exp(-answerAge * 4.25) else 0
	local hum = (0.5 + 0.5 * math.sin(t * 5)) * 0.18
	for i, half in self.halves do
		local side = if i == 1 then -1 else 1
		local bounce = math.abs(math.sin(age * 11)) * math.exp(-age * 3.6)
		local at = stoneAt + V(side * (1.17 + 0.14 * i) * open, 0.34 * bounce - 0.36 * open, (i - 0.9) * 0.34 * open)
		half:PivotTo(base * CF(at) * A(0.22 * open, side * 0.37 * open, -side * 0.48 * open))
	end
	local rise = ease(t, 37.48, 38.1)
	local core = base
		* CF(jewelAt + V(0, -0.49 + 0.49 * rise + 0.12 * echo, 0))
		* A(0.10, 0.2 + rise * 0.73 + echo * 0.34, -0.22)
	self.heart:PivotTo(core)
	self.light.Brightness = open * (0.32 + hum + echo * 1.12)
	if echo > 0.01 or self.answerVisible then
		self.answerVisible = echo > 0.01
		for _, face in self.facets do
			face.part.Color = face.color:Lerp(if face.litEdge then rgb("9962DB") else rgb("B98CEA"), echo * 0.66)
			face.part.Material = if face.litEdge and echo > 0.28 then neon else Enum.Material.SmoothPlastic
		end
	end
	self.coreAim = core.Position
	for i, shard in self.crumbs do
		local az = i * 2.399
		local r = (0.52 + i * 0.12) * math.min(1, age * 1.45)
		local height = math.max(0, 0.48 + age * (3.2 + i * 0.22) - 12 * age * age)
		shard.CFrame = base
			* CF(stoneAt + V(math.sin(az) * r, height - 0.75, math.cos(az) * r))
			* A(az, age * 4, az + age)
		shard.Transparency = if age > 0 then ease(t, 37.85, 38.53) else 1
	end
	local radius = 0.42 + math.max(0, answerAge) * 8
	for i, p in self.arcs do
		if answerAge >= 0 and answerAge <= 0.85 then
			local a = (i - 1) * math.pi * 2 / #self.arcs
			local at = V(stoneAt.X + math.cos(a) * radius, 0.065, stoneAt.Z + math.sin(a) * radius)
			p.CFrame = base * CF(at) * A(0, -a, 0)
			p.Size = V(0.13, 0.065, radius * 0.254)
			p.Transparency = 0.06 + 0.94 * ease(t, answersAt + 0.20, answersAt + 0.85)
		else
			p.Transparency = 1
		end
	end
end

function Crew:draw(t, base, motion)
	self:scan(t, base, motion)
	self:mine(t, base)
	self:fracture(t, base)
end
return Crew
