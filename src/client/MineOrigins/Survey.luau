local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local Survey = {}
Survey.__index = Survey
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
local metal, neon = Enum.Material.Metal, Enum.Material.Neon
local pad = V(1.6, 0.34, 22.7)
Survey.pad = pad

-- The survey hammer sends its test down the cable from the footbridge to the gate.
local cablePath =
	{ pad + V(0, 0.13, 0), V(1.0, 0.47, 20.1), V(-2.3, 0.40, 17.0), V(-3.4, 0.38, 11), V(-3.05, 0.40, 7.0) }
local faultPath = {
	V(0.05, 1.2, 4.65),
	V(0.5, 0.42, 3.3),
	V(-0.85, 0.30, 0.2),
	V(0.14, 0.27, -3.6),
	V(-1.64, 0.25, -6.5),
	V(-0.48, 0.22, -11),
	V(-2.25, 0.22, -17),
	V(-1, 0.22, -22),
}
local function onPath(path, u)
	local at = math.clamp(u, 0, 1) * (#path - 1)
	local i = math.min(math.floor(at) + 1, #path - 1)
	return path[i]:Lerp(path[i + 1], at - i + 1)
end
function Survey.new(shelf)
	local root = P.model(shelf, "Footbridge survey")
	local self = setmetatable({ root = root, lamps = {}, pips = {}, fault = {} }, Survey)
	P.cylinder(root, "Footplate", pad, 0.98, 0.24, "374453", metal)
	P.cylinder(root, "Strike plate", pad + V(0, 0.15, 0), 0.59, 0.12, "CCC3A3", metal)
	for i = 1, 3 do
		local angle = i * math.pi * 2 / 3
		local s = V(math.cos(angle), 0, math.sin(angle))
		P.rod(root, "Folding leg", pad + s * 1.55, pad + s * 0.65 + V(0, 3.05, 0), 0.21, rgb("E7A836"))
		P.rod(root, "Brace", pad + s * 1.12 + V(0, 0.82, 0), pad + V(0, 0.48, 0), 0.13, rgb("44575C"))
		P.box(root, "Rubber foot", pad + s * 1.53, V(0.48, 0.25, 0.49), "343D46")
	end
	P.cylinder(root, "Drive casing", pad + V(0, 3.15, 0), 0.92, 0.76, "D69C39", metal)
	P.cylinder(root, "Cap", pad + V(0, 3.60, 0), 0.78, 0.16, "405861", metal)
	self.ram = P.model(root, "Test hammer")
	P.cylinder(self.ram, "Piston shaft", V(0, 0.99, 0), 0.2, 1.7, "9CABAA", metal)
	P.cylinder(self.ram, "Hammer head", V(0, 0.20, 0), 0.52, 0.40, "596574", metal)
	for i = 1, 3 do
		local p = P.box(root, "Counter lamp", pad + V((i - 2) * 0.33, 3.18, 0.86), V(0.23, 0.32, 0.09), "37454B")
		table.insert(self.lamps, p)
	end
	for i = 1, #cablePath - 1 do
		P.rod(root, "Survey cable", cablePath[i], cablePath[i + 1], 0.14, rgb("394C56"))
	end
	for i = 1, 3 do
		table.insert(self.pips, P.sphere(root, "Cable pulse", Vector3.zero, V(0.48, 0.22, 0.72), "FFD371", neon))
	end
	-- The crew's standing work light illuminates their hands on the tunnel side.
	local foot = V(-5.7, 0.27, 1.9)
	P.box(root, "Work light foot", foot, V(1.24, 0.28, 1), "405764", nil, metal)
	P.rod(root, "Light mast", foot, foot + V(0, 3.7, 0), 0.13, rgb("7B8994"))
	P.box(root, "Lamp guard", foot + V(0, 3.74, 0), V(0.82, 0.63, 0.35), "465561", A(0, -0.64, 0), metal)
	local lamp =
		P.box(root, "LED panel", foot + V(0.11, 3.74, 0.15), V(0.66, 0.43, 0.13), "FFEACB", A(0, -0.64, 0), neon)
	P.light(lamp, "FFF1D8", 19, 1.52)
	for i = 1, #faultPath - 1 do
		local p = P.rod(root, "Answer in the rock", faultPath[i], faultPath[i + 1], 0.12, rgb("DFB4FF"))
		p.Material, p.Transparency = neon, 1
		table.insert(self.fault, p)
	end
	self.front = P.sphere(root, "Echo front", Vector3.zero, V(0.63, 0.34, 1.42), "F4DCFF", neon)
	self.light = P.light(self.front, "DC9AFF", 11, 1.0)
	return self
end
function Survey:draw(t, base)
	local lift = 0
	for i, when in Beats.outbound do
		local age = t - when
		-- Retract smoothly; release the head into the plate over three frames.
		local stroke = P.ease(t, when - 0.32, when - 0.09) * (1 - P.ease(t, when - 0.09, when))
		lift = math.max(lift, stroke)
		local lamp = self.lamps[i]
		lamp.Color = rgb(if age >= 0 and age < 3.1 then "FFCD54" else "37454B")
		lamp.Material = if age >= 0 and age < 3.1 then neon else metal
		local p = self.pips[i]
		p.Transparency = if age >= 0 and age <= 1.70 then 0.05 else 1
		if p.Transparency < 1 then
			p.Position = base * onPath(cablePath, age / 1.70)
		end
	end
	self.ram:PivotTo(base * CF(pad + V(0, 0.25 + lift * 1.47, 0)))
	local u = (t - 31.55) / 2.4
	for i, p in self.fault do
		local age = t - (31.55 + 2.4 * (i - 1) / #self.fault)
		p.Transparency = if age < 0 then 1 else 0.12 + 0.88 * P.ease(age, 0.18, 1.05)
	end
	self.front.Transparency = if u >= 0 and u <= 1 then 0.09 else 1
	self.light.Enabled = self.front.Transparency < 1
	if self.light.Enabled then
		self.front.Position = base * onPath(faultPath, u)
	end
end

-- A small, lamp-lit survey bay keeps close shots readable if the harbor is still streaming.
function Survey.standIn(parent, base)
	local room = P.model(parent, "Survey bay")
	P.box(room, "Rock floor", V(0, -0.58, 0), V(130, 1.1, 150), "685C62", nil, Enum.Material.Slate)
	for _, z in { 2, -6, -14, -22 } do
		for _, side in { -1, 1 } do
			P.box(room, "Steel upright", V(7.45 * side, 4, z), V(0.66, 8.4, 0.76), "52636A", nil, metal)
			P.box(room, "Tunnel side", V(8.3 * side, 4, z - 3.7), V(1.5, 9, 8), "555262", nil, Enum.Material.Slate)
			local wallLight = P.box(room, "Work light", V(7.05 * side, 5.2, z), V(0.2, 0.85, 0.7), "FFD49B", nil, neon)
			P.light(wallLight, "FFD49B", 15, 0.9)
		end
		P.box(room, "Lintel", V(0, 8.35, z), V(15.4, 0.63, 1.05), "53636A", nil, metal)
	end
	P.box(room, "Rear rock", V(0, 4, -28), V(18, 9, 2), "4F4757", nil, Enum.Material.Slate)
	room:PivotTo(base)
	return room
end
return Survey
