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
local ink = Color3.fromRGB(42, 34, 57)
cover.BackgroundColor3 = Color3.new(1, 1, 1)
local sky = Instance.new("UIGradient")
sky.Rotation = 38
sky.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 228, 139)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 185, 113)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 132, 146)),
})
sky.Parent = cover
local function round(obj, n)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, n)
	u.Parent = obj
end
local function plate(parentObj, name, x, y, w, h, color)
	local f = Instance.new("Frame")
	f.Name, f.BackgroundColor3, f.BorderSizePixel = name, color, 0
	f.Position, f.Size, f.Parent = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h), parentObj
	return f
end
local center = plate(cover, "Load panel", 0, 0, 422, 248, ink)
center.BackgroundTransparency = 1
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.Position = UDim2.fromScale(0.5, 0.5)
local scale = Instance.new("UIScale")
scale.Parent = center
local function resize()
	scale.Scale = math.clamp(math.min((cover.AbsoluteSize.X - 36) / 422, (cover.AbsoluteSize.Y - 36) / 248), 0.4, 1.45)
end
cover:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
local function label(name, text, x, y, w, h, size, color)
	local l = Instance.new("TextLabel")
	l.Name, l.Text, l.Font, l.TextSize, l.TextColor3 = name, text, Enum.Font.FredokaOne, size, color
	l.BackgroundTransparency, l.Position, l.Size, l.Parent = 1, UDim2.fromOffset(x, y), UDim2.fromOffset(w, h), center
	return l
end
local stone = plate(center, "Ore", 174, 0, 73, 66, ink)
round(stone, 14)
stone.Rotation = -9
local inset = plate(stone, "Specimen", 4, 3, 65, 58, Color3.fromRGB(85, 190, 176))
round(inset, 12)
for row = 0, 1 do
	for col = 0, 2 do
		local stud = plate(inset, "Stud", 7 + col * 19, 8 + row * 22, 13, 13, Color3.fromRGB(156, 240, 197))
		round(stud, 3)
	end
end
label("Title", "Mine EVERYTHING!", 0, 76, 422, 60, 45, ink)
local track = plate(center, "Loading bar", 24, 161, 374, 36, ink)
round(track, 12)
local fill = plate(track, "Progress", 4, 4, 0, 28, Color3.fromRGB(100, 234, 192))
round(fill, 8)
local status = label("Status", "Loading island parts…", 0, 0, 374, 36, 19, Color3.new(1, 1, 1))
status.TextStrokeColor3, status.TextStrokeTransparency = ink, 0.08
status.ZIndex, status.Parent = 2, track
local percent = label("Percent", "0%", 0, 205, 422, 24, 17, ink)
local shown = 0
local function progress(value)
	shown = math.max(shown, math.clamp(value, 0, 1))
	fill.Size = UDim2.new(0, math.floor(366 * shown), 0, 28)
	percent.Text = math.floor(shown * 100) .. "%"
end
gui.Parent = parent
First:RemoveDefaultLoadingScreen()
-- Only warm the built-in surfaces used by the studded plastic blocks.
local textures = {
	"rbxasset://textures/studs.dds",
	"rbxasset://textures/SurfacesDefault.png",
	"rbxasset://textures/plastic/diffuse.dds",
	"rbxasset://textures/plastic/normal.dds",
	"rbxasset://textures/plastic/normaldetail.dds",
}
local materialsFinished, processedTextures = false, 0
task.spawn(function()
	pcall(function()
		Content:PreloadAsync(textures, function()
			processedTextures = math.min(processedTextures + 1, #textures)
		end)
	end)
	materialsFinished = true
end)

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
local requestedEntrance = false
local function entranceBrickCount(net)
	local floor = net:GetAttribute("DigFloor")
	local size = net:GetAttribute("DigFloorSize")
	if not floor or not size then
		return 0
	end
	if workspace.StreamingEnabled and not requestedEntrance then
		requestedEntrance = true
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(floor, 2)
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
	return #workspace:GetPartBoundsInBox(CFrame.new(floor - Vector3.yAxis * (size.Y / 2)), size, overlap)
end

-- The entrance lights can already be replicated while the renderer still shows
-- the unlit ore. Give it several seconds of frames with the actual scene present.
local lightWarmup = 9.5
local coreSince
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
	local coreReady = game:IsLoaded()
		and workspace.CurrentCamera
		and character
		and character:GetAttribute("MiningViewReady")
		and net
		and net:GetAttribute("Ready")
		and hud
		and hud:GetAttribute("ControllerReady")
		and player:GetAttribute("ProfileReady")
	local now = os.clock()
	coreSince = if coreReady then coreSince or now else nil
	local ready = coreReady
		and count > 0
		and character:FindFirstChild("Mining lamp", true)
		and Lighting:FindFirstChild("SeaAir")
		and Lighting:FindFirstChild("MarketGlow")
	firstReady = if ready then firstReady or now else nil
	local scriptsReady = net and net:GetAttribute("Ready")
	local controlsReady = hud and hud:GetAttribute("ControllerReady")
	local profileReady = player:GetAttribute("ProfileReady")
	local visualsReady = firstReady and (materialsFinished or now - firstReady >= 2.5)
	status.Text = if not game:IsLoaded()
		then "Loading island parts…"
		elseif not scriptsReady then "Starting mine scripts…"
		elseif count == 0 then "Loading the mine entrance…"
		elseif not profileReady then "Loading your saved gear…"
		elseif not controlsReady then "Starting controls and HUD…"
		elseif
			not workspace.CurrentCamera
			or not character
			or not character:GetAttribute("MiningViewReady")
		then "Preparing your character…"
		elseif not materialsFinished and not visualsReady then string.format(
			"Loading surface textures · %d/%d",
			processedTextures,
			#textures
		)
		else "Warming up mine lighting…"
	local staged = (if game:IsLoaded() then 0.10 else 0)
		+ (if scriptsReady then 0.08 else 0)
		+ (if count > 0 then 0.16 else 0)
		+ 0.10 * (if materialsFinished then 1 else processedTextures / #textures)
		+ (if profileReady then 0.10 else 0)
		+ (if controlsReady then 0.11 else 0)
	progress(staged + 0.34 * math.min(1, renderedTime / lightWarmup))
	if count ~= lastCount then
		countChanged = now
		lastCount = count
	end
	if
		(visualsReady and now - countChanged >= 0.3 and renderedTime >= lightWarmup)
		or (coreSince and now - coreSince >= 15)
	then
		break
	end
	local interval = renderInterval()
	renderedTime = if visualsReady then renderedTime + interval else 0
until false
progress(1)
status.Text = "Ready to dig"
Run.PreRender:Wait()
task.wait(0.12)
gui:Destroy()
local net = Rep:FindFirstChild("EndlessMiningNet")
local action = net and net:FindFirstChild("Action")
if action then
	action:FireServer("Entered")
end
Run:UnbindFromRenderStep("MiningLoadLock")
Actions:UnbindAction("MiningLoadLock")
