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

local pop = "rbxassetid://15675055424" -- Roblox UI Cute Pop
local voices = {
	Hover = sound("Hover pip", pop, 0.055, 1.52),
	Open = sound("Menu bubble", pop, 0.19, 1.13),
	Close = sound("Close bubble", "rbxassetid://15675081158", 0.15, 1.1),
	Buy = sound("Workshop pop", pop, 0.17, 1.18),
	Job = sound("Job pop", pop, 0.16, 1.31),
	Lift = sound("Lift pop", pop, 0.16, 0.97),
	Mine = sound("Grip pop", pop, 0.09, 0.78),
	Select = sound("Switch pop", pop, 0.15, 1.21),
	Reward = sound("Reward bubbles", pop, 0.18, 1.26),
}
for _, voice in voices do
	if voice.SoundId == pop then
		voice.PlaybackRegionsEnabled = true
		voice.PlaybackRegion = NumberRange.new(0, 0.24)
	end
end
local function play(key)
	local voice = voices[key]
	voice.TimePosition = 0
	voice:Play()
end
function Audio.reward(pitch)
	play("Open")
	task.delay(0.10, function()
		voices.Reward.PlaybackSpeed = pitch
		play("Reward")
	end)
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
