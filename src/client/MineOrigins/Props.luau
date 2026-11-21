local Props = {}
local V, rgb = Vector3.new, Color3.fromHex
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name, m.WorldPivot, m.Parent = name, CFrame.identity, parent
	return m
end
local function part(parent, name, size, cf, color, class)
	local p = Instance.new(class or "Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return p
end
local function orb(parent, name, at, size, color)
	local p = part(parent, name, size, CFrame.new(at), color)
	p.Shape = Enum.PartType.Ball
	return p
end
local function rod(parent, name, a, b, width, color)
	return part(parent, name, V(width, width, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
end
-- Split a triangular face along the altitude to its longest side.
local function face(parent, a, b, c, color)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	local height = math.abs(ab:Dot(up))
	for i, vertex in { b, c } do
		local sign = if i == 1 then 1 else -1
		local depth = math.abs((vertex - a):Dot(along))
		if depth > 0.01 and height > 0.01 then
			part(
				parent,
				"Facet",
				V(0.025, height, depth),
				CFrame.fromMatrix((a + vertex) / 2, normal * sign, up, along * sign),
				color,
				"WedgePart"
			)
		end
	end
end

-- The pale gold edge and lavender fracture recur in orbit, in the lamp and
-- in the drill sample. These are asymmetric splinters, with a broken base.
local function crystal(parent, at, size)
	local m = model(parent, "Star heart")
	local top, foot = V(0.23, 1.4, -0.06) * size, V(-0.17, -0.86, 0.04) * size
	local waist = {
		V(-0.51, -0.19, 0),
		V(-0.13, 0.02, 0.41),
		V(0.42, -0.18, 0.17),
		V(0.36, -0.22, -0.26),
		V(-0.18, -0.31, -0.33),
	}
	local hues = { "FFE9B6", "F2D4FF", "BC8FE4", "6E588F", "AD8DC7" }
	for i, v in waist do
		local w = waist[i % #waist + 1] * size
		local color = rgb(hues[i])
		face(m, top, v * size, w, color)
		face(m, foot, w, v * size, color:Lerp(rgb("5F487E"), 0.44))
	end
	-- Splitting planes through the crystal catch a different color as it turns.
	local fracture = {
		V(-0.38, -0.16, 0.19),
		V(-0.13, 0.02, 0.43),
		V(0.032, 0.34, 0.302),
		V(0.14, 0.47, 0.232),
		V(0.17, 0.92, 0.104),
	}
	for i = 2, #fracture do
		local seam = rod(
			m,
			"Bright fracture",
			fracture[i - 1] * size,
			fracture[i] * size,
			math.max(0.025, 0.027 * size),
			rgb("FFF2CD")
		)
		seam.Material = Enum.Material.Neon
	end
	m:PivotTo(CFrame.new(at))
	return m
end

local function cylinder(parent, name, pos, radius, height, tint, mat)
	local p = part(
		parent,
		name,
		V(height, radius * 2, radius * 2),
		CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
		rgb(tint)
	)
	p.Shape, p.Material = Enum.PartType.Cylinder, mat or Enum.Material.SmoothPlastic
	return p
end
local function box(parent, name, pos, size, tint, rot, mat)
	local p = part(parent, name, size, CFrame.new(pos) * (rot or CFrame.identity), rgb(tint))
	p.Material = mat or Enum.Material.SmoothPlastic
	return p
end
local function sphere(parent, name, pos, size, tint, mat)
	local p = orb(parent, name, pos, size, rgb(tint))
	p.Material = mat or Enum.Material.SmoothPlastic
	return p
end
local function light(parent, tint, distance, intensity)
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Range, lamp.Brightness, lamp.Parent = rgb(tint), distance, intensity, parent
	return lamp
end
local function ease(t, start, finish)
	local u = math.clamp((t - start) / (finish - start), 0, 1)
	return u * u * (3 - 2 * u)
end
Props.model, Props.part, Props.face, Props.rod = model, part, face, rod
Props.box, Props.sphere, Props.cylinder, Props.crystal, Props.light, Props.ease =
	box, sphere, cylinder, crystal, light, ease
return Props
