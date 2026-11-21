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

-- Keep gameplay labels and the live avatar out of its double's shot. Streamed-in
-- signs and accessories use the same restoration path as existing instances.
local function clearSightlines(character, map)
	local hidden, connections = {}, {}
	local function hidePart(p)
		if p:IsA("BasePart") and hidden[p] == nil then
			hidden[p] = p.LocalTransparencyModifier
			p.LocalTransparencyModifier = 1
		elseif p:IsA("BillboardGui") and p.Enabled then
			hidden[p] = true
			p.Enabled = false
		end
	end
	local function hideSign(p)
		if p:IsA("BillboardGui") and p.Enabled then
			hidden[p] = true
			p.Enabled = false
		end
	end
	local function watch(root, hide)
		if not root then
			return
		end
		table.insert(connections, root.DescendantAdded:Connect(hide))
		for _, p in root:GetDescendants() do
			hide(p)
		end
	end
	watch(character, hidePart)
	watch(map, hideSign)
	return function()
		for _, c in connections do
			c:Disconnect()
		end
		for p, old in hidden do
			if p.Parent then
				if p:IsA("BillboardGui") then
					p.Enabled = old
				elseif p.LocalTransparencyModifier == 1 then
					p.LocalTransparencyModifier = old
				end
			end
		end
	end
end

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
	return constraint
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
	local fade = W.frame(screen, "Dissolve", 0, 0, 1, 1, rgb("040509"))
	fade.Size, fade.ZIndex = UDim2.fromScale(1, 1), 8
	local caption = W.text(safe, "", 0, 0, 1, 1, 24, rgb("FFF3DF"))
	caption.Name, caption.AnchorPoint = "Caption", Vector2.new(0.5, 0.5)
	caption.TextStrokeColor3 = rgb("12111A")
	textLimit(caption, Enum.Font.BuilderSansMedium, 38)
	local era = W.text(safe, "", 0, 0, 1, 1, 14, rgb("FFE0AE"))
	era.Name, era.AnchorPoint = "Era", Vector2.new(0.5, 1)
	textLimit(era, Enum.Font.BuilderSansBold, 18)
	local card = W.text(safe, "", 0, 0, 1, 1, 46, rgb("FFF0CA"))
	card.Name, card.AnchorPoint, card.Position = "Intertitle", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.48)
	card.Size, card.TextTransparency = UDim2.fromScale(0.86, 0.18), 1
	local cardLimit = textLimit(card, Enum.Font.BuilderSansExtraBold, 88)
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
	return caption, era, skip, fade, card, cardLimit, scrim
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
	local safe = layer(player, "Mine subtitles", 25, Enum.ScreenInsets.CoreUISafeInsets)
	local stage = Instance.new("Folder")
	stage.Name, stage.Parent = "Mine origins set", camera
	local oldClock = Lighting.ClockTime
	local controls, chatEnabled, skipped, finished, restoreSightlines
	local lens = Instance.new("DepthOfFieldEffect")
	lens.Name, lens.Enabled, lens.Parent = "Mine origins focus", false, camera
	hud.inOpening, hud.root.Visible, Prompts.Enabled = true, false, false
	aimGui.Enabled = false
	local function run()
		local caption, era, skip, fade, card, cardLimit, scrim = compose(screen, safe)
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
		restoreSightlines = clearSightlines(char, workspace:FindFirstChild("CitrineCove"))
		if workspace.StreamingEnabled then
			task.spawn(function()
				pcall(player.RequestStreamAroundAsync, player, site, 4)
			end)
		end
		local motion = player:GetAttribute("MenuMotion") ~= false
		local film = Film.new(screen, stage, camera, site, gate, motion, oldClock, char)
		local sound = Audio.origins(screen)
		local start = os.clock()
		while not skipped and player.Character == char and root.Parent and workspace.CurrentCamera == camera do
			local t = os.clock() - start
			local island = workspace:FindFirstChild("CitrineCove")
			local gallery = island and island:FindFirstChild("Working gallery")
			local gateModel = island and island:FindFirstChild("Citrine Mine")
			local live = gallery
				and gallery:FindFirstChild("Entrance sill")
				and gateModel
				and gateModel:FindFirstChild("Mine sign")
			local black = film:draw(t, live ~= nil)
			lens.Enabled = (t >= 13.12 and t < 15.55)
				or (t >= 18.78 and t < 20.19)
				or (t >= 22.04 and t < 24.36)
				or (t >= 28.78 and t < 31.52)
			if lens.Enabled then
				lens.FocusDistance = (camera.Focus.Position - camera.CFrame.Position).Magnitude
				lens.InFocusRadius, lens.FarIntensity, lens.NearIntensity = 2.2, 0.34, 0.08
			end
			local date, line, opacity = Film.caption(t)
			caption.Text, era.Text = line, date
			caption.TextTransparency, era.TextTransparency = 1 - opacity, 1 - opacity
			caption.TextStrokeTransparency = 1 - 0.56 * opacity
			local title, titleOpacity = Film.card(t)
			card.Text, card.TextTransparency = title, 1 - titleOpacity
			cardLimit.MaxTextSize = if t < 30 then 50 else 88
			scrim.BackgroundTransparency = 1 - 0.87 * opacity
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
	lens:Destroy()
	if restoreSightlines then
		restoreSightlines()
	end
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
