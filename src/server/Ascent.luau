local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Ascent = {}

-- A climb belongs to this character and trip. Only its completed award is saved.
function Ascent.sample(session, character, position, inMine, now)
	local climb = session.climb
	if climb and (character ~= climb.character or position.Y - climb.y > 12 + 56 * (now - climb.time)) then
		session.climb = nil
		climb = nil
	end
	if not climb then
		if inMine and Config.depthInBlocks(Config.FloorY - position.Y) > 100 then
			session.climb = { character = character, y = position.Y, time = now }
		end
		return false
	end
	if position.Y >= Config.FloorY then
		session.climb = nil
		-- A player can step across the entrance sill between two samples.
		return math.abs(position.X) <= Config.HallHalfWidth + 8
			and position.Z >= Config.HallBack - 8
			and position.Z <= Config.HallFront + 10
	end
	if not inMine then
		session.climb = nil
		return false
	end
	climb.y, climb.time = position.Y, now
	return false
end
return Ascent
