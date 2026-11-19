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
local inputTest=test:GetTestArgs()=="Pick swing"
report:SetAttribute("CheckSwing",inputTest)
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
	elseif stage=="openPage" then
		n.Feedback:FireClient(player,"page",detail)
	elseif stage=="station" then
		local island=workspace.CitrineCove
		local positions={Sell=island["Shore market"].Sell["Service mat"],Gear=island["Shore market"].Upgrades["Service mat"],Store=island["Harbor Plaza"].Store.Counter}
		if positions[detail] then
			player.Character:PivotTo(CFrame.new(positions[detail].Position+Vector3.yAxis*3))
			player.Character.HumanoidRootPart.Anchored=true
		end
	elseif stage=="closePage" then
		n.Feedback:FireClient(player,"travel","Citrine Harbor")
	elseif stage=="passed" then
		done[player]=detail
		local results={}
		for who,msg in done do table.insert(results,who.Name.." "..msg) end
		if #results==(if inputTest then 1 else 2) then finish("PASS "..table.concat(results," / ")) end
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
	waitFor(function() return p.Character:FindFirstChild("Harbor pick") end,8,"equipped pickaxe")
	local harbor=game.SoundService:WaitForChild("Harbor audio",8)
	local song=harbor:WaitForChild("Another 8 Bit Game",5)
	waitFor(function() return song.IsLoaded and song.IsPlaying and song.TimePosition>.1 end,20,"soundtrack playback")
	local audio=require(p.PlayerScripts.Client.HarborAudio)
	assert(audio.toggleMusic()==false)
	waitFor(function() return not song.IsPlaying end,3,"music pause")
	assert(audio.toggleMusic()==true)
	waitFor(function() return song.IsPlaying and song.Volume>.1 end,3,"music resume")
	for _,voice in harbor:GetChildren() do waitFor(function() return voice.IsLoaded end,8,voice.Name.." failed to load") end
	local car=workspace.CitrineCove["Citrine Highlands"]["Moving cabins"]["Ore carrier 1"]
	local start=car:GetPivot().Position
	waitFor(function() return (car:GetPivot().Position-start).Magnitude>.12 end,4,"tram movement")
	local overlay=gui.SafeArea.ShopOverlay
	local menu=overlay["Harbor menu"]
	local map=workspace.CitrineCove
	local counters={Sell=map["Shore market"].Sell["Service mat"],Gear=map["Shore market"].Upgrades["Service mat"],Store=map["Harbor Plaza"].Store.Counter}
	local function visit(key,activate)
		local pad=counters[key]
		r:FireServer("station",key)
		waitFor(function() return (p.Character.HumanoidRootPart.Position-pad.Position).Magnitude<7 end,5,"walk to "..key)
		if activate then
			task.wait(.25)
			pad.Service:InputHoldBegin()
			task.wait(pad.Service.HoldDuration+.15)
			pad.Service:InputHoldEnd()
		end
	end
	for _,page in {"Pack","Lift","Gear","Jobs","Book","Store"} do
		if counters[page] then visit(page,true) else r:FireServer("openPage",page) end
		local listing=({Lift="Citrine Harbor",Gear="Mining area",Jobs="First strike",Book="Stone",Pack="Stone",Store="Double Gold"})[page]
		waitFor(function() return overlay.Visible and menu.Listings:FindFirstChild(listing) end,5,"open "..page)
		local left,top=menu.AbsolutePosition.X,menu.AbsolutePosition.Y
		local safe=gui.SafeArea
		assert(left>=safe.AbsolutePosition.X-1 and top>=safe.AbsolutePosition.Y-1,"menu origin")
		assert(menu.AbsoluteSize.X<=safe.AbsoluteSize.X+1 and menu.AbsoluteSize.Y<=safe.AbsoluteSize.Y+1,"menu bounds")
	end
	r:FireServer("closePage")
	waitFor(function() return not overlay.Visible end,5,"close")
	r:FireServer("position")
	local origin=n:GetAttribute("Origin")
	waitFor(function() return (p.Character.Head.Position-origin).Z<0 end,8,"placement")
	local first=os.clock()
	local discovered,unlocked
	n.Feedback.OnClientEvent:Connect(function(kind,title,name)
		if kind=="milestone" then
			if title=="ORE DISCOVERED" then discovered=name end
			if title=="LIFT UNLOCKED" then unlocked=name end
		end
	end)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace.CitrineCove:WaitForChild("MineBlocks")}
	local head=p.Character.Head
	local config=require(rep.Shared.GameConfig)
	local pattern=require(rep.Shared.BlockPattern)
	local ores=require(rep.Shared.Ores)
	if r:GetAttribute("CheckSwing") then
		local camera=workspace.CurrentCamera
		local input=game:GetService("UserInputService"):CreateVirtualInput()
		assert(input,"Studio virtual input unavailable")
		local hand=p.Character:FindFirstChild("RightHand") or p.Character:FindFirstChild("Right Arm")
		local defaultY=hand.Position.Y
		local hit=workspace:Raycast(head.Position,Vector3.new(0,0,-32),params)
		assert(hit,"starter wall")
		local aim=config.blockCenter(origin,hit.Position,hit.Normal)
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(head.Position+Vector3.new(4,1.5,7),aim)
		local xy=camera.ViewportSize*.5
		input:SendMousePosition(xy)
		local meter=gui.SafeArea.Feedback["Mining progress"]
		local function outlined()
			local marker=workspace.MiningSelection:FindFirstChild("Selected block")
			if not marker or (marker:GetPivot().Position-aim).Magnitude>.02 or #marker:GetChildren()~=12 then return false end
			for _,edge in marker:GetChildren() do
				if not edge:IsA("BasePart") or edge.CanQuery or edge.CanCollide then return false end
			end
			return true
		end
		waitFor(outlined,4,"depth-tested borders on the selected cell")
		assert(game:GetService("StarterPlayer").LoadCharacterAppearance,"account appearance disabled")
		local pick=p.Character["Harbor pick"]
		local palm=hand:FindFirstChild("RightGripAttachment")
		local function gripError()
			local expected=if palm then palm.WorldPosition else hand.CFrame:PointToWorldSpace(Vector3.new(0,-hand.Size.Y*.4,0))
			return (pick["Grip tape"].Position-expected).Magnitude
		end
		assert(gripError()<.035,"idle hand grip")
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,true)
		waitFor(function() return meter.Visible and meter.Charge.Size.X.Scale>.1 and hand.Position.Y>defaultY+.4 end,3,"raised pick and progress")
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,false)
		waitFor(function() return not meter.Visible and math.abs(hand.Position.Y-defaultY)<.48 end,3,"cancelled swing")
		assert(p:GetAttribute("Used")==0,"early release spent a block")
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,true)
		local peaks,high,maxGap,replicated=0,false,0,false
		local deadline=os.clock()+3
		repeat
			game:GetService("RunService").PostSimulation:Wait()
			maxGap=math.max(maxGap,gripError())
			replicated=replicated or p.Character:GetAttribute("MiningSwing")~=nil
			local rise=hand.Position.Y-defaultY
			if not high and rise>.9 then
				high=true
				peaks+=1
			elseif high and rise<.5 then
				high=false
			end
		until p:GetAttribute("Used")>=1 or os.clock()>deadline
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,false)
		assert(p:GetAttribute("Used")==1,"completed cut")
		assert(peaks>=2,"expected repeated swings during the first cut, saw "..peaks)
		assert(maxGap<.035,"grip drift: "..maxGap)
		assert(replicated,"swing start was not replicated")
		waitFor(function() return not p.Character:GetAttribute("MiningSwing") end,3,"replicated swing release")
		return string.format("depth-tested faces, %d swings in one cut, grip error %.4f studs, early release",peaks,maxGap)
	end
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
	waitFor(function() return discovered and unlocked=="Ember Foundry" end,4,"ore and lift notifications")
	local value=p:GetAttribute("BagValue")
	assert(value>=72,"ore valuation")
	local quantity,total=0,0
	for _,ore in ores.list do
		local held=p:GetAttribute("Held"..ore.name)
		quantity+=held
		total+=held*ore.value
	end
	assert(quantity==36 and total==value,"pack quantities and value")
	n.Action:FireServer("Sell")
	task.wait(.4)
	assert(p:GetAttribute("Used")==36 and p:GetAttribute("Gold")==0,"exchange must require a visit")
	visit("Sell",true)
	waitFor(function() return p:GetAttribute("Gold")==value and p:GetAttribute("Used")==0 end,6,"exchange")
	for _,ore in ores.list do assert(p:GetAttribute("Held"..ore.name)==0) end
	n.Action:FireServer("Buy","Radius")
	task.wait(.4)
	assert(p:GetAttribute("Radius")==1 and p:GetAttribute("Gold")==value,"workshop must require a visit")
	visit("Gear",true)
	n.Action:FireServer("Buy","Radius")
	task.wait(.28)
	if p:GetAttribute("Radius")==1 then n.Action:FireServer("Buy","Radius") end
	waitFor(function() return p:GetAttribute("Radius")==2 and p:GetAttribute("Gold")==value-24 end,5,"purchase")
	r:FireServer("position")
	waitFor(function() return (p.Character.Head.Position-origin).Z<0 and not overlay.Visible end,5,"leave workshop")
	for i=1,90 do
		if p:GetAttribute("Used")==2 then break end
		if p:GetAttribute("Used")==0 then dig(i,2) end
		task.wait(.12)
	end
	assert(p:GetAttribute("Used")==2,"the 2x1 upgrade should mine both highlighted cells")
	assert(p:GetAttribute("OreIndex")>0 and p:GetAttribute("Mined")==38,"ore discovery and lifetime blocks")
	n.Action:FireServer("Job",1)
	waitFor(function() return p:GetAttribute("Jobs")==1 end,5,"first reward")
	local afterJob=p:GetAttribute("Gold")
	assert(afterJob==value-24+25)
	task.wait(.25)
	n.Action:FireServer("Job",1)
	task.wait(.3)
	assert(p:GetAttribute("Gold")==afterJob,"repeat claim")
	visit("Store",true)
	n.Action:FireServer("PreviewPass","DoubleGold")
	waitFor(function() return p:GetAttribute("DoubleGold") end,5,"studio pass preview")
	local double=p:GetAttribute("BagValue")*2
	visit("Sell",true)
	waitFor(function() return p:GetAttribute("Gold")==afterJob+double end,5,"double sale")
	visit("Store",true)
	n.Action:FireServer("PreviewPass","PrismTrail")
	waitFor(function() return p.Character.HumanoidRootPart:FindFirstChild("Prism Ribbon") end,5,"equipped trail")
	n.Action:FireServer("Travel","Foundry")
	local foundry=require(rep.Shared.Expeditions).byKey.Foundry.floor+origin
	waitFor(function() return (p.Character.HumanoidRootPart.Position-foundry).Magnitude<10 end,5,"foundry lift")
	task.wait(.3)
	n.Action:FireServer("Travel","Deep")
	task.wait(.4)
	assert((p.Character.HumanoidRootPart.Position-foundry).Magnitude<10,"locked vault")
	task.wait(.25)
	n.Action:FireServer("Surface")
	local landing=n:GetAttribute("Landing")
	waitFor(function() return (p.Character.HumanoidRootPart.Position-landing).Magnitude<8 end,5,"surface recall")
	return string.format("38 ore, %d gold sale, area 1×1→2×1, six menus, jobs, both passes, lift gates, recall (%.1fs)",value,os.clock()-first)
end
local ok,result=pcall(test)
r:FireServer(if ok then "passed" else "failed",tostring(result))
]==]
)
local studio = game:GetService("StudioTestService")
local swing = studio:ExecutePlayModeAsync("Pick swing")
print("QUARRY_SWING_RESULT", swing)
assert(type(swing) == "string" and string.sub(swing, 1, 4) == "PASS", tostring(swing))
local outcome = studio:ExecuteMultiplayerTestAsync(2, "CitrineCove")
print("QUARRY_PLAYTEST_RESULT", outcome)
assert(type(outcome) == "string" and string.sub(outcome, 1, 4) == "PASS", tostring(outcome))
