local P = require(script.Parent.Props)
local Burial = require(script.Parent.Burial)
local V, ease = Vector3.new, P.ease
local Shot = {}

function Shot.frame(t, motion, trajectory)
	local at = trajectory(t)
	if t < 3.08 then
		local u = if motion then ease(t, 0.25, 3.08) else 0.34
		local eye = at + V(14 - 22 * u, 8 - 6 * u, 42 - 19 * u)
		return eye, at + V(2.1 - 3 * u, 1.4, 0), 49, if motion then 0.055 - 0.12 * u else 0
	elseif t < 4.82 then
		local dir = (trajectory(t + 0.035) - at).Unit
		local u = if motion then ease(t, 3.08, 4.82) else 0.5
		return at - dir * (17 + 13 * u) + V(9.4, 4, 10.4), at + dir * (7 + 13 * u), 62 + 4 * u, -0.045
	elseif t < 7.58 then
		-- Shoot across the shore. The oncoming stone, lit point of contact and
		-- late pressure front all traverse this same wide, low frame.
		local s = t - 6.5
		local recoil = if motion then ease(s, 0.13, 0.52) * (1 - 0.42 * ease(s, 0.65, 1.16)) else 0
		local dt = math.max(0, s - 0.17)
		local shake = if motion and s > 0.17 then math.exp(-4.8 * dt) * math.sin(dt * 31) else 0
		local flight = math.clamp(-s / 1.68, 0, 1)
		local eye = V(-17 - 2.5 * recoil, 8.4 + 1.3 * recoil + 0.6 * shake, 55 + 3.8 * recoil)
		local target = V(1.7, 4.6 + 6.8 * ease(s, 0.05, 0.85), 0):Lerp(at, flight * 0.64)
		return eye, target, 53 + recoil * 3, 0.018 * shake
	else
		local core = Burial.point(t)
		local deep = ease(t, 7.74, 10.31)
		local back = ease(t, 10.88, 12.10)
		local distance = 35.5 + 12 * deep + 34 * back
		local lead = 1.5 + 1.6 * deep + 14 * back
		local aim = core + V(2.7 * math.sin((t - 7.58) * 2.1), lead + 0.9 * math.sin(t * 4), 0)
		-- Arrive at the deep bed ahead of the core, so it visibly falls through
		-- the last part of the frame and comes to rest on screen.
		local stop = Burial.point(10.81) + V(0.4, 9.1 + 13.4 * back, 0)
		aim = aim:Lerp(stop, ease(t, 10.17, 10.56))
		local x = if motion then 3.3 - 5 * deep else 0
		return aim + V(x, 2.7 + back * 2.4, distance), aim, 54 + 4 * back, if motion then -0.012 + 0.019 * deep else 0
	end
end

function Shot.surface(t, motion, eye, look, fov, roll)
	local vent = V(0, -0.205, -37.25)
	if not motion then
		return eye, look, fov, roll
	end
	local u = ease(t, 12.12, 13.60)
	local start = vent + V(-41, 38, 63)
	return start:Lerp(eye, u) + V(0, 7.4 * math.sin(math.pi * u), 0),
		(vent + V(0, -0.3, 2)):Lerp(look, u),
		52 + (fov - 52) * u,
		(roll or 0) * u
end

return Shot
