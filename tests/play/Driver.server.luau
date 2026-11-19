local rep = game:GetService("ReplicatedStorage")
local test = game:GetService("StudioTestService")
local mode = rep:GetAttribute("MiningTestMode")
local completed = false
local function finish(result)
	if not completed then
		completed = true
		local marker = if mode == "Swing" then "MINING_SWING_RESULT " else "MINING_PLAYTEST_RESULT "
		print(marker .. result .. " [" .. rep:GetAttribute("MiningTestRun") .. "]")
		test:EndTest(result)
	end
end
task.delay(180, function()
	finish("FAIL: playtest timeout")
end)
local report = Instance.new("RemoteEvent")
local inputTest = mode == "Swing"
report:SetAttribute("CheckSwing", inputTest)
report.Name = "MiningTestReport"
report.Parent = rep
local done = {}
report.OnServerEvent:Connect(function(player, stage, detail)
	local n = rep.EndlessMiningNet
	if stage == "gateApproach" then
		local char = player.Character
		char.HumanoidRootPart.Anchored = false
		char:PivotTo(CFrame.new(n:GetAttribute("Origin") + Vector3.new(0, 3, 2)))
	elseif stage == "position" then
		local char = player.Character
		local x = if player.UserId % 2 == 0 then -3.25 else 1.5
		char:PivotTo(CFrame.new(n:GetAttribute("Origin") + Vector3.new(x, -46.5, -12)))
		char.HumanoidRootPart.Anchored = true
	elseif stage == "depthSample" then
		local root = player.Character.HumanoidRootPart
		root.Anchored = true
		root.CFrame = CFrame.new(n:GetAttribute("Origin") + Vector3.new(-1, -46.5, -18))
	elseif stage == "walk" then
		player.Character.HumanoidRootPart.Anchored = false
	elseif stage == "openPage" then
		n.Feedback:FireClient(player, "page", detail)
	elseif stage == "station" then
		local island = workspace.CitrineCove
		local positions = {
			Sell = island["Shore market"].Sell["Service mat"],
			Gear = island["Shore market"].Upgrades["Service mat"],
			Store = island["Harbor Plaza"].Store.Counter,
			Book = island["Harbor Plaza"].Book.Counter,
		}
		if positions[detail] then
			player.Character:PivotTo(CFrame.new(positions[detail].Position + Vector3.yAxis * 3))
			player.Character.HumanoidRootPart.Anchored = true
		end
	elseif stage == "closePage" then
		n.Feedback:FireClient(player, "close")
	elseif stage == "passed" then
		done[player] = detail
		local results = {}
		for who, msg in done do
			table.insert(results, who.Name .. " " .. msg)
		end
		if #results == (if inputTest then 1 else 2) then
			finish("PASS " .. table.concat(results, " / "))
		end
	elseif stage == "failed" then
		finish("FAIL " .. player.Name .. " " .. detail)
	end
end)
