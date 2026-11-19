local Players = game:GetService("Players")
local Market = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Catalog = require(game.ReplicatedStorage.Shared.PassCatalog)
local Passes = {}

local function equip(player, char)
	if not player:GetAttribute("PrismTrail") then
		return
	end
	local root = char:WaitForChild("HumanoidRootPart", 8)
	if not root or char ~= player.Character or root:FindFirstChild("Prism Ribbon") then
		return
	end
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position = Vector3.new(-0.62, 0.45, 0.65), Vector3.new(0.62, -0.35, 0.65)
	a.Parent, b.Parent = root, root
	local trail = Instance.new("Trail")
	trail.Name, trail.Attachment0, trail.Attachment1 = "Prism Ribbon", a, b
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 240, 255)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(169, 102, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 97, 159)),
	})
	trail.Transparency = NumberSequence.new(0.12, 1)
	trail.Lifetime, trail.LightEmission, trail.FaceCamera, trail.Parent = 0.55, 0.8, true, root
end
local function grant(player, item)
	if player.Parent ~= Players then
		return
	end
	player:SetAttribute(item.key, true)
	if item.key == "PrismTrail" and player.Character then
		task.spawn(equip, player, player.Character)
	end
end
function Passes.join(player)
	player.CharacterAdded:Connect(function(c)
		task.spawn(equip, player, c)
	end)
	for _, item in Catalog do
		if item.id <= 0 then
			continue
		end
		task.spawn(function()
			for attempt = 1, 3 do
				if player.Parent ~= Players then
					return
				end
				local ok, owns = pcall(Market.UserOwnsGamePassAsync, Market, player.UserId, item.id)
				if ok then
					if owns then
						grant(player, item)
					end
					return
				end
				task.wait(attempt * 2)
			end
		end)
	end
end
function Passes.preview(player, key)
	if not RunService:IsStudio() or (game.GameId ~= 0 and player.UserId > 0) then
		return
	end
	for _, item in Catalog do
		if item.key == key and item.id == 0 then
			grant(player, item)
		end
	end
end
Market.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
	if not bought then
		return
	end
	for _, item in Catalog do
		if item.id > 0 and item.id == id then
			grant(player, item)
		end
	end
end)
return Passes
