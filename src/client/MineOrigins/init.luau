local Actions = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Prompts = game:GetService("ProximityPromptService")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Film = require(script.Film)
local Audio = require(script.Parent.HarborAudio)
local W = require(script.Parent.Widgets)
local rgb = Color3.fromHex
local Opening = {}

local function layer(player, name, order, insets)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.ScreenInsets = name, order, insets
	gui.ResetOnSpawn, gui.ZIndexBehavior = false, Enum.ZIndexBehavior.Sibling
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.Parent = player.PlayerGui
	return gui
end
local function textLimit(label, font, maxSize)
	label.Font, label.TextScaled, label.TextWrapped = font, true, true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize, constraint.MaxTextSize, constraint.Parent = 10, maxSize, label
end
local function compose(screen, safe)
	local bars = W.frame(screen, "Letterbox", 0, 0, 1, 1, rgb("10131D"))
	bars.Size, bars.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	local upper = W.frame(bars, "Upper", 0, 0, 1, 1, rgb("10131D"))
	local lower = W.frame(bars, "Lower", 0, 0, 1, 1, rgb("10131D"))
	lower.AnchorPoint, lower.Position = Vector2.new(0, 1), UDim2.fromScale(0, 1)
	local scrim = W.frame(screen, "Subtitle shade", 0, 0, 1, 1, rgb("0D1018"))
	scrim.AnchorPoint, scrim.Position, scrim.Size = Vector2.new(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.31)
	local ramp = Instance.new("UIGradient")
	ramp.Rotation, ramp.Transparency, ramp.Parent = 90, NumberSequence.new(1, 0.06), scrim
	local fade = W.frame(screen, "Dissolve", 0, 0, 1, 1, rgb("10131D"))
	fade.Size = UDim2.fromScale(1, 1)
	local caption = W.text(safe, "", 0, 0, 1, 1, 24, rgb("FFF3DF"))
	caption.Name, caption.AnchorPoint = "Caption", Vector2.new(0.5, 0.5)
	caption.TextStrokeColor3 = rgb("12111A")
	textLimit(caption, Enum.Font.Garamond, 34)
	local era = W.text(safe, "", 0, 0, 1, 1, 14, rgb("FFE0AE"))
	era.Name, era.AnchorPoint = "Era", Vector2.new(0.5, 1)
	textLimit(era, Enum.Font.BuilderSansBold, 14)
	local skip = Instance.new("TextButton")
	skip.Name, skip.Text, skip.Font, skip.TextSize = "Skip", "Skip  ›", Enum.Font.BuilderSansMedium, 16
	skip.AnchorPoint, skip.Position, skip.Size = Vector2.new(1, 0), UDim2.new(1, -12, 0, 6), UDim2.fromOffset(84, 44)
	skip.TextColor3, skip.BackgroundColor3, skip.BackgroundTransparency = rgb("FFF3DF"), rgb("151622"), 0.32
	skip.BorderSizePixel, skip.Parent = 0, safe
	W.round(skip, 7)
	local function resize()
		local size = bars.AbsoluteSize
		local narrow = size.X < size.Y
		local barHeight = if narrow then 0 else math.min(34, math.floor(size.Y * 0.038))
		upper.Size, lower.Size = UDim2.new(1, 0, 0, barHeight), UDim2.new(1, 0, 0, barHeight)
		caption.Size =
			UDim2.new(if narrow then 0.90 else 0.84, 0, 0, if narrow then 85 else math.clamp(size.Y * 0.105, 38, 76))
		caption.Position = UDim2.fromScale(0.5, if narrow then 0.82 else 0.87)
		era.Size = UDim2.new(0.85, 0, 0, 18)
		era.Position = caption.Position - UDim2.fromOffset(0, caption.Size.Y.Offset / 2 + 3)
	end
	bars:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return caption, era, skip, fade
end

function Opening.play(player, net, hud)
	local camera, char = workspace.CurrentCamera, player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local site, gate = net:GetAttribute("DigFloor"), net:GetAttribute("Entrance")
	if hud.inOpening or not camera or not root or not site or not gate then
		return
	end
	local oldView, oldFocus, oldFov, oldType = camera.CFrame, camera.Focus, camera.FieldOfView, camera.CameraType
	local oldHud, oldPrompts = hud.root.Visible, Prompts.Enabled
	local aimGui = hud.reticle.Parent
	local oldAim = aimGui.Enabled
	local screen = layer(player, "Mine origins", 24, Enum.ScreenInsets.None)
	local safe = layer(player, "Keeper subtitles", 25, Enum.ScreenInsets.CoreUISafeInsets)
	local stage = Instance.new("Folder")
	stage.Name, stage.Parent = "Mine origins set", camera
	local oldClock = Lighting.ClockTime
	local controls, chatEnabled, skipped, finished
	hud.inOpening, hud.root.Visible, Prompts.Enabled = true, false, false
	aimGui.Enabled = false
	local function run()
		local caption, era, skip, fade = compose(screen, safe)
		skip.Activated:Connect(function()
			skipped = true
		end)
		Actions:BindActionAtPriority("Skip mine origins", function(_, state)
			if state == Enum.UserInputState.Begin then
				skipped = true
			end
			return Enum.ContextActionResult.Sink
		end, false, 3100, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)
		Actions:BindActionAtPriority("Watch mine origins", function()
			return Enum.ContextActionResult.Sink
		end, false, 3050, table.unpack(Enum.PlayerActions:GetEnumItems()))
		local module = player.PlayerScripts:FindFirstChild("PlayerModule")
		if module then
			controls = require(module):GetControls()
			controls:Disable()
		end
		chatEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
		if chatEnabled then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end
		camera.CameraType = Enum.CameraType.Scriptable
		if workspace.StreamingEnabled then
			task.spawn(function()
				pcall(player.RequestStreamAroundAsync, player, site, 4)
			end)
		end
		local motion = player:GetAttribute("MenuMotion") ~= false
		local film = Film.new(screen, stage, camera, site, motion, oldClock)
		local sound = Audio.origins(screen)
		local start = os.clock()
		while not skipped and player.Character == char and root.Parent and workspace.CurrentCamera == camera do
			local t = os.clock() - start
			local island = workspace:FindFirstChild("CitrineCove")
			local gallery = island and island:FindFirstChild("Working gallery")
			local black = film:draw(t, gallery ~= nil and gallery:FindFirstChild("Hut back wall") ~= nil, site, gate)
			local date, line, opacity = Film.caption(t)
			caption.Text, era.Text = line, date
			caption.TextTransparency, era.TextTransparency = 1 - opacity, 1 - opacity
			caption.TextStrokeTransparency = 1 - 0.56 * opacity
			fade.BackgroundTransparency = 1 - black
			sound(t)
			if t >= Film.duration then
				finished = true
				break
			end
			Run.PreRender:Wait()
		end
		if (skipped or finished) and not player:GetAttribute("IntroSeen") then
			net.Action:FireServer("IntroSeen")
		end
		return fade
	end
	local ok, result = xpcall(run, debug.traceback)
	Actions:UnbindAction("Watch mine origins")
	Actions:UnbindAction("Skip mine origins")
	stage:Destroy()
	Lighting.ClockTime = oldClock
	if workspace.CurrentCamera == camera then
		if player.Character == char then
			camera.CFrame, camera.Focus = oldView, oldFocus
		end
		camera.FieldOfView, camera.CameraType = oldFov, oldType
	end
	if controls then
		controls:Enable()
	end
	if chatEnabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end
	hud.root.Visible, Prompts.Enabled = oldHud, oldPrompts
	aimGui.Enabled = oldAim
	safe:Destroy()
	if ok and finished then
		result.Parent.Letterbox.Visible = false
		result.Parent["Subtitle shade"].Visible = false
		W.tween(result, 0.35, { BackgroundTransparency = 1 }).Completed:Wait()
	end
	screen:Destroy()
	hud.inOpening = false
	if not ok then
		warn("Mine origins:", result)
	end
end
return Opening
