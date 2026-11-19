local Content = game:GetService("ContentProvider")
local First = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Run = game:GetService("RunService")
local Actions = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name, gui.DisplayOrder, gui.ResetOnSpawn, gui.ScreenInsets = "MiningLoading", 100, false, Enum.ScreenInsets.None
gui.ClipToDeviceSafeArea = false
local cover = Instance.new("Frame")
cover.Name, cover.BackgroundColor3, cover.BorderSizePixel = "Cover", Color3.fromRGB(27, 43, 63), 0
cover.Size, cover.Active, cover.Parent = UDim2.fromScale(1, 1), true, gui
cover.BackgroundTransparency = 0
local function blockMovement()
	return Enum.ContextActionResult.Sink
end
Actions:BindActionAtPriority("MiningLoadLock", blockMovement, false, 10000, unpack(Enum.PlayerActions:GetEnumItems()))
Run:BindToRenderStep("MiningLoadLock", Enum.RenderPriority.Input.Value + 1, function()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:Move(Vector3.zero, false)
		humanoid.Jump = false
	end
end)
local function line(text, y, size, tint)
	local label = Instance.new("TextLabel")
	label.Text, label.Font, label.TextSize, label.TextColor3 = text, Enum.Font.FredokaOne, size, tint
	label.BackgroundTransparency, label.AnchorPoint, label.Size = 1, Vector2.new(0.5, 0.5), UDim2.new(1, -16, 0, 48)
	label.Position, label.Parent = UDim2.new(0.5, 0, 0.5, y), cover
	return label
end
line("Citrine Cove", -25, 36, Color3.fromRGB(255, 213, 119))
local status = line("Opening the mine…", 20, 18, Color3.fromRGB(206, 237, 231))
gui.Parent = parent
First:RemoveDefaultLoadingScreen()
-- Only warm the built-in surfaces used by the studded plastic blocks.
local materialsFinished = false
task.spawn(function()
	pcall(function()
		Content:PreloadAsync({
			"rbxasset://textures/studs.dds",
			"rbxasset://textures/SurfacesDefault.png",
			"rbxasset://textures/plastic/diffuse.dds",
			"rbxasset://textures/plastic/normal.dds",
			"rbxasset://textures/plastic/normaldetail.dds",
		})
	end)
	materialsFinished = true
end)

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
local requestedEntrance = false
local function entranceBrickCount(net)
	local origin = net:GetAttribute("Origin")
	if not origin then
		return 0
	end
	if workspace.StreamingEnabled and not requestedEntrance then
		requestedEntrance = true
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(origin + Vector3.new(0, -48, -86), 2)
			end)
		end)
	end
	local island = workspace:FindFirstChild("CitrineCove")
	local grid = island and island:FindFirstChild("MineBlocks")
	local portal = island and island:FindFirstChild("Citrine Mine")
	local glow = portal and portal:FindFirstChild("Gallery glow")
	if not grid or not glow or not glow:FindFirstChildOfClass("PointLight") then
		return 0
	end
	overlap.FilterDescendantsInstances = { grid }
	return #workspace:GetPartBoundsInBox(
		CFrame.new(origin + Vector3.new(0, -50, -86)),
		Vector3.new(32, 12, 22),
		overlap
	)
end

-- The entrance lights can already be replicated while the renderer still shows
-- the unlit ore. Give it several seconds of frames with the actual scene present.
local lightWarmup = 9.5
local deadline = os.clock() + 15
local lastCount, countChanged, firstReady = 0, 0, nil
local renderedTime = 0
local function renderInterval()
	local untilTime = os.clock() + 0.1
	local rendered = 0
	repeat
		-- A single slow frame during replication hasn't given the lights time to render.
		rendered += math.min(Run.PreRender:Wait(), 1 / 15)
	until os.clock() >= untilTime
	return rendered
end
repeat
	local net = Rep:FindFirstChild("EndlessMiningNet")
	local hud = parent:FindFirstChild("MiningHUD")
	local character = player.Character
	local count = if net then entranceBrickCount(net) else 0
	local ready = count > 0
		and game:IsLoaded()
		and workspace.CurrentCamera
		and character
		and character:GetAttribute("MiningViewReady")
		and character:FindFirstChild("Mining lamp", true)
		and Lighting:FindFirstChild("SeaAir")
		and Lighting:FindFirstChild("MarketGlow")
		and net:GetAttribute("Ready")
		and hud
		and hud:GetAttribute("ControllerReady")
		and player:GetAttribute("ProfileReady")
	local now = os.clock()
	if ready then
		firstReady = firstReady or now
		status.Text = "Lighting the mine…"
	else
		firstReady = nil
		if net and net:GetAttribute("Ready") then
			status.Text = "Getting your gear ready…"
		end
	end
	local visualsReady = firstReady and (materialsFinished or now - firstReady >= 2.5)
	if count ~= lastCount then
		countChanged = now
		lastCount = count
	end
	if visualsReady and now - countChanged >= 0.3 and renderedTime >= lightWarmup then
		break
	end
	local interval = renderInterval()
	renderedTime = if visualsReady then renderedTime + interval else 0
until os.clock() >= deadline
gui:Destroy()
local net = Rep:FindFirstChild("EndlessMiningNet")
local action = net and net:FindFirstChild("Action")
if action then
	action:FireServer("Entered")
end
Run:UnbindFromRenderStep("MiningLoadLock")
Actions:UnbindAction("MiningLoadLock")
