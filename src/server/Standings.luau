local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Data = require(script.Parent.DataService)
local Standings = {}

function Standings.top(scores, levels)
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
		lines[i] = if levels
			then string.format("%d.   %s     ·     Lv %d", i, row.name, row.score)
			else string.format("%d.   %s     ·     %d blocks", i, row.name, row.score)
	end
	return lines, rows
end

local function draw(board, scores, levels, empty)
	local lines, rows = Standings.top(scores, levels)
	local face = board.Standings.Lettering
	for i = 1, 5 do
		face["Row" .. i].Text = lines[i] or (if i == 1 then empty else "")
	end
	for i = 1, 3 do
		local podium = board["Podium " .. i]
		local row = rows[i]
		podium:SetAttribute("StandingName", row and row.name)
		podium:SetAttribute(if levels then "StandingLevel" else "StandingDepth", row and row.score)
		podium:SetAttribute("StandingId", row and row.id)
	end
end

local function refreshGlobal(board, names)
	local ok, page = pcall(Data.globalDepths)
	if not ok then
		board.Standings.Lettering.Title.Text = "GLOBAL RECORDS OFFLINE"
		if not board["Podium 1"]:GetAttribute("StandingId") then
			board.Standings.Lettering.Row1.Text = "Checking again shortly"
		end
		return
	end
	local scores, missing, currentNames = {}, {}, {}
	for _, record in page do
		local id = tonumber(record.key)
		if id and id > 0 then
			local player = Players:GetPlayerByUserId(id)
			currentNames[id] = if player then player.DisplayName else names[id]
			if not currentNames[id] then
				table.insert(missing, id)
			end
			scores[id] = { score = record.value }
		end
	end
	if #missing > 0 then
		local resolved, users = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, missing)
		if resolved then
			for _, user in users do
				currentNames[user.Id] = user.DisplayName
			end
		end
	end
	table.clear(names)
	for id, row in scores do
		names[id] = currentNames[id]
		row.name = names[id] or ("Miner #" .. id)
	end
	board.Standings.Lettering.Title.Text = "DEEPEST DESCENT"
	draw(board, scores, false, "No depth records yet")
end

function Standings.start(court)
	local practice = RunService:IsStudio() and game.GameId == 0
	court.Server.Standings.Lettering.Title.Text = "HIGHEST LEVEL"
	if practice then
		court.Global.Standings.Lettering.Title.Text = "PRACTICE DEPTHS"
	else
		task.spawn(function()
			local names = {}
			while true do
				refreshGlobal(court.Global, names)
				task.wait(60)
			end
		end)
	end
	task.spawn(function()
		while true do
			local levels, depths = {}, {}
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("ProfileReady") then
					levels[player.UserId] = { name = player.DisplayName, score = player:GetAttribute("Level") or 1 }
					if practice and player.leaderstats.Depth.Value > 0 then
						depths[player.UserId] = { name = player.DisplayName, score = player.leaderstats.Depth.Value }
					end
				end
			end
			draw(court.Server, levels, true, "Waiting for miners")
			if practice then
				draw(court.Global, depths, false, "Mine deeper to set a record")
			end
			task.wait(2)
		end
	end)
end
return Standings
