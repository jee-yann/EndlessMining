local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Profile = require(script.Parent.Profile)
local Data = {}
local store
local function getStore()
	if not store then
		store = DSS:GetDataStore(Config.StoreName, if RunService:IsStudio() then "studio" else "live")
	end
	return store
end

local function copy(p)
	return {
		version = p.version,
		gold = p.gold,
		mined = p.mined,
		xp = p.xp,
		title = p.title,
		skills = table.clone(p.skills),
		counts = table.clone(p.counts),
		recentCuts = table.clone(p.recentCuts),
		earned = table.clone(p.earned),
		claimedJobs = p.claimedJobs,
		pet = p.pet,
		petName = p.petName,
		bestDepth = p.bestDepth,
		levels = table.clone(p.levels),
		preferences = table.clone(p.preferences),
		bag = table.clone(p.bag),
		jobs = p.jobs,
		discoveries = table.clone(p.discoveries),
		viewed = table.clone(p.viewed),
	}
end

-- Public lifetime score only. Reading a leaderboard must never claim a save lease.
function Data.readDepth(userId)
	local record = getStore():GetAsync("miner_" .. userId)
	if type(record) == "table" and type(record.profile) == "table" and type(record.profile.bestDepth) == "number" then
		return if record.profile.counts == nil
			then math.floor(record.profile.bestDepth / 4)
			else Config.depthInBlocks(record.profile.bestDepth)
	end
	return nil
end

function Data.claim(old, token, now)
	if old ~= nil then
		if type(old) ~= "table" or not Profile.valid(old.profile) then
			return nil, "Unsupported save format"
		end
		if old.owner and old.owner ~= token then
			if type(old.expires) ~= "number" or old.expires > now then
				return nil, "Save open on another server"
			end
		end
	end
	return {
		profile = if old then Profile.upgradeSave(old.profile) else Profile.new(),
		owner = token,
		expires = now + Config.LeaseSeconds,
	}
end

function Data.commit(record, token, snapshot, now, release)
	if type(record) ~= "table" or record.owner ~= token then
		return nil
	end
	if release then
		return { profile = snapshot }
	end
	return { profile = snapshot, owner = token, expires = now + Config.LeaseSeconds }
end

function Data.open(player)
	local session = {
		key = "miner_" .. player.UserId,
		token = Http:GenerateGUID(false),
		profile = Profile.new(),
		writable = false,
		busy = false,
	}
	local detail = "Saving unavailable"
	-- Unpublished local places cannot use DataStores. Skip the network wait.
	if RunService:IsStudio() and (game.GameId == 0 or player.UserId <= 0) then
		player:SetAttribute("SaveStatus", "Practice session")
		return session
	end
	for attempt = 1, 3 do
		local ok, record = pcall(function()
			return getStore():UpdateAsync(session.key, function(old)
				local claimed, reason = Data.claim(old, session.token, os.time())
				detail = reason or detail
				return claimed
			end)
		end)
		if ok and record and record.owner == session.token then
			session.profile, session.writable = record.profile, true
			player:SetAttribute("SaveStatus", "Saving enabled")
			return session
		end
		if ok then
			break
		end
		detail = tostring(record)
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	warn("Endless Mining opened a temporary session for", player.UserId, detail)
	player:SetAttribute("SaveStatus", "Temporary session • progress unsaved")
	return session
end

function Data.save(player, session, release)
	if release then
		session.closing = true
		while session.busy do
			task.wait()
		end
	elseif session.closing or session.busy then
		return
	end
	if not session.writable then
		return
	end
	session.busy = true
	local snapshot = copy(session.profile)
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return getStore():UpdateAsync(session.key, function(record)
				return Data.commit(record, session.token, snapshot, os.time(), release)
			end)
		end)
		if ok then
			if not result then
				session.writable = false
				player:SetAttribute("SaveStatus", "Temporary session • progress unsaved")
				warn("Endless Mining lost save ownership for", player.UserId)
			else
				session.writable = not release
				player:SetAttribute("SaveStatus", "Saving enabled")
			end
			break
		end
		warn("Endless Mining save failed", player.UserId, result)
		player:SetAttribute("SaveStatus", "Save delayed")
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	session.busy = false
end
return Data
