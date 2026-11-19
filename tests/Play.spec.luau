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
	waitFor(function() return p.PlayerGui:FindFirstChild("BrushRadius",true) end,8,"aim controller did not start")
	assert(p:GetAttribute("SaveStatus")=="Practice session","local data scope")
	r:FireServer("position")
	local origin=n:GetAttribute("Origin")
	waitFor(function() return (p.Character.Head.Position-origin).Z<0 end,8,"placement")
	local first=os.clock()
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace.Terrain}
	local head=p.Character.Head
	local directions={Vector3.new(0,-1,0),Vector3.new(0,-.45,-1),Vector3.new(-.6,-.5,-.6),Vector3.new(.6,-.4,-.6),Vector3.new(0,.1,-1)}
	for i=1,240 do
		local hit=workspace:Raycast(head.Position,directions[i%#directions+1].Unit*33,params)
		if hit then n.Mine:FireServer(hit.Position) end
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
	task.wait(.25)
	n.Action:FireServer("Surface")
	local landing=n:GetAttribute("Landing")
	waitFor(function() return (p.Character.HumanoidRootPart.Position-landing).Magnitude<8 end,5,"surface recall")
	return string.format("36 ore, %d gold sale, radius 5→7, surface recall (%.1fs)",value,os.clock()-first)
end
local ok,result=pcall(test)
r:FireServer(if ok then "passed" else "failed",tostring(result))
]==]
)
local outcome = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "CitrineCove")
print("QUARRY_PLAYTEST_RESULT", outcome)
assert(type(outcome) == "string" and string.sub(outcome, 1, 4) == "PASS", tostring(outcome))
