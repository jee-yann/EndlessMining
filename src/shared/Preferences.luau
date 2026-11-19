local Preferences = {}
Preferences.defaults = { MusicVolume = 55, SfxVolume = 80, MenuMotion = true }

function Preferences.valid(key, value)
	if key == "MenuMotion" then
		return type(value) == "boolean"
	end
	return (key == "MusicVolume" or key == "SfxVolume")
		and type(value) == "number"
		and value >= 0
		and value <= 100
		and value % 1 == 0
end
return Preferences
