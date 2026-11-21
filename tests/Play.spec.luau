local test = game:GetService("StudioTestService")
local swing = game.ReplicatedStorage:GetAttribute("MiningTestMode") == "Swing"
local marker = if swing then "MINING_SWING_RESULT " else "MINING_PLAYTEST_RESULT "
local reported = false
local output = game:GetService("LogService").MessageOut:Connect(function(message)
	if message:sub(1, #marker) == marker then
		reported = true
	end
end)
local result
if swing then
	result = test:ExecutePlayModeAsync("Pick swing")
else
	result = test:ExecuteMultiplayerTestAsync(2, "CitrineCove")
end
if type(result) == "string" then
	print(marker .. result)
else
	-- Some Studio versions start Play asynchronously. Keep its Output open until
	-- the in-game driver can report completion, including the timeout case.
	local deadline = os.clock() + (if swing then 90 else 190)
	while not reported and os.clock() < deadline do
		task.wait(0.25)
	end
end
output:Disconnect()
