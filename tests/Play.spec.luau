-- Temporary test drivers are inserted only into this CLI test's in-memory place.
local function driver(class, parent, source)
	local s = Instance.new(class)
	s.Name, s.Source, s.Parent = "QuarryPlaytest", source, parent
end
driver(
	"Script",
	game:GetService("ServerScriptService"),
	[==[
local rep=game:GetService("ReplicatedStorage")
local test=game:GetService("StudioTestService")
local completed=false
local function finish(result)
	if not completed then completed=true test:EndTest(result) end
end
task.delay(110,function() finish("FAIL: playtest timeout") end)
local report=Instance.new("RemoteEvent")
report.Name="QuarryTestReport"
report.Parent=rep
local done={}
report.OnServerEvent:Connect(function(player,stage,detail)
	local n=rep.EndlessMiningNet
	if stage=="position" then
		local char=player.Character
		local x=if player.UserId%2==0 then -3 else 4
		char:PivotTo(CFrame.new(n:GetAttribute("Origin")+Vector3.new(x,4,-8)))
		char.HumanoidRootPart.Anchored=true
	elseif stage=="passed" then
		done[player]=detail
		local results={}
		for who,msg in done do table.insert(results,who.Name.." "..msg) end
		if #results==2 then finish("PASS "..table.concat(results," / ")) end
	elseif stage=="failed" then finish("FAIL "..player.Name.." "..detail) end
end)
]==]
)
driver(
	"LocalScript",
	game:GetService("StarterPlayer").StarterPlayerScripts,
	[==[
local rep=game:GetService("ReplicatedStorage")
local p=game.Players.LocalPlayer
local r=rep:WaitForChild("QuarryTestReport")
local function waitFor(check,seconds,msg)
	local start=os.clock()
	repeat if check() then return end task.wait(.08) until os.clock()-start>seconds
	error(msg)
end
local function test()
	local n=rep:WaitForChild("EndlessMiningNet",25)
	assert(n,"server bootstrap")
	waitFor(function() return n:GetAttribute("Ready") and p:GetAttribute("ProfileReady") and p.Character and p.Character:FindFirstChild("Head") end,30,"profile/world readiness")
	local gui=p.PlayerGui:WaitForChild("QuarryHUD",10)
	assert(gui and gui.SafeArea:FindFirstChild("ShopOverlay"),"HUD did not mount")
	waitFor(function() return workspace:FindFirstChild("MiningSelection") end,8,"aim controller did not start")
	assert(p:GetAttribute("SaveStatus")=="Practice session","local data scope")
	r:FireServer("position")
	local origin=n:GetAttribute("Origin")
	waitFor(function() return (p.Character.Head.Position-origin).Z<0 end,8,"placement")
	local first=os.clock()
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace.CitrineCove:WaitForChild("MineBlocks")}
	local head=p.Character.Head
	local config=require(rep.Shared.GameConfig)
	local pattern=require(rep.Shared.BlockPattern)
	local ores=require(rep.Shared.Ores)
	local directions={}
	for x=-3,3 do
		for y=-3,1 do table.insert(directions,Vector3.new(x*.21,y*.25,-1).Unit) end
	end
	table.insert(directions,-Vector3.yAxis)
	local function dig(i,count)
		local hit=workspace:Raycast(head.Position,directions[i%#directions+1]*33,params)
		if not hit then return end
		local center=config.blockCenter(origin,hit.Position,hit.Normal)
		local _,mask=pattern.select(origin,center,hit.Normal,count,1,36-p:GetAttribute("Used"),nil,function(pos)
			local part=pattern.visiblePart(head.Position,pos,hit.Normal,params)
			return if part then ores.byName[part.Name] else nil
		end)
		if mask==2^count-1 then n.Mine:FireServer(center,hit.Normal,count,mask) end
	end
	for i=1,650 do
		dig(i,1)
		if p:GetAttribute("Used")==36 then break end
		task.wait(.12)
	end
	assert(p:GetAttribute("Used")==36,"starter pack incomplete: "..tostring(p:GetAttribute("Used")))
	local value=p:GetAttribute("BagValue")
	assert(value>=72,"ore valuation")
	n.Action:FireServer("Sell")
	waitFor(function() return p:GetAttribute("Gold")==value and p:GetAttribute("Used")==0 end,6,"exchange")
	n.Action:FireServer("Buy","Radius")
	task.wait(.28)
	if p:GetAttribute("Radius")==1 then n.Action:FireServer("Buy","Radius") end
	waitFor(function() return p:GetAttribute("Radius")==2 and p:GetAttribute("Gold")==value-24 end,5,"purchase")
	for i=1,90 do
		if p:GetAttribute("Used")==2 then break end
		if p:GetAttribute("Used")==0 then dig(i,2) end
		task.wait(.12)
	end
	assert(p:GetAttribute("Used")==2,"the 2x1 upgrade should mine both highlighted cells")
	task.wait(.25)
	n.Action:FireServer("Surface")
	local landing=n:GetAttribute("Landing")
	waitFor(function() return (p.Character.HumanoidRootPart.Position-landing).Magnitude<8 end,5,"surface recall")
	return string.format("36 ore, %d gold sale, area 1×1→2×1, surface recall (%.1fs)",value,os.clock()-first)
end
local ok,result=pcall(test)
r:FireServer(if ok then "passed" else "failed",tostring(result))
]==]
)
local outcome = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "CitrineCove")
print("QUARRY_PLAYTEST_RESULT", outcome)
assert(type(outcome) == "string" and string.sub(outcome, 1, 4) == "PASS", tostring(outcome))
