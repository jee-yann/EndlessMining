local ease = require(script.Parent.Props).ease
local V = Vector3.new
local Overlook = {}

-- A dolly on a circular track keeps the landing, mine and northern ridge in
-- their screen order. As the skiff docks, the near quay moves against the ridge.
function Overlook.frame(age, aspect, motion)
	local narrow = math.clamp((1.16 - aspect) / 0.70, 0, 1)
	local travel = if motion then ease(age, -0.8, 14.70) else 0.42
	local angle = math.rad(-24.5 + 12.5 * travel)
	local distance = (365 - 12 * travel) * (1 + 0.075 * narrow)
	local look = V(-2.5 + 4.0 * travel, 51.5 - travel * 4.2, 12 + 5 * travel)
	local eye = look + V(distance * math.sin(angle), 94 + 5 * travel + narrow * 3, distance * math.cos(angle))
	local push = if motion then ease(age, 14.72, 16.97) else if age >= 15.96 then 1 else 0
	local gateEye, gateLook = V(-32, 29, 66), V(5, 8, 1)
	local fov = 47 - 1.8 * travel
	return eye:Lerp(gateEye, push) + V(-9, 13, 2) * math.sin(math.pi * push),
		look:Lerp(gateLook, push),
		fov + (57 - fov) * push,
		-0.035 * push
end

return Overlook
