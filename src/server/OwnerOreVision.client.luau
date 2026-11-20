local Players = game:GetService("Players")
local Tags = game:GetService("CollectionService")
local Input = game:GetService("UserInputService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ores = require(shared:WaitForChild("Ores"))
local folderTag = require(shared:WaitForChild("GameConfig")).MineBlockTag
local player = Players.LocalPlayer
local gui = script.Parent
local playerGui = gui.Parent
local widgets = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Widgets"))
local location = playerGui:WaitForChild("MiningHUD"):WaitForChild("SafeArea"):WaitForChild("Location")
local surface = location:WaitForChild("Surface")
local badge = widgets.frame(location, "Ore vision status", 50, 52, 160, 23, widgets.ink, 8)
badge.Visible = false
local label = widgets.title(badge, "", 0, 0, 160, 23, 13, widgets.aqua)
local function placeBadge()
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, 0, 1, if surface.Visible then 52 else 4)
end
surface:GetPropertyChangedSignal("Visible"):Connect(placeBadge)
placeBadge()

local markers = {}
local count = 0
local added, removing
local function updateCount()
	label.Text = string.format("X-RAY  ·  %d %s loaded", count, if count == 1 then "ore" else "ores")
end
local function mark(part)
	local ore = Ores.byName[part.Name]
	if not ore or ore.host or markers[part] or not part:IsA("BasePart") then
		return
	end
	if not badge.Visible or not part:IsDescendantOf(workspace) or not part.Parent:HasTag(folderTag) then
		return
	end
	local box = Instance.new("BoxHandleAdornment")
	box.Name, box.Adornee, box.Size = ore.name, part, part.Size * 0.88
	box.AlwaysOnTop, box.ZIndex, box.Transparency = true, 1, 0.36
	box.Color3 = ore.color:Lerp(Color3.new(1, 1, 1), 0.18)
	box.Parent = gui
	markers[part] = box
	count += 1
	updateCount()
end
local function unmark(part)
	local box = markers[part]
	if box then
		box:Destroy()
		markers[part] = nil
		count -= 1
		updateCount()
	end
end
Input.InputBegan:Connect(function(key, processed)
	if
		processed
		or key.KeyCode ~= Enum.KeyCode.X
		or Input:GetFocusedTextBox()
		or playerGui:FindFirstChild("MiningLoading")
	then
		return
	end
	if badge.Visible then
		added:Disconnect()
		removing:Disconnect()
		badge.Visible = false
		for _, box in markers do
			box:Destroy()
		end
		table.clear(markers)
		count = 0
	else
		badge.Visible = true
		added = workspace.DescendantAdded:Connect(mark)
		removing = workspace.DescendantRemoving:Connect(unmark)
		for _, folder in Tags:GetTagged(folderTag) do
			if folder:IsDescendantOf(workspace) then
				for _, part in folder:GetChildren() do
					mark(part)
				end
			end
		end
		updateCount()
	end
end)
