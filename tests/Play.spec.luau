-- Temporary test drivers are inserted only into this CLI test's in-memory place.
local previousTestMute = game.ReplicatedStorage:GetAttribute("MuteTestMusic")
game.ReplicatedStorage:SetAttribute("MuteTestMusic", true)
local function driver(class, parent, source)
	local s = Instance.new(class)
	s.Name, s.Source, s.Parent = "MiningPlaytest", source, parent
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
report.Name="MiningTestReport"
report.Parent=rep
local done={}
report.OnServerEvent:Connect(function(player,stage,detail)
	local n=rep.EndlessMiningNet
	if stage=="position" then
		local char=player.Character
		local x=if player.UserId%2==0 then -3.25 else 1.5
		char:PivotTo(CFrame.new(n:GetAttribute("Origin")+Vector3.new(x,4,-8)))
		char.HumanoidRootPart.Anchored=true
	elseif stage=="depthSample" then
		local root=player.Character.HumanoidRootPart
		root.Anchored=true
		root.CFrame=CFrame.new(n:GetAttribute("Origin")+Vector3.new(-1,-108.5,-9))
	elseif stage=="openPage" then
		n.Feedback:FireClient(player,"page",detail)
	elseif stage=="station" then
		local island=workspace.CitrineCove
		local positions={Sell=island["Shore market"].Sell["Service mat"],Gear=island["Shore market"].Upgrades["Service mat"],Store=island["Harbor Plaza"].Store.Counter, Book=island["Harbor Plaza"].Book.Counter}
		if positions[detail] then
			player.Character:PivotTo(CFrame.new(positions[detail].Position+Vector3.yAxis*3))
			player.Character.HumanoidRootPart.Anchored=true
		end
	elseif stage=="closePage" then
		n.Feedback:FireClient(player,"close")
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
local r=rep:WaitForChild("MiningTestReport")
local function waitFor(check,seconds,msg)
	local start=os.clock()
	repeat if check() then return end task.wait(.08) until os.clock()-start>seconds
	error(msg)
end
local function test()
	local n=rep:WaitForChild("EndlessMiningNet",25)
	assert(n,"server bootstrap")
	waitFor(function() return n:GetAttribute("Ready") and p:GetAttribute("ProfileReady") and p.Character and p.Character:FindFirstChild("Head") end,30,"profile/world readiness")
	local gui=p.PlayerGui:WaitForChild("MiningHUD",10)
	assert(gui and gui.SafeArea:FindFirstChild("ShopOverlay"),"HUD did not mount")
	waitFor(function() return workspace:FindFirstChild("MiningSelection") end,8,"aim controller did not start")
	assert(p:GetAttribute("SaveStatus")=="Practice session","local data scope")
	waitFor(function() return p.Character:FindFirstChild("Harbor pick") end,8,"equipped pickaxe")
	local harbor=game.SoundService:WaitForChild("Harbor audio",8)
	local song=harbor:WaitForChild("Prima Bossa Nova",5)
	assert(not song.IsPlaying and song.Volume < 0.1,"test music must stay muted")
	waitFor(function() return gui:GetAttribute("ControllerReady") and not p.PlayerGui:FindFirstChild("MiningLoading") end,18,"loading screen dismisses")
	local mount=p.Character.HumanoidRootPart:FindFirstChild("Lamp mount")
	assert(mount and mount:FindFirstChildOfClass("PointLight") and p.Character:GetAttribute("MiningViewReady"),"spawn camera and character light on reveal")
	local gallery=workspace.CitrineCove["Citrine Mine"]:FindFirstChild("Gallery glow")
	assert(gallery and gallery:FindFirstChildOfClass("PointLight"),"gallery lighting on reveal")
	local audio=require(p.PlayerScripts.Client.HarborAudio)
	for _,voice in harbor:GetChildren() do if voice==song then continue end waitFor(function() return voice.IsLoaded end,8,voice.Name.." failed to load") end
	if r:GetAttribute("CheckSwing") then
		local seenIds={}
		for _,ore in require(rep.Shared.Ores).list do
			local voice=harbor[ore.name.." break"]
			assert(not seenIds[voice.SoundId], "duplicate ore sound")
			seenIds[voice.SoundId]=true
			local played,notes=false,0
			local strike=voice.Played:Connect(function() played=true end)
			local flourishes={}
			for i=1,3 do
				table.insert(flourishes,harbor["Discovery note "..i].Played:Connect(function() notes+=1 end))
			end
			audio.ore({[ore.name]=1})
			waitFor(function() return played and notes==math.max(0,ore.hardness-3) end,2,ore.name.." break and reward notes")
			strike:Disconnect()
			for _,signal in flourishes do signal:Disconnect() end
		end
	end
	local car=workspace.CitrineCove["Citrine Highlands"]["Moving cabins"]["Ore carrier 1"]
	local start=car:GetPivot().Position
	waitFor(function() return (car:GetPivot().Position-start).Magnitude>.12 end,4,"tram movement")
	local overlay=gui.SafeArea.ShopOverlay
	local menu=overlay["Harbor menu"]
	local map=workspace.CitrineCove
	local counters={Sell=map["Shore market"].Sell["Service mat"],Gear=map["Shore market"].Upgrades["Service mat"],Store=map["Harbor Plaza"].Store.Counter,Book=map["Harbor Plaza"].Book.Counter}
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
	for _,page in {"Pack","Settings","Gear","Jobs","Book","Store"} do
		if counters[page] then visit(page,true) else r:FireServer("openPage",page) end
		local listing=({Settings="Music volume",Gear="Speed",Jobs="First strike",Book="Stone",Pack="Stone",Store="Double Gold"})[page]
		waitFor(function() return overlay.Visible and menu.Listings:FindFirstChild(listing) end,5,"open "..page)
		if page=="Book" then
			assert(menu.Listings["Iron Shelf"].Depth.Text=="27 blocks","index depth in blocks")
		end
		task.wait(.26)
		local left,top=menu.AbsolutePosition.X,menu.AbsolutePosition.Y
		local safe=gui.SafeArea
		assert(left>=safe.AbsolutePosition.X-1 and top>=safe.AbsolutePosition.Y-1,"menu origin")
		assert(menu.AbsoluteSize.X<=safe.AbsoluteSize.X+1 and menu.AbsoluteSize.Y<=safe.AbsoluteSize.Y+1,"menu bounds")
	end
	r:FireServer("closePage")
	waitFor(function() return not overlay.Visible end,5,"close")
	if not r:GetAttribute("CheckSwing") then
		r:FireServer("depthSample")
		local location=gui.SafeArea.Location
		waitFor(function()
			return location.Coordinates.Text=="X -1    Y -27    Z -3" and location.Depth.Text=="27 blocks"
				and location.Region.Text=="IRON SHELF" and p.leaderstats.Depth.Value==27
		end,8,"block coordinates, region and personal best at Iron Shelf")
		assert(location.Coordinates.TextFits and location.Depth.TextFits,"location readout clipped")
	end
	r:FireServer("position")
	local origin=n:GetAttribute("Origin")
	waitFor(function()
		local pos=p.Character.Head.Position-origin
		return pos.Z<0 and math.abs(pos.Y-5)<4
	end,8,"placement at starter seam")
	local first=os.clock()
	local discovered
	n.Feedback.OnClientEvent:Connect(function(kind,title,name)
		if kind=="milestone" then
			if title=="ORE DISCOVERED" then discovered=name end
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
		r:FireServer("openPage","Settings")
		waitFor(function() return overlay.Visible and menu.Listings:FindFirstChild("Music volume") end,4,"settings")
		task.wait(.3)
		local function clickAt(xy)
			input:SendMousePosition(xy); task.wait(.07)
			input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,true);task.wait(.07)
			input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,false);task.wait(.07)
		end
		local function adjust(row,value,key,group)
			local track=menu.Listings[row].Slider.Track
			local xy=track.AbsolutePosition+track.AbsoluteSize*Vector2.new(value/100,.5)+game:GetService("GuiService"):GetGuiInset()
			clickAt(xy)
			waitFor(function() return p:GetAttribute(key)==value and math.abs(group.Volume-value/100)<.011 end,2,row.." slider")
		end
		adjust("Music volume",0,"MusicVolume",song.SoundGroup)
		assert(harbor["Coal break"].SoundGroup.Volume>.5,"music muted effects")
		adjust("Sound effects",23,"SfxVolume",harbor["Coal break"].SoundGroup)
		assert(song.SoundGroup.Volume==0,"effects changed music")
		adjust("Music volume",55,"MusicVolume",song.SoundGroup)
		adjust("Sound effects",80,"SfxVolume",harbor["Coal break"].SoundGroup)
		r:FireServer("closePage")
		waitFor(function() return not overlay.Visible end,2,"animated close")
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
		local cursor=p.PlayerGui.MiningAim["Mining cursor"]
		assert(cursor.Visible and not cursor["No entry"].Visible, "mineable cursor")
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
		assert(workspace.MiningSelection:FindFirstChild("Fractures") and #workspace.MiningSelection.Fractures:GetChildren()>=1, "visible impact cracks")
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
		local popup
		waitFor(function() popup=workspace.Terrain:FindFirstChild("Ore find");return popup and popup:FindFirstChild("Ore popup") end,2,"world ore popup")
		assert((popup.WorldPosition-aim).Magnitude<2.1 and popup["Ore popup"].TextLabel.Text=="+1 Coal","popup location and label")
		waitFor(function() return not popup.Parent end,2,"popup fades out")
		camera.CFrame=CFrame.lookAt(head.Position+Vector3.new(2,1,3),origin+Vector3.new(10,6,-26))
		waitFor(function() return cursor.Visible and cursor["No entry"].Visible end,5,"locked copper cursor")
		local collected=p:GetAttribute("Used")
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,true)
		task.wait(.85)
		input:SendMouseButton(xy,Enum.UserInputType.MouseButton1,false)
		assert(p:GetAttribute("Used")==collected and not meter.Visible and not workspace.MiningSelection:FindFirstChild("Fractures"),"locked ore started a cut")
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
		local part=pattern.visiblePart(head.Position,center,hit.Normal,params)
		local selected=pattern.select(origin,center,part and ores.byName[part.Name],1,36-p:GetAttribute("Used"))
		if #selected==1 then n.Mine:FireServer(center,hit.Normal,count,2^count-1) end
	end
	for i=1,650 do
		dig(i,1)
		if p:GetAttribute("Used")==36 then break end
		task.wait(.12)
	end
	assert(p:GetAttribute("Used")==36,"starter pack incomplete: "..tostring(p:GetAttribute("Used")))
	waitFor(function() return discovered end,4,"first ore discovery")
	local value=p:GetAttribute("BagValue")
	assert(value>=36,"material valuation")
	local quantity,total=0,0
	for _,ore in ores.list do
		local held=p:GetAttribute("Held"..ore.name)
		if held>0 then assert(gui.SafeArea.Haul[ore.name].Visible and gui.SafeArea.Haul[ore.name].Quantity.Text=="×"..held,"live haul row") end
		quantity+=held
		total+=held*ore.value
	end
	assert(quantity==36 and total==value,"pack quantities and value")
	n.Action:FireServer("Sell")
	task.wait(.4)
	assert(p:GetAttribute("Used")==36 and p:GetAttribute("Gold")==0,"exchange must require a visit")
	visit("Sell",true)
	waitFor(function() return gui.SafeArea:FindFirstChild("Sale receipt") end,4,"sale payout")
	waitFor(function() return p:GetAttribute("Gold")==value and p:GetAttribute("Used")==0 end,6,"exchange")
	for _,ore in ores.list do assert(p:GetAttribute("Held"..ore.name)==0) end
	n.Action:FireServer("Buy","Capacity")
	task.wait(.4)
	assert(p:GetAttribute("Capacity")==1 and p:GetAttribute("Gold")==value,"workshop must require a visit")
	visit("Gear",true)
	n.Action:FireServer("Buy","Capacity")
	task.wait(.28)
	if p:GetAttribute("Capacity")==1 then n.Action:FireServer("Buy","Capacity") end
	waitFor(function() return p:GetAttribute("Capacity")==2 and p:GetAttribute("Gold")==value-24 end,5,"purchase")
	r:FireServer("position")
	waitFor(function() return (p.Character.Head.Position-origin).Z<0 and not overlay.Visible end,5,"leave workshop")
	for i=1,6 do dig(i,2) task.wait(.12) end
	assert(p:GetAttribute("Used")==0,"multi-block request was accepted")
	for i=1,100 do
		if p:GetAttribute("Used")==2 then break end
		dig(i,1)
		task.wait(.14)
	end
	assert(p:GetAttribute("Used")==2,"single-block mining after upgrade")
	assert(p:GetAttribute("Found"..discovered) and p:GetAttribute("Mined")==38,"ore discovery and lifetime blocks")
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
	r:FireServer("depthSample")
	waitFor(function() return gui.SafeArea.Location.Depth.Text=="27 blocks" end,4,"return starting depth")
	n.Action:FireServer("Surface")
	local passage=p.PlayerGui.SurfaceReturn
	waitFor(function() return passage.Enabled end,2,"surface fade begins")
	local departed=os.clock()
	local landing=n:GetAttribute("Entrance")
	waitFor(function() return (p.Character.HumanoidRootPart.Position-landing).Magnitude<8 end,5,"surface recall")
	waitFor(function() return not passage.Enabled end,6,"surface fade completed")
	assert(os.clock()-departed>.6 and not song.IsPlaying,"depth travel and test mute")
	return string.format("38 blocks, %d gold sale, larger pack, physical ore index, settings, entrance return (%.1fs)",value,os.clock()-first)
end
local ok,result=pcall(test)
r:FireServer(if ok then "passed" else "failed",tostring(result))
]==]
)
local studio = game:GetService("StudioTestService")
local ok, why = pcall(function()
	local swing = studio:ExecutePlayModeAsync("Pick swing")
	print("MINING_SWING_RESULT", swing)
	assert(type(swing) == "string" and string.sub(swing, 1, 4) == "PASS", tostring(swing))
	local outcome = studio:ExecuteMultiplayerTestAsync(2, "CitrineCove")
	print("MINING_PLAYTEST_RESULT", outcome)
	assert(type(outcome) == "string" and string.sub(outcome, 1, 4) == "PASS", tostring(outcome))
end)
game.ReplicatedStorage:SetAttribute("MuteTestMusic", previousTestMute)
assert(ok, why)
