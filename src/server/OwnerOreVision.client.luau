local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Rep = game:GetService("ReplicatedStorage")
local shared = Rep:WaitForChild("Shared")
local Ores = require(shared:WaitForChild("Ores"))
local Config = require(shared:WaitForChild("GameConfig"))
local net = Rep:WaitForChild("EndlessMiningNet")
local player = Players.LocalPlayer
local gui = script.Parent
local scan = gui:WaitForChild("Scan")
local playerGui = gui.Parent
local widgets = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Widgets"))
local location = playerGui:WaitForChild("MiningHUD"):WaitForChild("SafeArea"):WaitForChild("Location")
local surface = location:WaitForChild("Surface")
local badge = widgets.frame(location, "Ore vision status", 50, 52, 200, 23, widgets.ink, 8)
badge.BackgroundTransparency = 1
badge.Visible = false
local label = widgets.title(badge, "", 0, 0, 200, 23, 13, widgets.aqua)
widgets.outlineText(label, 1.5)
local function placeBadge()
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, 0, 1, if surface.Visible then 52 else 4)
end
surface:GetPropertyChangedSignal("Visible"):Connect(placeBadge)
placeBadge()

local markers = {}
local revision, session, lastClear = nil, 0, 0
local function updateCount(count)
	label.Text = string.format(
		"X-RAY  ·  %d blocks  ·  %d %s",
		Config.OreVisionRadius,
		count,
		if count == 1 then "ore" else "ores"
	)
end
local function clear()
	for _, box in markers do
		box:Destroy()
	end
	table.clear(markers)
	revision = nil
	lastClear += 1
	updateCount(0)
end

local function show(center, hits)
	local terrain = workspace.Terrain
	local nextMarkers = {}
	for i = 0, buffer.len(hits) - 1, 4 do
		local offset = Vector3.new(buffer.readi8(hits, i), buffer.readi8(hits, i + 1), buffer.readi8(hits, i + 2))
		local at = center + offset * Config.Cell
		local ore = Ores.list[buffer.readu8(hits, i + 3)]
		local box = markers[at]
		if not box then
			box = Instance.new("BoxHandleAdornment")
			box.Adornee, box.CFrame = terrain, terrain.CFrame:ToObjectSpace(CFrame.new(at))
			box.Size = Vector3.one * Config.Cell * 0.55
			box.AlwaysOnTop, box.ZIndex, box.Transparency = true, 1, 0.48
			box.Parent = gui
		end
		if box.Name ~= ore.name then
			box.Name, box.Color3 = ore.name, ore.color:Lerp(Color3.new(1, 1, 1), 0.18)
		end
		nextMarkers[at] = box
	end
	for at, box in markers do
		if not nextMarkers[at] then
			box:Destroy()
		end
	end
	markers = nextMarkers
	updateCount(buffer.len(hits) / 4)
end

local function poll(token)
	while token == session and badge.Visible do
		local character = player.Character
		if character and net:GetAttribute("Ready") then
			local clearAtRequest = lastClear
			local ok, nextRevision, center, hits = pcall(scan.InvokeServer, scan, revision)
			if token ~= session then
				return
			end
			if
				ok
				and nextRevision
				and lastClear == clearAtRequest
				and player.Character == character
				and net:GetAttribute("Ready")
			then
				show(center, hits)
				revision = nextRevision
			elseif ok and nextRevision == false then
				clear()
			end
		end
		task.wait(0.4)
	end
end
player.CharacterRemoving:Connect(clear)
net:GetAttributeChangedSignal("Ready"):Connect(function()
	if not net:GetAttribute("Ready") then
		clear()
	end
end)
Input.InputBegan:Connect(function(key, processed)
	if processed or key.KeyCode ~= Enum.KeyCode.X or Input:GetFocusedTextBox() then
		return
	end
	session += 1
	badge.Visible = not badge.Visible
	clear()
	if badge.Visible then
		task.spawn(poll, session)
	end
end)
