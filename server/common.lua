ESX = {}
ESX.Game = {}
ESX.Players = {}
ESX.UsableItemsCallbacks = {}
ESX.Items = {}
ESX.ServerCallbacks = {}
ESX.TimeoutCount = -1
ESX.CancelledTimeouts = {}
ESX.Pickups = {}
ESX.PickupId = 0
ESX.Jobs = {}
ESX.RegisteredCommands = {}
local n, nn, nnn = 0, 0, 0

AddEventHandler('esx:getSharedObject', function(cb) cb(ESX) end)

exports('getSharedObject', function() return ESX end)

function ConfigLoad()
	local items, jobs, grades = Shared.Items, Shared.Jobs, Shared.Grades

	for k,v in ipairs(items) do
		ESX.Items[v.name] = {
			label = v.label,
			weight = v.weight,
			rare = v.rare,
			canRemove = v.can_remove
		}
		n=n+1
	end

	for k,v in ipairs(jobs) do
		ESX.Jobs[v.name] = v
		ESX.Jobs[v.name].grades = {}
		nn=nn+1
	end

	for k,v in ipairs(grades) do
		if ESX.Jobs[v.job_name] then
			ESX.Jobs[v.job_name].grades[tostring(v.grade)] = v
			n=n+1
		else
			print(('[ESX] [^3WARNING^7] Ignoring job grades for "%s" due to missing job'):format(v.job_name))
		end
	end

	for k,v in pairs(ESX.Jobs) do
		if next(v2.grades) == 0 then
			ESX.Jobs[v2.name] = nil
			print(('[ESX] [^3WARNING^7] Ignoring job "%s" due to no job grades found'):format(v2.name))
		end
	end

	local oneSyncStatus = GetConvar('onesync', 'default_false')

	if oneSyncStatus ~= 'on' then
		if oneSyncStatus == 'legacy' then
			print('[ESX] [^3WARNING^7] OneSync is currently set to ^8legacy^7. You are probably using the ' ..
				'"^4+set onesync_enabled 1^7" command line argument in your server start file. ' ..
				'Change it to "^4+set onesync on^7". This new OneSync mode fixes hair colour syncing, ' ..
				'and has better overall performance.')
		else
			print('[ESX] [^3WARNING^7] OneSync is disabled! Important features such as spawning cars are not going to work!')
		end
	end

	print('[ESX] [^2INFO^7] Fetched ^4' .. n .. ' ^0items, ^4' .. nn .. ' ^0jobs and ^4' .. nnn .. ' ^0grades from config')
	print('[ESX] [^2INFO^7] Initialized')
end

function BasicLoad()
	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for k,v in ipairs(result) do
			ESX.Items[v.name] = {
				label = v.label,
				weight = v.weight,
				rare = v.rare,
				canRemove = v.can_remove
			}
		end
	end)

	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs)
		for k,v in ipairs(jobs) do
			ESX.Jobs[v.name] = v
			ESX.Jobs[v.name].grades = {}
		end

		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(jobGrades)
			for k,v in ipairs(jobGrades) do
				if ESX.Jobs[v.job_name] then
					ESX.Jobs[v.job_name].grades[tostring(v.grade)] = v
				else
					print(('[ESX] [^3WARNING^7] Ignoring job grades for "%s" due to missing job'):format(v.job_name))
				end
			end

			for k2,v2 in pairs(ESX.Jobs) do
				if ESX.Table.SizeOf(v2.grades) == 0 then
					ESX.Jobs[v2.name] = nil
					print(('[ESX] [^3WARNING^7] Ignoring job "%s" due to no job grades found'):format(v2.name))
				end
			end
		end)
	end)

	print('[ESX] [^2INFO^7] Initialized - Fetched from the database')
	local oneSyncStatus = GetConvar('onesync', 'default_false')

	if oneSyncStatus ~= 'on' then
		if oneSyncStatus == 'legacy' then
			print('[ESX] [^3WARNING^7] OneSync is currently set to ^8legacy^7. You are probably using the ' ..
				'"^4+set onesync_enabled 1^7" command line argument in your server start file. ' ..
				'Change it to "^4+set onesync on^7". This new OneSync mode fixes hair colour syncing, ' ..
				'and has better overall performance.')
		else
			print('[ESX] [^3WARNING^7] OneSync is disabled! Important features such as spawning cars are not going to work!')
		end
	end
end

if ESX.GetConfig().FetchFromConfig then
	ConfigLoad()
else
	BasicLoad()
end

RegisterNetEvent('esx:clientLog')
AddEventHandler('esx:clientLog', function(msg)
	if Config.EnableDebug then
		print(('[ESX] [^2TRACE^7] %s^7'):format(msg))
	end
end)

RegisterNetEvent('esx:triggerServerCallback')
AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	ESX.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('esx:serverCallback', playerId, requestId, ...)
	end, ...)
end)