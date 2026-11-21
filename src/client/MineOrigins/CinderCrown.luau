-- The fire cuts are original curved silhouettes with separate depth, rise and
-- turnover. Use actual triangular geometry so the fire stays sharp up close
-- on published phones that cannot allocate an editable texture.
local P = require(script.Parent.Props)
local Plume = require(script.Parent.Plume)
local Drawings = require(script.Parent.CinderDrawings)
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
local Crown = {}
Crown.__index = Crown

local function ink(parent, kind, mirror)
	local panel = P.model(parent, "Painted " .. kind)
	for i, layer in Drawings[kind] do
		local points, vertices, faces = {}, layer[2], layer[3]
		for j = 1, #vertices, 2 do
			points[#points + 1] = V(vertices[j] * mirror, vertices[j + 1], 0.17 * i)
		end
		for j = 1, #faces, 3 do
			P.face(panel, points[faces[j]], points[faces[j + 1]], points[faces[j + 2]], Color3.fromHex(layer[1]))
		end
	end
	for _, part in panel:GetChildren() do
		part.Material, part.CastShadow = Enum.Material.Neon, false
	end
	return panel
end

local function stroke(parent, a, b, name)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, a, b
	beam.FaceCamera, beam.Segments, beam.LightInfluence, beam.LightEmission = true, 8, 0, 0.78
	beam.Color = ColorSequence.new(Color3.fromHex("FFF3CB"), Color3.fromHex("FFE0A8"))
	beam.Transparency = NumberSequence.new(0.12)
	beam.Parent = parent
	return beam
end

local function pressurePen(parent, tilt, offset, width)
	local root = P.box(parent, "Front of compressed air", Vector3.zero, Vector3.one, "FFFFFF")
	root.Transparency, root.CastShadow = 1, false
	local joints, curves = {}, {}
	for i = 0, 11 do
		local angle = math.rad(-165 + i * 24) + offset
		local a = Instance.new("Attachment")
		a.Name, a.Axis, a.Parent = "Pressure knot", V(-math.sin(angle), 0.03, math.cos(angle)), root
		joints[i + 1] = { point = a, angle = angle }
		if i > 0 then
			curves[i] = stroke(root, joints[i].point, a, "Traveling crescent")
		end
	end
	return { root = root, joints = joints, curves = curves, tilt = tilt, width = width }
end

function Crown.new(parent, parked)
	local self = setmetatable({ root = P.model(parent, "Fire and pressure"), parked = parked, layers = {} }, Crown)
	local templates = {}
	for _, spec in
		{
			-- Profile, flip, start, time leaving the frame, size, center, downwind drift, depth.
			{ "front", 1, 0.075, 0.73, 0.88, V(1, 0.1, -1.4), V(5, 1, -0.2), -3 },
			{ "spray", -1, 0.20, 0.83, 0.36, V(-7, 0.1, -1), V(-21, 1, -2), -4 },
			{ "spray", 1, 0.26, 0.93, 0.39, V(7, 0.1, -1), V(21, 1, -2), -4 },
		}
	do
		local kind, mirror, first, last, size, source, drift, depth = table.unpack(spec)
		local key = kind .. tostring(mirror)
		local model
		if templates[key] then
			model = templates[key]:Clone()
		else
			model = ink(parked, kind, mirror)
			templates[key] = model
		end
		model.Parent = parked
		table.insert(self.layers, {
			model = model,
			kind = kind,
			first = first,
			last = last,
			size = size,
			origin = source,
			drift = drift,
			depth = depth,
			pan = mirror,
		})
	end
	self.volumes = {}
	-- Leading edge is copper and ivory. Downwind spall rises into a tall
	-- cool backlit column after the hot tongue has folded underneath it.
	for _, v in
		{
			{ "melt", 0.05, 0.97, V(0, 1, 2), V(6, 10, -2), 25, 0.46 },
			{ "melt", 0.11, 1.02, V(-2, 0.6, 4), V(-9, 7, 4), 25, -0.3 },
			{ "melt", 0.11, 1.24, V(3, 1, 4), V(14, 13, 1), 28, 0.7 },
			{ "melt", 0.16, 1.21, V(3, 1, 0), V(18, 21, -3), 25, -0.84 },
			{ "melt", 0.19, 1.04, V(-2, 0.7, -2), V(-7, 20, -3), 24, 0.32 },
			{ "ash", 0.24, 2.12, V(-2, 0.5, 1), V(-12, 15, -3), 26, 0.67 },
			{ "ash", 0.27, 2.19, V(4, 0.8, -3), V(21, 25, -9), 33, -0.48 },
			{ "ash", 0.40, 2.13, V(3, 1.8, -7), V(28, 32, -11), 29, 0.29 },
			{ "ash", 0.35, 2.04, V(6, 0.6, 2), V(12, 12, 3), 24, -0.77 },
			{ "ash", 0.39, 1.95, V(-4, 0.5, 4), V(-26, 5.5, 7), 26.5, -0.57 },
			{ "ash", 0.41, 1.98, V(6, 0.7, 5), V(36, 5.9, 6), 29, 0.56 },
		}
	do
		local part = P.box(self.root, "Volcanic convection", Vector3.zero, Vector3.one, "FFFFFF")
		part.Transparency, part.CastShadow = 1, false
		local gui, density = Plume.mount(part, v[1])
		table.insert(self.volumes, { spec = v, part = part, gui = gui, density = density })
	end
	self.fronts = { pressurePen(self.root, 0.14, 0.8, 1.95), pressurePen(self.root, -0.16, -0.7, 1.08) }
	return self
end

function Crown:draw(age, base, motion)
	local camera = workspace.CurrentCamera
	local view = if camera then camera.CFrame.Position else base:PointToWorldSpace(V(-22, 22, 87))
	for _, layer in self.layers do
		local s = age - layer.first
		local life = layer.last - layer.first
		local model = layer.model
		local active = s >= 0 and s < life
		if active then
			local fire = layer.kind == "front"
			local roll = layer.kind == "spray"
			local u = s / life
			local bloom = 1 - math.exp(-(if fire then 9 else 5) * s)
			local fold = if fire then 1 - 0.94 * ease(u, 0.45, 1) else 1 - 0.97 * ease(u, 0.70, 1)
			local size = layer.size * (0.035 + 0.965 * bloom) * fold
			local origin = layer.origin + layer.drift * bloom + V(4 * u, if fire then 7 * u else 2.6 * u, layer.depth)
			local at = base:PointToWorldSpace(origin)
			-- The normal follows the low reaction camera. Smoke rolls in the wind
			-- rather than staying parallel to the flat face of the fiery comb.
			local back = Vector3.new(view.X - at.X, 0, view.Z - at.Z)
			local pose = CFrame.lookAt(at, at - back.Unit)
				* A(0, 0, if fire then -0.15 * bloom else layer.pan * (if roll then 0.04 else -0.23) * u)
			model:ScaleTo(math.max(0.008, size))
			model:PivotTo(pose)
			if model.Parent ~= self.root then
				model.Parent = self.root
			end
		elseif model.Parent ~= self.parked then
			model.Parent = self.parked
		end
	end
	for n, puff in self.volumes do
		local profile = puff.spec
		local kind, first, last, from, drift, diam, spin = table.unpack(profile)
		local s = age - first
		local u = math.clamp(s / (last - first), 0, 1)
		local heat = kind == "melt"
		local swell = 1 - math.exp(-(if heat then 4.9 else 3.95) * math.max(0, s))
		local position = from + drift * swell + V(u * u * (if heat then 2 else 7), u * (if heat then 1 else 4), u * 1.4)
		puff.part.Position = base:PointToWorldSpace(position)
		local span = diam * (0.07 + swell * (if heat then 0.93 else 1.07) + 0.15 * u)
		puff.gui.Size =
			UDim2.fromScale(span * (1 + 0.15 * swell), span * (if n > 9 then 0.47 + 0.14 * u else 1 + 0.05 * u))
		local alpha = ease(u, 0, 0.14) * (1 - ease(u, if heat then 0.50 else 0.50, 1))
		Plume.show(puff.gui, puff.density, n * 53 + u * spin * 41, alpha * (if heat then 0.98 else 0.91))
	end
	for i, p in self.fronts do
		local s = age - (if i == 1 then 0.115 else 0.315)
		local life = if i == 1 then 0.84 else 1.07
		local active = s >= 0 and s < life
		for j, b in p.curves do
			b.Enabled = active
			if active then
				local u = s / life
				local fade = ease(u, 0.49, 1)
				b.Transparency = NumberSequence.new(0.06 + 0.94 * fade)
				local function width(k)
					return p.width
						* (if motion then 1 else 0.6)
						* (1 + 0.65 * u)
						* math.max(0.016, math.sin(k * math.pi / 11)) ^ 1.3
				end
				b.Width0, b.Width1 = width(j - 1), width(j)
			end
		end
		if active then
			local u = s / life
			local r = 2 + 79 * (1 - (1 - u) ^ 1.2)
			local turn = A(0, if i == 1 then -0.24 else 0.53, p.tilt)
			p.root.CFrame = base * CF(3, 3.6 + 12 * u, 0) * turn
			for _, k in p.joints do
				k.point.Position = V(r * math.cos(k.angle), 3.3 * u * math.sin(k.angle), r * math.sin(k.angle) * 0.77)
				k.point.Axis = V(-math.sin(k.angle), 0, 0.77 * math.cos(k.angle)).Unit
			end
			for _, b in p.curves do
				b.CurveSize0, b.CurveSize1 = r * 0.14, r * 0.14
			end
		end
	end
end
return Crown
