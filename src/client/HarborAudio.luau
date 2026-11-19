local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")

local Audio = {}
local bus = Instance.new("Folder")
bus.Name, bus.Parent = "Harbor audio", SoundService
local function sound(name, asset, volume, pitch)
	local s = Instance.new("Sound")
	s.Name, s.SoundId, s.Volume, s.PlaybackSpeed, s.Parent = name, asset, volume, pitch, bus
	return s
end

-- Jim Condelli, Another 8 Bit Game, from APM's Roblox Creator Store catalog.
local music = sound("Another 8 Bit Game", "rbxassetid://9048374150", 0, 1)
music.Looped = true
local enabled = true
local fade
local function fadeMusic(volume)
	if fade then
		fade:Cancel()
	end
	fade = TweenService:Create(music, TweenInfo.new(0.3), { Volume = volume })
	fade:Play()
end
music:Play()
fadeMusic(0.17)

function Audio.toggleMusic()
	enabled = not enabled
	if enabled then
		if not music.IsPlaying then
			music:Resume()
		end
		fadeMusic(0.17)
	else
		fadeMusic(0)
		fade.Completed:Once(function()
			if not enabled then
				music:Pause()
			end
		end)
	end
	return enabled
end

local bell = "rbxasset://sounds/volume_slider.ogg"
local tap = "rbxasset://sounds/action_jump_land.mp3"
local voices = {
	Hover = sound("Cursor tick", bell, 0.055, 2.45),
	Open = sound("Menu pop", bell, 0.19, 1.38),
	Close = sound("Close pop", bell, 0.15, 0.84),
	Buy = sound("Workshop tap", tap, 0.24, 2.2),
	Job = sound("Job stamp", tap, 0.22, 1.8),
	Lift = sound("Lift bell", bell, 0.17, 0.99),
	Sell = sound("Coin click", bell, 0.19, 1.80),
	Mine = sound("Pick grip", tap, 0.12, 1.6),
	Select = sound("Switch", bell, 0.16, 1.17),
}
local function play(key)
	local voice = voices[key]
	voice.TimePosition = 0
	voice:Play()
end
local lastHover = 0
function Audio.bind(button, cue)
	button.MouseEnter:Connect(function()
		if
			button.Interactable
			and Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
			and os.clock() - lastHover > 0.09
		then
			lastHover = os.clock()
			play("Hover")
		end
	end)
	if cue == "Mine" then
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				play(cue)
			end
		end)
	else
		button.Activated:Connect(function()
			play(cue or "Open")
		end)
	end
end
return Audio
