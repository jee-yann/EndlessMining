local P = require(script.Parent.Props)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Actor = {}
Actor.__index = Actor

-- The hands and boots stay on the prop or floor as the shoulders and knees move.
local function joint(a, b, bend, length)
	local d = b - a
	local along = d.Unit
	local outward = bend - along * along:Dot(bend)
	if outward.Magnitude < 0.001 then
		outward = Vector3.xAxis
	end
	return (a + b) / 2 + outward.Unit * math.sqrt(math.max(0.012, length ^ 2 - d.Magnitude ^ 2 * 0.25))
end
local function segment(part, a, b)
	part.Size = V(part.Size.X, part.Size.Y, (a - b).Magnitude + 0.06)
	part.CFrame = CFrame.lookAt((a + b) / 2, b)
end
function Actor.new(parent, name, coat, skin, hat)
	local root = P.model(parent, name)
	local torso = P.model(root, "Oilskin coat")
	P.box(torso, "Jacket", V(0, 0, 0), V(1.35, 1.12, 0.74), coat)
	for _, s in { -1, 1 } do
		P.box(torso, "Lapel", V(s * 0.24, 0.30, 0.39), V(0.25, 0.46, 0.09), "ECDDB7", A(0, 0, -s * 0.36))
	end
	for i = 1, 3 do
		P.sphere(torso, "Brass button", V(0, 0.16 - i * 0.20, 0.408), V(0.105, 0.105, 0.07), "F6C76E")
	end
	P.box(torso, "Leather belt", V(0, -0.45, 0), V(1.38, 0.14, 0.77), "534237")
	local head = P.model(root, "Face")
	P.box(head, "Cheeks", V(0, 0.02, 0), V(1.00, 0.92, 0.85), skin)
	P.box(head, "Hair", V(0, 0.35, -0.04), V(1.06, 0.31, 0.9), "4D3834")
	for _, s in { -1, 1 } do
		P.sphere(head, "Ear", V(s * 0.51, 0, 0), V(0.17, 0.27, 0.17), skin)
		P.sphere(head, "Eye", V(s * 0.205, 0.08, 0.44), V(0.079, 0.112, 0.05), "292831")
		P.box(head, "Brow", V(s * 0.20, 0.20, 0.443), V(0.19, 0.047, 0.045), "47352F", A(0, 0, -s * 0.11))
	end
	P.box(head, "Nose", V(0, -0.05, 0.46), V(0.16, 0.15, 0.14), skin)
	P.box(head, "Mouth", V(0.02, -0.22, 0.44), V(0.24, 0.043, 0.035), "865647", A(0, 0, 0.09))
	P.cylinder(head, "Brim", V(0, 0.42, 0.045), 0.68, 0.085, hat)
	P.cylinder(head, "Crown", V(0, 0.55, -0.02), 0.49, 0.25, hat)
	P.cylinder(head, "Hat band", V(0, 0.47, -0.02), 0.5, 0.09, "453D42")
	local self = setmetatable({ model = root, torso = torso, head = head, limbs = {} }, Actor)
	for i, s in { -1, 1 } do
		local function limb(n, w, c)
			return P.box(root, n, Vector3.zero, V(w, w, 0.55), c)
		end
		self.limbs[i] = {
			s = s,
			sleeve = limb("Coat sleeve", 0.44, coat),
			cuff = limb("Rolled sleeve", 0.36, "D9C9A6"),
			hand = P.sphere(root, "Hand", Vector3.zero, V(0.36, 0.37, 0.36), skin),
			thigh = limb("Trousers", 0.49, "334451"),
			shin = limb("Boot shaft", 0.43, "483D39"),
			boot = limb("Boot", 0.46, "453C38"),
		}
	end
	return self
end
function Actor:pose(base, crouch, turn, tilt, left, right, stride)
	local body = base * CF(0, 1.94 - 0.64 * crouch, 0) * A(0.22 * crouch, turn * 0.26, 0)
	self.torso:PivotTo(body)
	self.head:PivotTo(body * CF(0, 1.03, 0.04) * A(tilt, turn, 0.035 * math.sin(turn)))
	for i, l in self.limbs do
		local s = l.s
		local a = body:PointToWorldSpace(V(s * 0.73, 0.32, 0))
		local b = base:PointToWorldSpace(if i == 1 then left else right)
		local elbow = joint(a, b, base:VectorToWorldSpace(V(s * 0.65, -0.88, -0.52)), 0.61)
		segment(l.sleeve, a, elbow)
		segment(l.cuff, elbow, b)
		l.hand.Position = b
		local hip = body:PointToWorldSpace(V(s * 0.35, -0.44, 0))
		local foot = base * CF(s * 0.37, 0.21 + math.max(0, stride * s) * 0.22, stride * s * 0.52)
		local knee = joint(hip, foot.Position, base.LookVector * -1, 0.76)
		segment(l.thigh, hip, knee)
		segment(l.shin, knee, foot.Position)
		l.boot.Size, l.boot.CFrame = V(0.48, 0.37, 0.75), foot * CF(0, -0.025, 0.13)
	end
end
return Actor
