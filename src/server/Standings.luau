local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local Data = require(script.Parent.DataService)
local Standings = {}

function Standings.top(scores)
	local rows = {}
	for id, entry in scores do
		table.insert(rows, { id = id, name = entry.name, score = entry.score })
	end
	table.sort(rows, function(a, b)
		return a.score > b.score or (a.score == b.score and a.id < b.id)
	end)
	local lines = {}
	for i = 1, math.min(5, #rows) do
		local row = rows[i]
		lines[i] = string.format("%d.   %s     ·     %d blocks", i, row.name, row.score)
	end
	return lines, rows
end

function Standings.start(court, event)
	local friends, cache = {}, {}
	local nextRead = 0
	local function scan(player, state)
		local function active()
			return player.Parent == Players and friends[player] == state
		end
		local ok = pcall(function()
			if player.UserId <= 0 then
				return
			end
			local pages = Players:GetFriendsAsync(player.UserId)
			repeat
				for _, friend in pages:GetCurrentPage() do
					state.names[friend.Id] = friend.DisplayName or friend.Username
				end
				if pages.IsFinished or not active() then
					break
				end
				pages:AdvanceToNextPageAsync()
			until false
			if not active() or player:GetAttribute("SaveStatus") ~= "Saving enabled" then
				return
			end
			for id in state.names do
				while active() and not state.near do
					task.wait(2)
				end
				if not active() then
					return
				end
				if Players:GetPlayerByUserId(id) then
					continue
				end
				local old = cache[id]
				if not old or os.clock() >= old.expires then
					while
						active()
						and (
							os.clock() < nextRead
							or DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync) < 8
						)
					do
						task.wait(0.35)
					end
					if not active() then
						return
					end
					nextRead = os.clock() + 0.25
					local loaded, score = pcall(Data.readDepth, id)
					if loaded then
						cache[id] = { score = score, expires = os.clock() + 600 }
					else
						state.partial = true
					end
				end
			end
		end)
		state.complete, state.partial = true, state.partial or not ok
		state.refresh = os.clock() + (if state.partial then 60 else 300)
	end
	Players.PlayerRemoving:Connect(function(player)
		friends[player] = nil
	end)
	task.spawn(function()
		while true do
			local scores = {}
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("ProfileReady") then
					scores[p.UserId] = { name = p.DisplayName, score = p.leaderstats.Depth.Value }
				end
			end
			local lines, ranked = Standings.top(scores)
			for rank = 1, 3 do
				local stand = court.Server["Podium " .. rank]
				local row = ranked[rank]
				stand:SetAttribute("StandingName", row and row.name)
				stand:SetAttribute("StandingDepth", row and row.score)
				stand:SetAttribute("StandingId", row and row.id)
			end
			for i = 1, 5 do
				court.Server.Standings.Lettering["Row" .. i].Text = lines[i]
					or (if i == 1 then "Waiting for miners" else "")
			end
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local near = root
					and math.min(
							(root.Position - court.Friends.Standings.Position).Magnitude,
							(root.Position - court.Server.Standings.Position).Magnitude
						)
						<= 34
				local state = friends[player]
				if state then
					state.near = near
				end
				if not near or not scores[player.UserId] then
					continue
				end
				if not state or (state.complete and os.clock() >= state.refresh) then
					state = { names = {}, near = true }
					friends[player] = state
					task.spawn(scan, player, state)
				end
				local personal = { [player.UserId] = { name = "You", score = scores[player.UserId].score } }
				for id, display in state.names do
					local value = scores[id] or cache[id]
					if value and value.score ~= nil then
						personal[id] = { name = display, score = value.score }
					end
				end
				local list, rankedFriends = Standings.top(personal)
				local note = if not state.complete
					then "Checking friends…"
					elseif state.partial then "Some scores unavailable"
					elseif player:GetAttribute("SaveStatus") ~= "Saving enabled" then "FRIENDS IN THIS SESSION"
					elseif #list == 1 then "No other miners ranked yet"
					else ""
				local signature = table.concat(list, "\n") .. note
				for i = 1, math.min(3, #rankedFriends) do
					signature ..= "/" .. rankedFriends[i].id
				end
				if state.last ~= signature then
					state.last = signature
					local winners = {}
					for i = 1, math.min(3, #rankedFriends) do
						winners[i] = rankedFriends[i]
					end
					event:FireClient(player, list, note, winners)
				end
			end
			for id, record in cache do
				if os.clock() > record.expires + 600 then
					cache[id] = nil
				end
			end
			task.wait(2)
		end
	end)
end
return Standings
