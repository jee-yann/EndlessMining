local P = require(script.Parent.Props)
local V, CF = Vector3.new, CFrame.new
local Tide = {}
Tide.__index = Tide

-- A vibration can be seen first in the water on either side of the bridge, then
-- in the brass of the landing compass. The geometry lives with this camera.
function Tide.new(parent, gate, landing)
	local marks = {}
	for i, x in { -7.6, 8.1 } do
		local model = P.model(nil, "Ripples under the boards")
		for j = 1, 18 do
			local a = j * math.pi / 9
			local b = a + math.pi / 9
			local segment = P.rod(
				model,
				"Ripple crest",
				V(math.cos(a), 0, math.sin(a)),
				V(math.cos(b), 0, math.sin(b)),
				0.025,
				Color3.fromHex("F6DAEE")
			)
			segment.Material, segment.CastShadow = Enum.Material.Neon, false
		end
		marks[i] = { model = model, at = gate * CF(x, -3.77, 30.4 + (i - 1) * 4.1), time = 45.54 + i * 0.15 }
	end
	local point = P.box(parent, "Resonance on the landing brass", landing, Vector3.one, "D6BAE8")
	point.Transparency, point.CastShadow = 1, false
	local light = P.light(point, "E6B5FA", 11, 0)
	return setmetatable({ marks = marks, stage = parent, light = light }, Tide)
end

function Tide:draw(t)
	for _, mark in self.marks do
		local age = t - mark.time
		if age >= 0 and age <= 1.03 then
			if not mark.model.Parent then
				mark.model.Parent = self.stage
			end
			mark.model:ScaleTo(0.26 + age * 3.4)
			mark.model:PivotTo(mark.at)
			local opacity = math.sin(math.pi * age / 1.03) * 0.47
			for _, crest in mark.model:GetChildren() do
				crest.Transparency = 1 - opacity
			end
		elseif mark.model.Parent then
			mark.model.Parent = nil
		end
	end
	local age = t - 47.34
	self.light.Brightness = if age > 0 then 2.2 * P.ease(age, 0, 0.18) * (1 - P.ease(age, 0.23, 1.13)) else 0
end

function Tide:Destroy()
	for _, mark in self.marks do
		mark.model:Destroy()
	end
end

return Tide
