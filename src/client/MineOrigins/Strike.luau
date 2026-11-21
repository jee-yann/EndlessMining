local P = require(script.Parent.Props)
local Strike = {}
Strike.__index = Strike

local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb, ease, tau = Color3.fromHex, P.ease, math.pi * 2
local stone, neon = Enum.Material.Slate, Enum.Material.Neon
local flightTime = require(script.Parent.Beats).impact
local impact = V(0, 1.5, 0)
local approach = V(-218, 186.5, -122)
Strike.impactTime = flightTime

-- Negative time extrapolates the entry trajectory so the wake already has a
-- history when the first shot opens. All three flight cameras track this body.
function Strike.position(t)
	local u = math.min(t / flightTime, 1)
	local distance = 0.27 * u + 0.73 * math.max(0, u) ^ 2.2
	return impact + approach * (1 - distance) + V(9, 14, 6) * math.sin(distance * math.pi)
end

local function pair(parent, name, a, b, width, color, material)
	local rod = P.rod(parent, name, a, b, width, rgb(color))
	rod.Material = material
	return rod
end

local function between(p, base, a, b, width, height)
	p.Size = V(width, height, math.max(0.06, (b - a).Magnitude))
	p.CFrame = base * CFrame.lookAt((a + b) * 0.5, b)
end

local function place(p, parent)
	if p.Parent ~= parent then
		p.Parent = parent
	end
end

local function ball(parent, name, at, size, hue, mat)
	local p = P.sphere(parent, name, at, size, hue, mat)
	p.CastShadow = mat ~= neon
	return p
end

local function ellipse(parent, name, color, mat)
	return ball(parent, name, Vector3.zero, Vector3.one, color, mat)
end

local function stratum(parent, name, hue, size, at)
	local p = P.cylinder(parent, name, at, 1, 1, hue, stone)
	-- Cylinder length runs along local X, now vertical.
	p.Size = V(size.Y, size.X, size.Z)
	return p
end

local function marker(parent, name, at)
	local anchor = P.box(parent, name, at, Vector3.one, "FFFFFF")
	anchor.Transparency, anchor.CastShadow = 1, false
	return anchor
end

local function ribbon(anchor, a, b, near, far, color, fade)
	local first, last = Instance.new("Attachment", anchor), Instance.new("Attachment", anchor)
	first.Position, last.Position = a, b
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = first, last
	beam.FaceCamera, beam.Width0, beam.Width1 = true, near, far
	beam.Color, beam.Transparency = color, fade
	beam.Texture, beam.TextureMode = "rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch
	beam.Parent = anchor
	return beam, last
end

local function sprite(parent, name, asset, brightness)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.AlwaysOnTop, gui.LightInfluence, gui.Brightness = name, false, 0, brightness
	gui.Size, gui.Parent = UDim2.fromScale(1, 1), parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency, image.Size = 1, UDim2.fromScale(1, 1)
	image.Image, image.Parent = "rbxasset://textures/particles/" .. asset, gui
	return gui, image
end

local function buildCoast(root, rng)
	-- The impact falls below the back of today's gallery. The lagoon and
	-- smaller landing island lie to its south (+Z), just as they do at spawn.
	local shore = P.model(root, "Ancient mine headland")
	local sea = P.box(shore, "Open ocean", V(0, -8.6, 0), V(1900, 1, 1900), "31586F")
	sea.Reflectance = 0.09
	for i = 1, 52 do
		local x, z = rng:NextNumber(-220, 220), rng:NextNumber(-150, 260)
		local whitecap = ball(
			shore,
			"Ocean swell",
			V(x, -8.08, z),
			V(rng:NextNumber(3, 16), 0.075, rng:NextNumber(0.17, 0.58)),
			"7599A2"
		)
		whitecap.CastShadow = false
	end
	local shade = { "776866", "796A69", "786968", "756566" }
	local n, inner, mid, rim, foot = 24, {}, {}, {}, {}
	for i = 1, n do
		local a = tau * i / n
		local x, z = math.cos(a), math.sin(a)
		local jag = rng:NextNumber(0.86, 1.08)
		inner[i] = V(x * 8.1, 0, z * 7.7)
		mid[i] = V(x * 26, 0.54 + math.sin(a * 3) * 0.74, z * 23)
		rim[i] = V(x * 74 * jag, 1.1 + 2.7 * math.sin(a * 2) - math.max(z, 0) * 2.1, z * 56 * jag)
		foot[i] = V(rim[i].X * 1.08, -10, rim[i].Z * 1.09)
	end
	for i = 1, n do
		local j = i % n + 1
		local c = rgb(shade[i % #shade + 1])
		P.face(shore, inner[i], mid[i], mid[j], c)
		P.face(shore, inner[i], mid[j], inner[j], c)
		P.face(shore, mid[i], rim[i], rim[j], c)
		P.face(shore, mid[i], rim[j], mid[j], c)
		P.face(shore, rim[i], foot[i], foot[j], rgb("66505B"))
		P.face(shore, rim[i], foot[j], rim[j], rgb("9B786A"))
	end
	-- Low stacked headlands leave the central approach and its horizon legible.
	for _, ridge in { V(-61, 0, -23), V(-47, 0, -43), V(58, 0, -16), V(40, 0, -47), V(1, -5, 101), V(-102, -3, 70) } do
		local tall = if ridge.Z > 65 then 2 else rng:NextNumber(5, 11)
		local ground, ledge, crown = {}, {}, {}
		local count = 9
		for j = 1, count do
			local theta = j * tau / count
			local x, z = math.cos(theta), math.sin(theta)
			local irregular = rng:NextNumber(0.85, 1.12)
			ground[j] = ridge + V(x * 21 * irregular, -3, z * 15 * irregular)
			ledge[j] = ridge + V(x * 17 * irregular, tall * rng:NextNumber(0.3, 0.57), z * 12 * irregular)
			crown[j] = ridge
				+ V(3 + x * 12 * irregular, tall * (0.72 + 0.22 * math.sin(theta * 2 + 0.4)), z * 7 * irregular)
		end
		for j = 1, count do
			local k = j % count + 1
			local flank = rgb(if j % 3 == 0 then "8D7470" else "816B69")
			P.face(shore, ground[j], ground[k], ledge[k], flank)
			P.face(shore, ground[j], ledge[k], ledge[j], flank)
			P.face(shore, ledge[j], ledge[k], crown[k], rgb("A58779"))
			P.face(shore, ledge[j], crown[k], crown[j], rgb("9F8073"))
			P.face(shore, crown[j], crown[k], ridge + V(4, tall, 0), rgb("7B6D6D"))
		end
	end
	for i = 1, 20 do
		local a = rng:NextNumber(0, tau)
		local r = rng:NextNumber(13, 43)
		local s = rng:NextNumber(0.32, 1.65)
		local p =
			ball(shore, "Lava boulder", V(math.cos(a) * r, 0.3, math.sin(a) * r), V(1.8, 1, 1.3) * s, "77636A", stone)
		p.CFrame *= A(0.2, a, -0.16)
	end
	-- The lowest clouds frame the real descent corridor. A gap around the
	-- centerline keeps the meteor visible to the camera traveling alongside it.
	for i = 1, 17 do
		local time = rng:NextNumber(1.6, 8.9)
		local side = if i % 2 == 1 then -1 else 1
		local center = Strike.position(time)
			+ V(side * rng:NextNumber(28, 63), -rng:NextNumber(9, 31), rng:NextNumber(-54, -24))
		local anchor = marker(shore, "High vapor", center)
		local mist = ribbon(
			anchor,
			V(-19, 0, 0),
			V(19, 1.2, 1),
			rng:NextNumber(7, 10),
			rng:NextNumber(8, 16),
			ColorSequence.new(rgb("DAD3D0"), rgb("9BAAB8")),
			NumberSequence.new(0.48)
		)
		mist.LightInfluence, mist.TextureSpeed = 0.48, 0
	end
	return shore
end

local function buildMeteor(root)
	local body = P.model(root, "Starfall meteor")
	ball(body, "Incandescent mantle", Vector3.zero, V(5.18, 4.98, 5.10), "834D3F", stone)
	-- Closed, overlapping plates surround a solid body. The raised lip and
	-- pinched channels leave streaks of color between dark chunks of crust.
	local rows, columns = 5, 9
	local shell = {}
	for j = 0, rows do
		shell[j] = {}
		local lat = -math.pi * 0.5 + j * math.pi / rows
		for i = 1, columns do
			local polar = tau * (i + (0.33 * (j % 2))) / columns
			local d = V(math.cos(polar) * math.cos(lat), math.sin(lat), math.sin(polar) * math.cos(lat))
			local radius = 3.03 + 0.26 * math.sin(i * 2.2 + j * 3.7) * math.cos(lat)
			shell[j][i] = V(d.X * radius * 1.07, d.Y * radius * 0.96, d.Z * radius)
		end
	end
	local hues = { "57434D", "493747", "76504B", "483F4B", "80564E", "674B4C" }
	for j = 0, rows - 1 do
		for i = 1, columns do
			local k = i % columns + 1
			local a, b, c, d = shell[j][i], shell[j][k], shell[j + 1][k], shell[j + 1][i]
			local center = (a + b + c + d) / 4
			local fracture = if (i + 3 * j) % 5 <= 2 then 0.017 else 0.088
			a, b, c, d =
				a:Lerp(center, fracture), b:Lerp(center, fracture), c:Lerp(center, fracture), d:Lerp(center, fracture)
			local tone = rgb(hues[(i * 5 + j * 3) % #hues + 1])
			if j > 0 then
				P.face(body, a, b, d, tone)
			end
			if j < rows - 1 then
				P.face(body, b, c, d, tone:Lerp(rgb("D38260"), 0.15))
			end
		end
	end
	for path = 1, 4 do
		local longitude = tau * path / 4 + 0.29 * math.sin(path * 2.12)
		local prior
		for step = 0, 6 do
			local lat = -0.92 + 0.33 * math.sin(path * 2.24) + step * (0.17 + 0.045 * (path % 3))
			local lon = longitude + math.sin(step * 2.1 + path) * 0.26 + step * 0.055
			local v = V(math.cos(lat) * math.cos(lon) * 3.11, math.sin(lat) * 2.9, math.cos(lat) * math.sin(lon) * 3.05)
			if prior then
				pair(
					body,
					"Molten fissure",
					prior,
					v,
					if step % 2 == 0 then 0.075 else 0.13,
					if path == 2 then "D4A1F9" elseif path == 1 then "FFD89F" else "FA9A65",
					neon
				)
			end
			prior = v
		end
	end
	for i = 1, 19 do
		local y = 1 - (i - 0.5) * 2 / 19
		local a = i * 2.399
		local r = math.sqrt(1 - y * y)
		local normal = V(math.cos(a) * r, y, math.sin(a) * r)
		local center = normal * (2.70 + 0.10 * math.sin(i * 2.7))
		local w = 1.1 + 0.9 * (0.5 + 0.5 * math.sin(i * 3.6))
		local clast =
			ball(body, "Ablated basalt", center, V(w, w * (0.56 + 0.12 * (i % 3)), 0.68), hues[i % #hues + 1], stone)
		clast.CFrame = CFrame.lookAt(center, center + normal) * A(0, 0, a)
	end
	for _, surface in body:GetChildren() do
		if surface.Name == "Facet" then
			surface.Material = stone
		end
	end
	local key = marker(body, "Fire on the leading face", V(1.9, -1.8, 2.1))
	P.light(key, "FFB57B", 9, 2.6)
	local nucleus = body:FindFirstChild("Incandescent mantle")
	P.light(nucleus, "FFB06C", 42, 3.1)
	return body
end

local function buildWake(self)
	local wake = P.model(self.root, "Plasma wake")
	self.wake = wake
	self.torch = P.model(wake, "Continuous plasma")
	local sections = {
		{ 1.7, 0.86, "FFD99B" },
		{ 3.5, 1.23, "FFD18C" },
		{ 5.5, 1.21, "FFB370" },
		{ 7.7, 0.79, "ED9A70" },
		{ 9.6, 0.51, "D38E7E" },
		{ 11.8, 0.18, "CA8F91" },
		{ 14, 0.055, "9B8198" },
	}
	local previous
	for j, section in sections do
		local z, r = section[1], section[2]
		local ring = {}
		for i = 1, 6 do
			local theta = tau * i / 6 + j * 0.18
			ring[i] = V(math.cos(theta) * r + 0.40 * math.sin(j * 0.72), math.sin(theta) * r + 0.035 * j * j, -z)
		end
		if previous then
			local skin = P.model(self.torch, "Flame front")
			for i = 1, 6 do
				local k = i % 6 + 1
				P.face(skin, previous[i], previous[k], ring[k], rgb(sections[j - 1][3]))
				P.face(skin, previous[i], ring[k], ring[i], rgb(section[3]))
			end
			for _, p in skin:GetChildren() do
				p.Material, p.Transparency, p.CastShadow = neon, math.min(0.97, 0.17 + (j - 2) * 0.16), false
			end
		end
		previous = ring
	end
	-- A windward shock cap stays with the velocity vector while the pitted
	-- stone rotates through it. Its broken incandescent lip reads in profile.
	for i = 1, 22 do
		if i % 9 < 5 then
			local an = tau * i / 22
			local bn = tau * (i + 1) / 22
			local a = V(math.cos(an) * 2.45, math.sin(an) * 2.45, 1.92 + 0.1 * math.sin(an * 3))
			local b = V(math.cos(bn) * 2.45, math.sin(bn) * 2.45, 1.92 + 0.1 * math.sin(bn * 3))
			pair(self.torch, "Bow shock", a, b, 0.11, if i % 3 == 0 then "FFE4A6" else "FFA969", neon)
		end
	end
	self.wakeAnchor = marker(wake, "Ionized air", Vector3.zero)
	local plasma = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb("FFF4D3")),
		ColorSequenceKeypoint.new(0.32, rgb("FFB374")),
		ColorSequenceKeypoint.new(0.69, rgb("EF98B7")),
		ColorSequenceKeypoint.new(1, rgb("AC93CE")),
	})
	local haze, last = ribbon(
		self.wakeAnchor,
		V(0, 0, -1.1),
		V(0, 0, -46),
		7.2,
		0.16,
		plasma,
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.52),
			NumberSequenceKeypoint.new(0.25, 0.36),
			NumberSequenceKeypoint.new(0.68, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
	)
	haze.LightEmission, haze.LightInfluence, haze.TextureSpeed = 0.94, 0, -0.23
	self.wakeEnd = last
	haze.Attachment0.Axis, haze.Attachment1.Axis = V(0.25, 0.12, -1).Unit, V(-0.1, 0.22, -1).Unit
	haze.CurveSize0, haze.CurveSize1 = 9, 12
	local curl, far = ribbon(
		self.wakeAnchor,
		V(-1, 0.55, -2),
		V(1, 3, -34),
		4.4,
		1.1,
		ColorSequence.new(rgb("FFBD80"), rgb("A492A3")),
		NumberSequence.new(0.19, 0.86)
	)
	curl.LightEmission, curl.TextureSpeed = 0.73, 0.21
	curl.Attachment0.Axis, curl.Attachment1.Axis = V(-0.43, 0.36, -1).Unit, V(0.43, -0.16, -1).Unit
	curl.CurveSize0, curl.CurveSize1 = 8, 11
	self.wispEnd = far
	-- These textured billows follow the recent flight path. They are visible
	-- on the very first frame and remain individually readable on the flyby.
	self.billows = {}
	for i = 1, 16 do
		local anchor = marker(wake, "Streaming vapor", Vector3.zero)
		local burning = i <= 10
		local gui, img = sprite(
			anchor,
			if burning then "Ablation flame" else "Exhaust smoke",
			if burning then "explosion01_core_main.dds" else "smoke_main.dds",
			if burning then 3.6 else 1.15
		)
		img.ImageColor3 = if burning then rgb("FFF0D4") else rgb("9A8B96")
		self.billows[i] = { anchor = anchor, gui = gui, img = img, fire = burning }
	end
	local vapor = Instance.new("ParticleEmitter")
	vapor.Name, vapor.Texture, vapor.Rate = "Plasma vapor", "rbxasset://textures/particles/smoke_main.dds", 28
	vapor.Color, vapor.LightEmission = plasma, 0.65
	vapor.Speed, vapor.Drag = NumberRange.new(1, 3.5), 0.45
	vapor.Lifetime, vapor.SpreadAngle = NumberRange.new(0.35, 0.92), Vector2.new(45, 45)
	vapor.Size = NumberSequence.new(2.1, 5.8)
	vapor.Transparency = NumberSequence.new(0.48, 1)
	vapor.Parent = self.wakeAnchor
	self.sparks = {}
	for i = 1, 16 do
		local p = ellipse(wake, "Ablating ember", if i % 4 == 0 then "E7B6FF" else "FFD79A", neon)
		self.sparks[i] = p
	end
end

local function drawWake(self, t, base)
	local head = Strike.position(t)
	local reverse = (Strike.position(t - 0.04) - head).Unit
	local side = reverse:Cross(Vector3.yAxis).Unit
	local up = side:Cross(reverse).Unit
	local stepLength = (Strike.position(t - 0.85) - head).Magnitude
	local length = math.clamp(stepLength * 1.33, 26, 71)
	local pose = base * CFrame.lookAt(head, head + reverse)
	self.torch:PivotTo(pose * A(0, 0, 0.14 * math.sin(t * 3.1)))
	self.wakeAnchor.CFrame = pose
	self.wakeEnd.Position = V(0, 3, -length)
	self.wispEnd.Position = V(1 + math.sin(t * 2.1) * 1.15, 2.2, -length * 0.78)
	for i, lobe in self.billows do
		local u = if lobe.fire then ((i - 1) / 10 + t * 0.38) % 1 else ((i - 11) / 6 + t * 0.29) % 1
		local age = if lobe.fire then 0.035 + u * 0.56 else 0.24 + u * 0.87
		local swirl = (up * math.sin(i * 2.15 + t * 2.3) + side * math.cos(i * 2.15 + t * 2.3)) * (0.42 + u * 1.45)
		local path = Strike.position(t - age)
		-- A minimum exhaust speed keeps the train streaming even high above the cove.
		local d = math.max((path - head).Magnitude, age * 38)
		lobe.anchor.Position = base:PointToWorldSpace(head + reverse * (1.5 + d) + swirl + up * (u * u * 1.9))
		local width = if lobe.fire then 7.1 - 3.4 * u else 5.5 - 2.1 * u
		lobe.gui.Size = UDim2.fromScale(width * 1.5, width)
		lobe.img.Rotation = i * 61 + t * (if i % 2 == 0 then 29 else -23)
		local opacity = (if lobe.fire then 0.94 else 0.76) * ease(u, -0.08, 0.11) * (1 - ease(u, 0.43, 1))
		lobe.img.ImageTransparency = 1 - opacity
	end
	for i, p in self.sparks do
		local u = (t * (0.77 + i % 3 * 0.12) + i * 0.618) % 1
		local a = i * 2.399
		local outward = (side * math.cos(a) + up * math.sin(a)) * (1.9 + u * (4 + i % 5))
		local pos = head + reverse * (2 + u * length * 0.92) + outward
		local w = 0.14 + (1 - u) * 0.24
		between(p, base, pos, pos + reverse * (1.05 + u * 3), w, w)
		p.Transparency = 0.08 + 0.90 * u * u
	end
end

local function buildImpact(self, rng)
	local root = self.root
	self.cap = stratum(root, "Unbroken bedrock", "7A6669", V(16.3, 0.95, 15.5), V(0, -0.47, 0))
	local crater = P.model(root, "Buried Starfall")
	self.crater = crater
	stratum(crater, "Crater floor", "3F3547", V(16.7, 0.47, 16), V(0, -2.42, 0))
	local core = ball(crater, "Exposed core", V(0, -0.97, 0), V(4.15, 3.1, 3.9), "866384", stone)
	self.core = core
	self.pulse = ball(crater, "Violet inclusion", V(0.16, 0.48, 0.16), V(1.19, 0.54, 1.32), "F3BCFF", neon)
	self.light = P.light(self.pulse, "D69AFF", 19, 2.2)
	for i = 1, 21 do
		local theta = tau * i / 21
		local dir = V(math.cos(theta), 0, math.sin(theta))
		local n = dir * 7.61
		local mass = rng:NextNumber(0.72, 1.16)
		P.box(
			crater,
			"Overturned crust",
			n + V(0, -0.27, 0),
			V(2.1 * mass, 0.64 * mass, 2.5 * mass),
			if i % 4 == 0 then "997365" else "61505B",
			A(rng:NextNumber(-0.18, 0.18), -theta + 0.15, rng:NextNumber(-0.21, 0.21)),
			stone
		)
		local a, b = dir * 7.9, dir * 4.7 + V(0, -1.9, 0)
		local tangent = V(-dir.Z, 0, dir.X) * 1.45
		P.face(crater, a + tangent, a - tangent, b + tangent * 0.68, rgb("574351"))
		P.face(crater, a - tangent, b - tangent * 0.68, b + tangent * 0.68, rgb("6D5059"))
	end
	self.cracks = {}
	for i = 1, 8 do
		local angle = i * 2.399
		local length = if i % 3 == 0 then 10.6 else 6.7
		local prior = V(0.16, 0.44, 0.16)
		for j = 1, 4 do
			local r = length * j / 4
			local a = angle + 0.16 * math.sin(j * 2.1 + i)
			local p =
				V(math.cos(a) * r, if r > 7.6 then 0.12 else -1.64 + math.max(0, 1 - r / 3) * 1.60, math.sin(a) * r)
			local seg = pair(
				crater,
				"Hot fracture",
				prior,
				p,
				0.28 * (1 - j * 0.14),
				if i % 3 == 0 then "FFD69B" else "DE9AF7",
				neon
			)
			table.insert(self.cracks, { p = seg, r = r })
			prior = p
		end
	end
	self.sediment = {}
	for i = 1, 5 do
		local m = P.model(crater, "Settling rock")
		local lo, hi = tau * (i - 1) / 5 - 0.035, tau * i / 5 + 0.035
		local mid = (lo + hi) * 0.5
		local lip = V(math.cos(mid) * 7.5, 0, math.sin(mid) * 7.1)
		local hue = rgb(({ "6F585E", "8C6D65", "9C7D6C", "8B7368", "82696A" })[i])
		local center = V(0.07 * math.cos(mid), -0.08, 0.07 * math.sin(mid))
		local last
		for k = 0, 5 do
			local a = lo + (hi - lo) * k / 5
			local v = V(math.cos(a) * 8.05, -0.13 + (k % 2) * 0.09, math.sin(a) * 7.65)
			if last then
				P.face(m, center - lip, last - lip, v - lip, hue)
				local edge = V(0, 0.55, 0)
				P.face(m, last - lip - edge, v - lip - edge, v - lip, hue:Lerp(rgb("513E50"), 0.40))
				P.face(m, last - lip, v - lip, last - lip - edge, hue:Lerp(rgb("513E50"), 0.40))
			end
			last = v
		end
		self.sediment[i] = { m = m, lip = lip }
	end

	local crown = P.model(root, "Impact crown")
	self.crown = crown
	self.flash = ellipse(crown, "Impact flash", "FFF5D3", neon)
	self.impactLight = P.light(self.flash, "FFD495", 58, 4)
	self.lobes = {}
	for i = 1, 14 do
		local a = i * 2.399
		local dir = V(math.cos(a), 0, math.sin(a))
		local p = ellipse(crown, "Incandescent ejecta", if i % 3 == 0 then "FFBE68" else "FF915C", neon)
		local ash =
			ellipse(crown, "Rolling ash", if i % 3 == 0 then "876F74" else "A78279", Enum.Material.SmoothPlastic)
		local flameSprite, flameImage = sprite(p, "Rolling flame", "explosion01_core_main.dds", 3.2)
		local dustSprite, dustImage = sprite(ash, "Volcanic ash", "smoke_main.dds", 0.85)
		dustImage.ImageColor3 = rgb(if i % 2 == 0 then "9B8E90" else "BBA59C")
		flameImage.Rotation, dustImage.Rotation = i * 41, i * 79
		self.lobes[i] = {
			flameSprite = flameSprite,
			flameImage = flameImage,
			dustSprite = dustSprite,
			dustImage = dustImage,
			fire = p,
			ash = ash,
			dir = dir,
			delay = (i % 5) * 0.052,
			radius = rng:NextNumber(7, 15),
			lift = rng:NextNumber(7.5, 15.8),
		}
	end
	-- Project the pressure wave flush to the ground with a feathered edge.
	-- Each sheet belongs to the private set and vanishes as it clears the cove.
	self.waves = {}
	for i = 1, 2 do
		local sheet = marker(crown, "Pressure front", V(0, 0.46, 0))
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.LightInfluence, gui.Brightness = Enum.NormalId.Top, 0, if i == 1 then 2.4 else 1.1
		gui.CanvasSize, gui.Parent = Vector2.new(256, 256), sheet
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency, image.Size = 1, UDim2.fromScale(1, 1)
		image.Image, image.ImageColor3 =
			"rbxasset://textures/particles/explosion01_shockwave_main.dds", rgb(if i == 1 then "FFF0C3" else "CCC2B2")
		image.Parent = gui
		self.waves[i] = { p = sheet, image = image }
	end
	self.column = marker(crown, "Rising column", Vector3.zero)
	self.columnSprite, self.columnImage = sprite(self.column, "Fire column", "explosion01_core_main.dds", 3.6)
	self.ejecta = {}
	for i = 1, 28 do
		local a = i * 2.399
		local speed = rng:NextNumber(7.8, 21.5)
		local v = V(math.cos(a) * speed, rng:NextNumber(13, 36), math.sin(a) * speed)
		local s = rng:NextNumber(0.23, 0.96)
		local p = ball(crown, "Basalt ejecta", Vector3.zero, V(s * 1.5, s, s * 1.4), "695363", stone)
		local scale = rng:NextNumber(1, 1.7)
		local tail, tip = ribbon(
			p,
			Vector3.zero,
			V(0, -4, 0),
			s * scale + 0.18,
			0.04,
			ColorSequence.new(rgb("FFB772"), rgb("9E818B")),
			NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.06),
				NumberSequenceKeypoint.new(0.38, 0.24),
				NumberSequenceKeypoint.new(1, 1),
			})
		)
		tail.LightEmission, tail.TextureSpeed = 0.85, 0
		self.ejecta[i] = { p = p, tail = tail, tip = tip, v = v, s = s, scale = scale, delay = (i % 4) * 0.07 }
	end
	local plume = Instance.new("ParticleEmitter")
	plume.Name, plume.Texture, plume.Rate = "Impact dust", "rbxasset://textures/particles/smoke_main.dds", 0
	plume.Lifetime, plume.Speed = NumberRange.new(1.2, 2.0), NumberRange.new(6, 20)
	plume.SpreadAngle, plume.Drag = Vector2.new(72, 72), 1.7
	plume.Color = ColorSequence.new(rgb("BF9384"), rgb("655C69"))
	plume.Size = NumberSequence.new(2.4, 8.1)
	plume.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.55, 0.58),
		NumberSequenceKeypoint.new(1, 1),
	})
	plume.Parent = core
	local flame = Instance.new("ParticleEmitter")
	flame.Name, flame.Texture, flame.Rate =
		"Incandescent dust", "rbxasset://textures/particles/explosion01_core_main.dds", 0
	flame.Lifetime, flame.Speed = NumberRange.new(0.38, 0.92), NumberRange.new(13, 32)
	flame.SpreadAngle, flame.Drag = Vector2.new(51, 51), 2.4
	flame.LightEmission, flame.Brightness = 1, 2
	flame.Rotation, flame.RotSpeed = NumberRange.new(0, 359), NumberRange.new(-75, 75)
	flame.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4.2),
		NumberSequenceKeypoint.new(0.45, 13),
		NumberSequenceKeypoint.new(1, 16),
	})
	flame.Transparency = NumberSequence.new(0.02, 1)
	flame.Parent = core
	self.blastFlame = flame
	self.plume = plume
end

function Strike.new(shelf)
	local root = P.model(shelf, "Primordial cove")
	local self = setmetatable({ root = root, shelf = shelf }, Strike)
	local rng = Random.new(58237)
	buildCoast(root, rng)
	self.meteor = buildMeteor(root)
	buildWake(self)
	buildImpact(self, rng)
	return self
end

local function drawBlast(self, t, base, motion)
	local age = t - flightTime
	-- First the compression flash, then a crown of fire with its own rolling ash
	-- and delayed ballistics. The last airborne stones outlive the flash.
	local flash = self.flash
	local burst = math.clamp(age / 0.32, 0, 1)
	flash.Size = V(1 + burst * 17, 0.8 + burst * 11, 1 + burst * 17)
	flash.Position = base:PointToWorldSpace(V(0, 1.15 + burst * 2.9, 0))
	flash.Transparency = if age > 0.54 then 1 else 0.12 + 0.88 * ease(age, 0.14, 0.54)
	self.impactLight.Brightness = (if motion then 5.5 else 2.5) * (1 - ease(age, 0.18, 1.35))
	for i, lobe in self.lobes do
		local s = math.max(0, age - lobe.delay)
		local rise = ease(s, 0, 0.76)
		local climb = ease(s, 0.44, 2.7)
		local lead = lobe.dir * (lobe.radius * (0.14 + 0.84 * rise + 0.16 * climb))
			+ V(0, 1 + lobe.lift * (0.27 * rise + 0.66 * climb), 0)
		local size = 0.3 + rise * (6 + i % 4) + climb * 2.2
		lobe.fire.Position = base:PointToWorldSpace(lead)
		lobe.fire.Size = V(size, size * (1.18 + 0.32 * rise), size * 0.85)
		local fireOpacity = if age < lobe.delay then 0 else 1 - ease(s, 0.42, 1.49)
		lobe.fire.Transparency = 1 - 0.18 * fireOpacity * (1 - ease(s, 0.08, 0.51))
		lobe.flameSprite.Size = UDim2.fromScale(size * 2.3, size * (2.5 + 0.36 * rise))
		lobe.flameImage.ImageTransparency = 1 - fireOpacity
		lobe.flameImage.Rotation = i * 41 + s * (if i % 2 == 0 then 27 else -24)
		lobe.ash.Position = base:PointToWorldSpace(lead + lobe.dir * climb * 2 + V(0, climb * 1.8, 0))
		lobe.ash.Size = V(size * (1 + 0.55 * climb), size * (0.85 + 0.49 * climb), size * (0.81 + 0.5 * climb))
		local smokeOpacity = ease(s, 0.24, 0.81) * (1 - ease(s, 1.20, 2.96))
		lobe.ash.Transparency = 1
		lobe.dustSprite.Size = UDim2.fromScale(size * (1.9 + 0.56 * climb), size * (2.4 + 0.5 * climb))
		lobe.dustImage.ImageTransparency = 1 - smokeOpacity
		lobe.dustImage.Rotation = i * 79 + s * (if i % 2 == 0 then -20 else 19)
	end
	for j, wave in self.waves do
		local s = math.max(0, age - (j - 1) * 0.23)
		local span = 2 + s * (if j == 1 then 86 else 58)
		wave.p.Size = V(span, 0.055, span)
		wave.p.CFrame = base * CF(0, 0.56 + s * 0.35, 0)
		wave.image.ImageTransparency = if age < (j - 1) * 0.23 then 1 else ease(s, 0.34, 1.58)
	end
	local rise = ease(age, 0.06, 0.72)
	self.column.Position = base:PointToWorldSpace(V(0, 2 + rise * 11 + ease(age, 0.72, 1.5) * 5, 0))
	self.columnSprite.Size = UDim2.fromScale(3 + rise * 15, 4 + rise * 39)
	self.columnImage.ImageTransparency = ease(age, 0.6, 1.48)
	self.columnImage.Rotation = -8 + age * 9
	for i, chunk in self.ejecta do
		local s = math.max(0, age - chunk.delay)
		local function point(dt)
			return V(0, 0.7, 0) + chunk.v * dt - V(0, 12.0 * dt * dt, 0)
		end
		local pos = point(s)
		local hidden = age < chunk.delay or pos.Y < 0.4
		chunk.p.CFrame = base * CF(pos) * A(s * 4, i + s * 3, s * 1.5)
		chunk.p.Transparency = if hidden then 1 else ease(age, 2.45, 3.2)
		local behind = point(math.max(-0.015, s - 0.23 * chunk.scale))
		chunk.tip.Position = chunk.p.CFrame:PointToObjectSpace(base:PointToWorldSpace(behind))
		chunk.tail.Enabled = not hidden and s < 1.48
		chunk.tail.Width0 = (0.15 + chunk.s * 0.9) * (1 - 0.68 * ease(s, 0.48, 1.40))
	end
	if age < 0.6 and not self.emitted then
		self.plume:Emit(if motion then 62 else 26)
		self.blastFlame:Emit(if motion then 48 else 20)
		self.emitted = true
	end
end

local function drawBurial(self, t, base)
	local cover = ease(t, 13.13, 15.1)
	self.core.Position = base:PointToWorldSpace(V(0, -0.97 - cover * 1.18, 0))
	self.pulse.Position = base:PointToWorldSpace(V(0.16, 0.48 - cover * 0.29, 0.16))
	local finalPulse = ease(t, 14.76, 15.13)
	self.pulse.Size = V(1.19 - cover * 0.58, 0.54 - cover * 0.30, 1.32 - cover * 0.65) * (1 + finalPulse * 0.36)
	self.light.Brightness = 1.8 + math.sin(t * 5) * 0.22 + finalPulse * 3.1
	for _, v in self.cracks do
		v.p.Transparency = 0.06 + 0.92 * cover * math.clamp(v.r / 2.5, 0, 1)
	end
	for j, layer in self.sediment do
		local u = ease(t, 12.98 + j * 0.15, 13.8 + j * 0.23)
		if u ~= layer.last then
			local m = layer.m
			place(m, if u > 0 then self.crater else self.shelf)
			if u > 0 then
				m:ScaleTo(math.max(0.01, u))
				m:PivotTo(base * CF(layer.lip - V(0, (1 - u) * 0.80, 0)))
			end
			layer.last = u
		end
	end
end

function Strike:draw(t, base, motion)
	local flying = t < flightTime
	place(self.meteor, if flying then self.root else self.shelf)
	place(self.wake, if flying then self.root else self.shelf)
	place(self.cap, if flying then self.root else self.shelf)
	place(self.crater, if flying then self.shelf else self.root)
	local exploding = not flying and t < flightTime + 3.2
	place(self.crown, if exploding then self.root else self.shelf)
	if flying then
		local at = Strike.position(t)
		self.meteor:PivotTo(base * CF(at) * A(0.23 + t * 0.69, 0.55 + t * 0.77, t * 0.39))
		drawWake(self, t, base)
		self.emitted = false
	else
		if exploding then
			drawBlast(self, t, base, motion)
		end
		drawBurial(self, t, base)
	end
end

return Strike
