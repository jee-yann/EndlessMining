local ease = require(script.Parent.Props).ease
local V = Vector3.new
local Overlook = {}

function Overlook.frame(age, aspect, motion)
	local narrow = math.clamp((1.16 - aspect) / 0.70, 0, 1)
	-- Hold the survey photograph through the first seasons. Only the cutter's
	-- landing and the laying of the siding motivate a move around the cove.
	local track = if motion then 0.55 * ease(age, 5.55, 6.95) + 0.45 * ease(age, 9.8, 11.42) else 0.34
	local angle = math.rad(-24.5 + 12.5 * track)
	local distance = (365 - 12 * track) * (1 + 0.075 * narrow)
	local look = V(-2.5 + 4 * track, 51.5 - track * 4.2, 12 + 5 * track)
	local eye = look + V(distance * math.sin(angle), 94 + 5 * track + narrow * 3, distance * math.cos(angle))

	if age < 15.10 then
		return eye, look, 47 - 1.8 * track, 0
	end
	-- Match on the rails across two scales. Give the audience a beat to read
	-- the finished bridge before the modern crew appears in the same gate shot.
	if age < 16.28 then
		return V(-69, 54, 125), V(1.7, 13.5, 9), 52, -0.023
	end
	return V(-32, 29, 66), V(5, 8, 1), 57, -0.035
end

return Overlook
