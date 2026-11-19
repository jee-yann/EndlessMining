local First = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name, gui.DisplayOrder, gui.ResetOnSpawn, gui.ScreenInsets = "QuarryLoading", 100, false, Enum.ScreenInsets.None
local cover = Instance.new("CanvasGroup")
cover.Name, cover.BackgroundColor3, cover.BorderSizePixel = "Cover", Color3.fromRGB(27, 43, 63), 0
cover.Size, cover.Active, cover.Parent = UDim2.fromScale(1, 1), true, gui
local function line(text, y, size, tint)
	local label = Instance.new("TextLabel")
	label.Text, label.Font, label.TextSize, label.TextColor3 = text, Enum.Font.FredokaOne, size, tint
	label.BackgroundTransparency, label.AnchorPoint, label.Size = 1, Vector2.new(0.5, 0.5), UDim2.new(1, -16, 0, 48)
	label.Position, label.Parent = UDim2.new(0.5, 0, 0.5, y), cover
	return label
end
line("Citrine Cove", -25, 36, Color3.fromRGB(255, 213, 119))
local status = line("Opening the quarry…", 20, 18, Color3.fromRGB(206, 237, 231))
gui.Parent = parent
First:RemoveDefaultLoadingScreen()
local start = os.clock()
repeat
	local net = Rep:FindFirstChild("EndlessMiningNet")
	local hud = parent:FindFirstChild("QuarryHUD")
	local island = workspace:FindFirstChild("CitrineCove")
	local grid = island and island:FindFirstChild("MineBlocks")
	local ready = game:IsLoaded()
		and workspace.CurrentCamera
		and player.Character
		and player.Character:FindFirstChild("HumanoidRootPart")
		and Lighting:FindFirstChild("SeaAir")
		and Lighting:FindFirstChild("MarketGlow")
		and grid
		and grid:FindFirstChildWhichIsA("BasePart")
		and net
		and net:GetAttribute("Ready")
		and hud
		and hud:GetAttribute("ControllerReady")
		and player:GetAttribute("ProfileReady")
	if ready then
		break
	end
	if net and net:GetAttribute("Ready") then
		status.Text = "Getting your gear ready…"
	end
	task.wait(0.05)
until os.clock() - start > 15
Run.RenderStepped:Wait()
local fade = Tween:Create(cover, TweenInfo.new(0.28), { GroupTransparency = 1 })
fade:Play()
fade.Completed:Wait()
gui:Destroy()
