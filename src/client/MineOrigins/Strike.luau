local P = require(script.Parent.Props)
local Plume = require(script.Parent.Plume)
local Burial = require(script.Parent.Burial)
local Descent = require(script.Parent.Descent)
local Jets = require(script.Parent.EjectaJets)
local Crater = require(script.Parent.Crater)
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

-- Follow the seven peaks north of today's cableway, at their younger heights.
-- All faces share the same vertices, including the far side visible during the dive.
local function buildHeadlands(shore)
	local peaks = {
		V(-246, -9, -90),
		V(-201, 16, -111),
		V(-157, 23, -167),
		V(-79, 24, -154),
		V(-39, 22, -185),
		V(53, 29, -173),
		V(113, 24, -157),
		V(201, 16, -99),
		V(252, -9, -73),
	}
	local crest = { peaks[1] }
	for i = 2, #peaks do
		local previous, peak = peaks[i - 1], peaks[i]
		local saddle = previous:Lerp(peak, if i % 2 == 0 then 0.39 else 0.64)
		table.insert(crest, saddle - V(0, math.max(0, saddle.Y + 9) * 0.37, 3))
		table.insert(crest, peak)
	end
	local last
	for i, top in crest do
		local section = {
			V(top.X, -12, top.Z + 34),
			V(top.X + 2 * math.sin(i), (top.Y + 9) * 0.44 - 9, top.Z + 15 + 3 * math.cos(i)),
			top,
			V(top.X, -12, top.Z - 31),
		}
		if last then
			for j, hue in { "827A7F", "93868A", "797986" } do
				local color = rgb(hue):Lerp(rgb("9C8E95"), 0.12 * (i % 3))
				P.face(shore, last[j], section[j], section[j + 1], color)
				P.face(shore, last[j], section[j + 1], last[j + 1], color)
			end
		end
		last = section
	end
end

local function buildCoast(root, rng)
	-- The impact falls below the back of today's gallery. The lagoon and
	-- smaller landing island lie to its south (+Z), just as they do at spawn.
	local shore = P.model(root, "Ancient mine headland")
	buildHeadlands(shore)
	-- Tile to the atmospheric horizon so the opening orbit cannot see the
	-- outside corners of the ocean below the rock.
	for east = -2, 2 do
		for south = -2, 2 do
			local sea = P.box(shore, "Open ocean", V(east * 1900, -8.6, south * 1900), V(1900, 1, 1900), "31586F")
			sea.Reflectance = 0.09
		end
	end
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
	local n, inner, mid, rim, foot = 32, {}, {}, {}, {}
	for i = 1, n do
		local a = tau * i / n
		local x, z = math.cos(a), math.sin(a)
		local jag = rng:NextNumber(0.86, 1.08)
		inner[i] = V(x * 34, 1.15 + 0.67 * math.sin(3 * a), z * 29)
		mid[i] = V(x * 49, 1.64 + math.sin(a * 3) * 1.61, z * 41)
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
		local r = rng:NextNumber(36, 57)
		local s = rng:NextNumber(0.32, 1.65)
		local p =
			ball(shore, "Lava boulder", V(math.cos(a) * r, 0.3, math.sin(a) * r), V(1.8, 1, 1.3) * s, "77636A", stone)
		p.CFrame *= A(0.2, a, -0.16)
	end
	-- The lowest clouds frame the real descent corridor. A gap around the
	-- centerline keeps the meteor visible to the camera traveling alongside it.
	for i = 1, 17 do
		local time = rng:NextNumber(0.9, 5.9)
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

local sculptures = script.Parent.ImpactSculptures

local function sculpt(parent, asset, name, scale)
	local model = sculptures[asset]:Clone()
	model.Name = name
	if scale then
		model:ScaleTo(scale)
	end
	model.Parent = parent
	return model
end

local sliverOffset = CF(0.62, 0.52, 2.66) * A(-0.19, 0.21, -0.78)
local function meteorPose(t)
	return CF(Strike.position(t)) * A(0.36 + t * 0.46, 0.72 + t * 0.71, t * 0.40)
end

local separation = meteorPose(flightTime) * sliverOffset
function Strike.corePosition(t)
	if t <= flightTime then
		return (meteorPose(t) * sliverOffset).Position
	end
	return Burial.point(t)
		+ (separation.Position - Burial.point(flightTime)) * (1 - ease(t, flightTime, flightTime + 0.47))
end

function Strike.frame(t, motion)
	return Descent.frame(t, motion, Strike.position)
end
Strike.surfaceFrame = Descent.surface

local function buildMeteor(root)
	local body = sculpt(root, "Fluted iron", "Starfall meteor")
	local core = P.crystal(body, Vector3.zero, 1.57)
	core.Name = "Starfall core"
	-- A violet cleft rings the same asymmetric crystal before and after breakup.
	for i, p in core:GetChildren() do
		if p.Name == "Facet" then
			p.Color = p.Color:Lerp(rgb("9859DF"), 0.30)
			if i % 8 == 1 or i % 8 == 2 then
				p.Material = neon
				p.Color = rgb("BC8AEA")
			end
		end
	end
	for i, off in { V(-0.57, -0.64, 0.05), V(0.50, -0.8, -0.11) } do
		local rind = sculpt(core, "Spall", "Fused meteoritic iron", 0.43 + 0.05 * i)
		rind:PivotTo(CF(off) * A(0.44 * i, -i, 0.28))
	end
	core:PivotTo(sliverOffset)
	P.light(body.PrimaryPart, "FFAB76", 42, 2.75)
	return body, core
end

local function knot(parent, position, tangent)
	local a = Instance.new("Attachment")
	a.Position, a.Axis = position, tangent.Unit
	a.Parent = parent
	return a
end

local function beam(parent, from, to, width, tip, color, alpha)
	local b = Instance.new("Beam")
	b.FaceCamera, b.Segments = true, 10
	b.Attachment0, b.Attachment1 = from, to
	b.Width0, b.Width1, b.Color, b.Transparency = width, tip, color, alpha
	b.Parent = parent
	return b
end

local function gradient(a, b, c, breakpoint)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(a)),
		ColorSequenceKeypoint.new(breakpoint or 0.42, rgb(b)),
		ColorSequenceKeypoint.new(1, rgb(c)),
	})
end

local function buildWake(self)
	local wake = P.model(self.root, "Plasma wake")
	self.wake = wake
	local anchor = marker(wake, "Ablation streamlines", Vector3.zero)
	self.wakeAnchor = anchor
	local flame = gradient("FFAD6F", "E58458", "A57891")
	local fading = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.4, 0.20),
		NumberSequenceKeypoint.new(1, 1),
	})
	self.streams = {}
	for i = 1, 9 do
		-- Each spline leaves the flank of the body and tears off into the slipstream.
		-- An opaque narrow streak travels inside its translucent, much broader envelope.
		local a = tau * i / 9
		local rim = V(math.cos(a), math.sin(a), 0)
		local near = knot(anchor, rim * 2.3 + V(0, 0, 0.75), (rim * 0.62 - V(0, 0, 1)).Unit)
		local tip = knot(anchor, V(0, 0, -20), -Vector3.zAxis)
		local plume = beam(anchor, near, tip, 1.9 + i % 3 * 0.48, 0.18, flame, fading)
		plume.Texture, plume.TextureMode = "rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch
		plume.CurveSize0, plume.LightEmission, plume.LightInfluence = 6.8, 0.48, 0.08
		local spine = beam(
			anchor,
			near,
			tip,
			0.10 + i % 3 * 0.075,
			0.02,
			gradient("FFF3C9", "F4BA76", "D88C9B", 0.56),
			NumberSequence.new(0.34, 1)
		)
		spine.CurveSize0, spine.LightEmission, spine.LightInfluence = plume.CurveSize0, 0.94, 0
		self.streams[i] = { theta = a, tip = tip, outer = plume, inner = spine }
	end
	local haze, tip = ribbon(
		anchor,
		V(0, 0, -1),
		V(0, 3, -48),
		7.8,
		0.8,
		gradient("F9CAA4", "C3909C", "9789A1"),
		NumberSequence.new(0.19, 1)
	)
	haze.LightEmission, haze.TextureSpeed, haze.CurveSize0, haze.CurveSize1 = 0.40, -0.18, 13, 7
	haze.Attachment0.Axis, haze.Attachment1.Axis = V(0.14, 0.08, -1).Unit, V(-0.2, 0.1, -1).Unit
	self.wakeEnd = tip

	-- A thin band of compressed air bends around the windward cheek of the stone.
	for i = 1, 7 do
		local a, b = tau * (i - 1) / 7, tau * i / 7
		local u, v = V(math.cos(a), math.sin(a), 0), V(math.cos(b), math.sin(b), 0)
		local start = knot(anchor, u * 2.72 + V(0, 0, 1.05), V(-u.Y, u.X, 0.12).Unit)
		local finish = knot(anchor, v * 2.72 + V(0, 0, 1.05), V(-v.Y, v.X, -0.08).Unit)
		local bow = beam(
			anchor,
			start,
			finish,
			0.10,
			0.045,
			gradient("FFC785", "FFBA76", "F0919B"),
			NumberSequence.new(0.08, 0.40)
		)
		bow.CurveSize0, bow.CurveSize1, bow.LightEmission = 0.46, 0.46, 0.94
	end
	self.fire = {}
	for i = 1, 6 do
		local mark = marker(wake, "Sheared copper vapor", Vector3.zero)
		local gui, density = Plume.mount(mark, "melt")
		self.fire[i] = { mark = mark, gui = gui, density = density }
	end
	self.smoke = {}
	for i = 1, 10 do
		local mark = marker(wake, "Ablated dust", Vector3.zero)
		local gui, img = sprite(mark, "Fine ash", "smoke_main.dds", 1.35)
		img.ImageColor3 = rgb(if i % 3 == 0 then "D2A39F" else "B49AA2")
		self.smoke[i] = { mark = mark, gui = gui, img = img }
	end
	self.sparks = {}
	for i = 1, 14 do
		self.sparks[i] = ellipse(wake, "Fusion spark", if i % 5 == 0 then "CBB4F3" else "FFCB83", neon)
	end
end

local function drawWake(self, t, base)
	local head = Strike.position(t)
	local reverse = (Strike.position(t - 0.04) - head).Unit
	local side = reverse:Cross(Vector3.yAxis).Unit
	local up = side:Cross(reverse).Unit
	local length = math.clamp((Strike.position(t - 0.85) - head).Magnitude * 1.51, 27, 73)
	self.wakeAnchor.CFrame = base * CFrame.lookAt(head, head + reverse)
	self.wakeEnd.Position = V(1 + 1.5 * math.cos(t * 1.5), 3.8, -length)
	for i, s in self.streams do
		local phi = s.theta + 0.49 * math.sin(t * 2.2 + i)
		local span = length * (0.34 + 0.17 * math.sin(i * 2.2) + 0.09 * math.sin(t * 3 + i))
		local radius = 1.0 + 0.88 * math.cos(i * 2 + t * 1.8)
		s.tip.Position = V(math.cos(phi) * radius, math.sin(phi) * radius + 0.7, -span)
		s.tip.Axis = V(0.3 * math.sin(phi + 0.84), 0.3 * math.cos(phi), -1).Unit
		s.inner.CurveSize1 = span * 0.24
		s.outer.CurveSize1 = span * 0.24
	end
	for i, k in self.fire do
		local u = ((i - 1) / #self.fire + t * 0.62) % 1
		local phi = i * 2.39 + t * 2.24
		local slip = (side * math.cos(phi) + up * math.sin(phi)) * (0.38 + 1.10 * u)
		k.mark.Position = base:PointToWorldSpace(head + reverse * (1.4 + u * length * 0.51) + slip + up * u * u)
		local size = 8.7 - 4.0 * u
		k.gui.Size = UDim2.fromScale(size * 1.31, size)
		Plume.show(k.gui, k.density, i * 67 + t * 24, 0.96 * ease(u, -0.055, 0.12) * (1 - ease(u, 0.56, 1)))
	end
	for i, s in self.smoke do
		local u = ((i - 1) / #self.smoke + t * 0.34) % 1
		local slip = (side * math.sin(i * 2.1 + t) + up * math.cos(i * 2.1 + t)) * (0.32 + 2.0 * u)
		s.mark.Position =
			base:PointToWorldSpace(head + reverse * (3 + length * (0.13 + 0.89 * u)) + slip + up * u * u * 4.2)
		local size = 4.1 + u * 3.6
		s.gui.Size = UDim2.fromScale(1.3 * size, size)
		s.img.ImageTransparency = 1 - 0.65 * ease(u, 0, 0.16) * (1 - ease(u, 0.44, 1))
		s.img.Rotation = i * 42 + t * (if i % 2 == 0 then 24 else -22)
	end
	for i, p in self.sparks do
		local u = (t * (0.73 + i % 3 * 0.14) + i * 0.618) % 1
		local a = i * 2.399
		local outward = (side * math.cos(a) + up * math.sin(a)) * (2.25 + u * (3 + i % 5))
		local pos = head + reverse * (1 + u * length * 0.8) + outward
		local w = 0.09 + (1 - u) * 0.18
		between(p, base, pos, pos + reverse * (1.45 + u * 3.4), w, w)
		p.Transparency = 0.07 + 0.93 * u * u
	end
end

local function craterBed(self, rng)
	self.crater = P.model(self.root, "Buried Starfall")
	self.bed = Crater.new(self.root)
	self.rimRocks = {}
	for i = 1, 17 do
		local angle = i * 2.399
		local rock = sculpt(
			self.bed.root,
			if i % 3 == 0 then "Slag blade" else "Spall",
			"Torn crater lip",
			rng:NextNumber(0.82, 1.7)
		)
		local p = Crater.ground(0.80, angle) + V(0, 2.05, 0)
		table.insert(self.rimRocks, { rock = rock, point = p, angle = angle, delay = 0.24 + 0.024 * (i % 5) })
	end
	local trace = marker(self.crater, "Core and pressure glow", Vector3.zero)
	self.core = trace
	self.light = P.light(trace, "BF94FF", 18, 1)
	self.tailEnds = {}
	for j = 1, 3 do
		local a, b = knot(trace, Vector3.zero, Vector3.yAxis), knot(trace, Vector3.yAxis * 0.2, Vector3.yAxis)
		local ribbon = beam(
			trace,
			a,
			b,
			if j == 1 then 0.70 else 0.27,
			0.03,
			gradient("F9DFFF", "B379F0", "79679C"),
			NumberSequence.new(if j == 1 then 0.23 else 0.18, 0.95)
		)
		ribbon.LightEmission, ribbon.LightInfluence = 0.87, 0
		table.insert(self.tailEnds, { a = a, b = b, beam = ribbon })
	end
	self.fill = marker(self.crater, "Reflected light in the section", Vector3.zero)
	self.fillLight = P.light(self.fill, "EBD3C6", 74, 1.47)
	self.section = Burial.new(self.shelf)
end

local function buildImpact(self, rng)
	craterBed(self, rng)
	local crown = P.model(self.root, "Impact crown")
	self.crown = crown
	self.fault = sculpt(crown, "Contact fault", "Impact contact", 1)
	self.flash = marker(crown, "Contact heat", Vector3.zero)
	self.corona, self.coronaImage = sprite(self.flash, "Air lit by the contact", "explosion01_implosion_main.dds", 1.7)
	self.coronaImage.ImageColor3 = rgb("FFD492")
	self.impactLight = P.light(self.flash, "FFD799", 98, 8.5)

	self.jets = Jets.new(crown)

	local origin = marker(crown, "Traveling pressure fronts", Vector3.zero)
	self.fronts = {}
	for p = 1, 2 do
		local joints, edges = {}, {}
		local n = 28
		for i = 1, n do
			local a = tau * (i - 1) / n
			local dir = V(math.cos(a), 0, math.sin(a))
			joints[i] = { a = knot(origin, Vector3.zero, V(-dir.Z, 0, dir.X)), dir = dir }
		end
		for i, joint in joints do
			local edge = beam(
				origin,
				joint.a,
				joints[i % n + 1].a,
				1.4,
				0.9,
				if p == 1 then gradient("FFF3CE", "FAD6A0", "E9B484") else gradient("CA9B8B", "BC9DA1", "998C9A"),
				NumberSequence.new(0.32)
			)
			edge.Texture, edge.TextureMode = "rbxasset://textures/particles/smoke_main.dds", Enum.TextureMode.Stretch
			edge.LightEmission, edge.LightInfluence = if p == 1 then 0.68 else 0.13, 0.16
			edges[i] = edge
		end
		self.fronts[p] = { joints = joints, edges = edges, fade = -1 }
	end

	self.dust = {}
	for i = 1, 20 do
		local a = tau * ((i - 1) / 20) + 0.09 * math.sin(i * 2.3)
		local d = V(math.cos(a), 0, math.sin(a))
		local mark = marker(crown, "Rolling curtain of dust", Vector3.zero)
		local gui, img = sprite(mark, "Windblown silt", "smoke_main.dds", 1)
		img.ImageColor3 = rgb(({ "D8B49C", "BB9590", "B2A0A1", "DAC3A6" })[i % 4 + 1])
		self.dust[i] = {
			mark = mark,
			gui = gui,
			img = img,
			dir = d,
			delay = (i % 4) * 0.043 + 0.065,
			size = rng:NextNumber(9.2, 14.6),
			speed = rng:NextNumber(11, 20),
		}
	end
	-- Fine material and coarse material separate in flight. Warm silt rises on
	-- the same inclined paths as the sheets and curls downwind after they fall.
	self.ash = {}
	for i = 1, 18 do
		local az = if i % 3 == 0 then (i % 5) * 1.23 else 0.53 + 1.95 * math.sin(i * 2.399)
		local dir = V(math.sin(az), 0, math.cos(az))
		local mark = marker(crown, "Airborne scoria", Vector3.zero)
		local gui, img = sprite(mark, "Torn ash cloud", "smoke_main.dds", 1.4)
		self.ash[i] = {
			mark = mark,
			gui = gui,
			img = img,
			dir = dir,
			delay = 0.055 + (i % 6) * 0.056,
			rise = 5.2 + (i % 5) * 1.65,
			span = 1 + (i % 4) * 1.1,
			size = 6.1 + (i % 5) * 1.3,
			warm = rgb(({ "FFD9A2", "EAB476", "FFAA70", "FFD484" })[i % 4 + 1]),
			cool = rgb(({ "8C8188", "A29591", "7F7783", "937E81" })[i % 4 + 1]),
		}
	end
	self.bloom = {}
	for i, profile in
		{
			{ "melt", 0, 0, 0, 2.3, 13.8, 0.25 },
			{ "melt", 3.4, -0.5, 0.035, 5.7, 17.1, 0.72 },
			{ "melt", 6.5, -2.6, 0.10, 9.7, 13.6, 0.75 },
			{ "melt", -3.1, 1.4, 0.09, 4.2, 9.8, -0.51 },
			{ "ash", -4.2, -1.4, 0.09, 7.6, 12.1, -0.84 },
			{ "ash", 2.5, -2.9, 0.17, 15.0, 16.9, 0.57 },
			{ "ash", 7.1, -0.9, 0.29, 18.8, 13.3, 0.85 },
		}
	do
		local mark = marker(crown, "Boiling ejecta", Vector3.zero)
		local gui, density = Plume.mount(mark, profile[1])
		self.bloom[i] = { mark = mark, gui = gui, density = density, profile = profile }
	end
	self.ejecta = {}
	for i = 1, 19 do
		local s = rng:NextNumber(0.40, 1.39)
		local a = i * 2.399
		local v = V(
			math.cos(a) * rng:NextNumber(12, 39) + 6.2,
			rng:NextNumber(16, 38),
			math.sin(a) * rng:NextNumber(11, 29) + 4
		)
		local rock = sculpt(crown, if i % 3 == 0 then "Slag blade" else "Spall", "Spalled rock", s)
		local tail, tip = ribbon(
			rock.PrimaryPart,
			Vector3.zero,
			V(1, -3, 0),
			0.41 + s * 0.35,
			0.06,
			gradient("FFC78B", "D7A480", "A89698"),
			NumberSequence.new(0.17, 1)
		)
		tail.LightEmission, tail.LightInfluence = 0.58, 0.12
		self.ejecta[i] = { rock = rock, tail = tail, tip = tip, v = v, scale = s, delay = 0.04 + (i % 5) * 0.045 }
	end
end

function Strike.new(shelf)
	local root = P.model(shelf, "Primordial cove")
	local self = setmetatable({ root = root, shelf = shelf }, Strike)
	local rng = Random.new(58237)
	self.shore = buildCoast(root, rng)
	self.meteor, self.shard = buildMeteor(root)
	buildWake(self)
	buildImpact(self, rng)
	return self
end

local function pressure(self, age, motion)
	for i, f in self.fronts do
		local s = math.max(0, age - (if i == 1 then 0.065 else 0.25))
		local r = 2.8 + (if i == 1 then 88 else 47) * s
		local opacity = (if i == 1 then 0.73 else 0.42) * ease(s, 0, 0.095) * (1 - ease(s, 0.49, 1.48))
		if not motion then
			opacity *= 0.57
		end
		local fade = math.round((1 - opacity) * 30) / 30
		if fade ~= f.fade then
			f.fade = fade
			local alpha = NumberSequence.new(fade)
			for _, edge in f.edges do
				edge.Transparency = alpha
				edge.Enabled = fade < 1
			end
		end
		if opacity > 0.01 then
			for j, joint in f.joints do
				local radial = r * (1 + 0.033 * math.sin(j * 1.83))
				local edge = f.edges[j]
				joint.a.Position = joint.dir * radial + V(0, 0.63 + 0.35 * i + 0.25 * math.sin(j * 1.75) + s * 0.55, 0)
				local w = (if i == 1 then 0.59 else 1.55) * (1 + 0.7 * s)
				edge.Width0, edge.Width1 = w * (1 + 0.2 * math.sin(j * 2)), w * (1 + 0.2 * math.sin((j + 1) * 2))
				edge.CurveSize0, edge.CurveSize1 = r * 0.061, r * 0.061
			end
		end
	end
end

local function drawBlast(self, t, base, motion)
	local age = t - flightTime
	self.fault:PivotTo(base * CF(1, 0.26 - 0.8 * ease(age, 0.10, 0.42), 0.7) * A(0, -0.64, 0))
	place(self.fault, if age < 0.25 then self.crown else self.shelf)
	local flash = ease(age, 0, 0.20)
	self.corona.Enabled = age < 0.24
	self.corona.Size = UDim2.fromScale(10 + 42 * flash, 7 + 22 * flash)
	self.flash.CFrame = base * CF(1.4, 1.05, 0.9) * A(0, -0.44, 0.06)
	self.coronaImage.ImageTransparency = 0.12 + 0.88 * ease(age, 0.035, 0.23)
	self.impactLight.Brightness = (if motion then 8 else 3.1) * (1 - ease(age, 0.035, 0.32))
	self.jets:draw(age)
	pressure(self, age, motion)
	for i, dust in self.dust do
		local s = math.max(0, age - dust.delay)
		local front = 1 - math.exp(-1.75 * s)
		local rad = 2.3 + front * dust.speed + s * 1.2
		local up = 0.46 + front * (1.15 + i % 3 * 0.35) + s * s * 0.29
		dust.mark.Position = base:PointToWorldSpace(dust.dir * rad + V(1.3 * front, up, 1.7 * front))
		local size = dust.size * (0.14 + 0.86 * front + 0.15 * s)
		dust.gui.Size = UDim2.fromScale(size * 1.55, size * (0.38 + 0.18 * front))
		dust.img.Rotation = 9 * math.sin(i * 3.3) + s * (if i % 2 == 0 then 6 else -6)
		dust.img.ImageTransparency = 1 - 0.77 * ease(s, 0, 0.39) * (1 - ease(s, 1.0, 2.68))
	end
	for i, cloud in self.ash do
		local s = math.max(0, age - cloud.delay)
		local swell = 1 - math.exp(-3.6 * s)
		local rad = 0.6 + cloud.span * swell + 3 * s
		local h = cloud.rise * swell + 1.18 * s
		cloud.mark.Position = base:PointToWorldSpace(cloud.dir * rad + V(1.50 * s, h, 1.24 * s))
		local size = cloud.size * (0.18 + 0.82 * swell + 0.4 * s)
		cloud.gui.Size = UDim2.fromScale(size * 1.16, size * (0.86 + 0.32 * swell))
		cloud.img.Rotation = i * 67 + s * (if i % 2 == 0 then -14 else 13)
		local cold = ease(s, 0.21, 1.03)
		cloud.img.ImageColor3 = cloud.warm:Lerp(cloud.cool, cold)
		cloud.img.ImageTransparency = 1 - 0.90 * ease(s, 0, 0.26) * (1 - ease(s, 0.97 + (i % 4) * 0.06, 2.2))
	end
	for i, cloud in self.bloom do
		local b = cloud.profile
		local s = math.max(0, age - b[4])
		local rise = 1 - math.exp(-4.1 * s)
		local cooling = b[1] == "ash"
		local h = 0.72 + b[5] * rise + s * (if cooling then 1.7 else 0.4)
		local offset = V(b[2] * (1 + rise) + b[7] * s * 2.1, h, b[3] * (1 + rise))
		cloud.mark.Position = base:PointToWorldSpace(offset)
		local span = b[6] * (0.10 + 0.90 * rise + s * 0.37)
		cloud.gui.Size = UDim2.fromScale(span * (1.15 + 0.22 * rise), span * (1.21 - 0.22 * rise))
		local opacity = (if cooling then 0.85 else 0.98)
			* ease(s, 0, 0.24)
			* (1 - ease(s, if cooling then 0.68 else 0.42, if cooling then 1.55 else 0.99))
		Plume.show(cloud.gui, cloud.density, b[7] * 21 + s * (if i % 2 == 0 then -8 else 7), opacity)
	end
	for i, e in self.ejecta do
		local s = age - e.delay
		local function point(h)
			return e.v * h - V(0, 13.2 * h * h, 0)
		end
		local p = point(math.max(0, s))
		local visible = s >= 0 and p.Y > 0
		place(e.rock, if visible then self.crown else self.shelf)
		if visible then
			local cf = CF(p) * A(s * (2.3 + i % 3), i + s * 2.8, s * 1.6)
			e.rock:PivotTo(base * cf)
			e.tip.Position = cf:PointToObjectSpace(point(math.max(0, s - 0.17)))
			e.tail.Enabled = s < 1.4
		end
	end
end

local function penetration(self, t, base, section)
	local p = Strike.corePosition(t)
	local plunge = ease(t, 6.5, 7.25)
	local spin = separation.Rotation:Lerp(A(0.14, -0.24, 2.88) * A(0, 0.66 * math.sin(t * 1.7), 0), plunge)
	-- The visible shard is the inset from the meteor. It is never replaced by
	-- a second prop standing on the lip after contact.
	local scale = 1 + 0.48 * ease(t, 7.22, 7.91)
	if self.shardScale ~= scale then
		self.shard:ScaleTo(scale)
		self.shardScale = scale
	end
	self.shard:PivotTo(base * CF(p) * spin)
	self.core.Position = base:PointToWorldSpace(p)
	self.light.Brightness = (0.91 + 0.18 * math.sin(t * 9)) * (1 - ease(t, 11.23, 11.93))
	for j, item in self.tailEnds do
		local live = t > 6.525 and t < 11.0
		item.beam.Enabled = live
		if live then
			local old = Strike.corePosition(math.max(6.5, t - (0.12 + j * 0.042))) - p
			local width = if j == 1 then 0 else (j - 2.5) * 1.2
			item.a.Position = V(width * 0.39, 0.32, 0)
			item.b.Position = old + V(width, 0, 0.05)
			item.a.Axis = if old.Magnitude > 0.02 then old.Unit else Vector3.yAxis
			item.b.Axis = item.a.Axis
		end
	end
	self.fillLight.Enabled = section
	if section then
		self.fill.Position = base:PointToWorldSpace(p + V(-12, 11, 18))
		self.fillLight.Color = rgb("F3C8A0"):Lerp(rgb("BDCCE1"), ease(t, 8.7, 10.5))
		self.section:draw(t, base)
	end
end

function Strike:draw(t, base, motion)
	local flying = t < flightTime
	local section = t >= 7.58
	place(self.shore, if section then self.shelf else self.root)
	self.section:prepare(if section then math.huge else 1)
	if section and not self.mountedSection then
		self.section.root:PivotTo(base)
		self.mountedSection = true
	end
	place(self.section.root, if section then self.root else self.shelf)
	place(self.bed.root, if section then self.shelf else self.root)
	if not section then
		self.bed:draw(t - flightTime, base)
		for _, v in self.rimRocks do
			local rise = ease(t - flightTime, v.delay, v.delay + 0.43)
			if rise ~= v.last then
				v.last = rise
				place(v.rock, if rise > 0 then self.bed.root else self.shelf)
				if rise > 0 then
					v.rock:PivotTo(
						base
							* CF(v.point + V(0, -3.4 * (1 - rise), 0))
							* A(0.16 * math.sin(v.angle), -v.angle, 0.32 + 1.1 * (1 - rise))
					)
				end
			end
		end
	end
	place(self.crater, if flying then self.shelf else self.root)
	local exploding = not flying and t < 8.67
	place(self.crown, if exploding then self.root else self.shelf)
	place(self.wake, if flying then self.root else self.shelf)
	if flying then
		place(self.meteor, self.root)
		place(self.shard, self.meteor)
		self.meteor:PivotTo(base * meteorPose(t))
		self.shard:PivotTo(base * meteorPose(t) * sliverOffset)
		drawWake(self, t, base)
	else
		place(self.shard, self.crater)
		place(self.meteor, self.shelf)
		if exploding then
			drawBlast(self, t, base, motion)
		end
		penetration(self, t, base, section)
	end
end

return Strike
