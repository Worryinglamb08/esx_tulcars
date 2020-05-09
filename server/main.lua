ESX = nil

TriggerEvent("pz:getSharedObject", function(response)
    ESX = response
end)

local VehiclesForSale = 0

ESX.RegisterServerCallback("pz_tulcars:retrieveVehicles", function(source, cb)
    MySQL.Async.fetchAll("SELECT id, seller, vehicleProps, price FROM tulcars_cars", {}, function(result)
        local vehicleTable = {}

        VehiclesForSale = 0

        if result[1] ~= nil then
            for i = 1, #result, 1 do
                VehiclesForSale = VehiclesForSale + 1
                table.insert(vehicleTable, { ["id"] = result[i]["id"], ["price"] = result[i]["price"], ["vehProps"] = json.decode(result[i]["vehicleProps"]), ["seller"] = result[i]["seller"]})
            end
        end
        cb(vehicleTable)
    end)
end)

ESX.RegisterServerCallback("pz_tulcars:IsVehiclePlayerProperty", function(source, cb, plate)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local isPlayerProperty = false

	RetrievePlayerVehicles(xPlayer.identifier, function(ownedVehicles)
		for id, v in pairs(ownedVehicles) do
			if v.plate == plate then
				isPlayerProperty = true
				break
			end		
		end
		cb(isPlayerProperty)	
	end)
end)

ESX.RegisterServerCallback("pz_tulcars:TryToCreateOffer", function(source, cb, vehicleProps, price, placeID)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local plate = vehicleProps["plate"]
	local isFound = false
	RetrievePlayerVehicles(xPlayer.identifier, function(ownedVehicles)

		for id, v in pairs(ownedVehicles) do
                MySQL.Async.execute("UPDATE tulcars_cars SET seller = @sellerIdentifier, vehicleProps = @vehProps, price = @vehPrice WHERE id = @id",
                    {
						["@sellerIdentifier"] = xPlayer["identifier"],
                        ["@vehProps"] = json.encode(vehicleProps),
                        ["@vehPrice"] = price,
						["@id"] = placeID
                    }
                )
  
				MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', { ["@plate"] = plate})
                TriggerClientEvent("pz_tulcars:refreshVehicles", -1)
				if xPlayer.getMoney() < 300 then
					xPlayer.removeAccountMoney('bank', 300)
				else
					xPlayer.removeMoney(300)
				end			
				TriggerEvent('pz_addonaccount:getSharedAccount', 'society_cardealer', function(account)
					account.addMoney(300)
				end)				
				isFound = true
				break
		end
		cb(isFound)
	end)
end)

ESX.RegisterServerCallback("pz_tulcars:GetInfoAboutVehicle", function(source, cb, id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    
    MySQL.Async.fetchAll("SELECT seller, vehicleProps, price FROM tulcars_cars WHERE id = @id", {["@id"] = id}, function(result)
        local vehicleTable = {}
		local owner = false
        if result[1] ~= nil then
			if result[1]["seller"] == xPlayer.identifier then
				owner = true
			end
			
			table.insert(vehicleTable, {["price"] = result[1]["price"], ["vehProps"] = json.decode(result[1]["vehicleProps"]), ["seller"] = result[1]["seller"], ["isOwner"] = owner})
        end

        cb(vehicleTable)
    end)
end)

ESX.RegisterServerCallback("pz_tulcars:Cancel", function(source, cb, id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local completed = false
    MySQL.Async.fetchAll("SELECT seller, vehicleProps FROM tulcars_cars WHERE id = @id", {["@id"] = id}, function(result)
        if result[1] ~= nil then
			if result[1]["seller"] == xPlayer.identifier then
                MySQL.Async.execute("UPDATE tulcars_cars SET seller = 0, vehicleProps = 0, price = 0 WHERE id = @id",
                    {
						["@id"] = id
                    }
                )
                MySQL.Async.execute("INSERT INTO owned_vehicles (owner, vehicle, type, state, plate) VALUES (@sellerIdentifier, @vehProps, @type, @stored, @plate)",
                    {
						["@sellerIdentifier"] = xPlayer["identifier"],
                        ["@vehProps"] = result[1]["vehicleProps"],
                        ["@type"] = "car",
						["@stored"] = 1,
						["@plate"] = json.decode(result[1]["vehicleProps"]).plate,
                    }
                )	
                TriggerClientEvent("pz_tulcars:refreshVehicles", -1)				
				completed = true
			end

        end

        cb(completed)
    end)
end)

ESX.RegisterServerCallback("pz_tulcars:Cancel", function(source, cb, id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local completed = false
    MySQL.Async.fetchAll("SELECT seller, vehicleProps FROM tulcars_cars WHERE id = @id", {["@id"] = id}, function(result)
        if result[1] ~= nil then
			if result[1]["seller"] == xPlayer.identifier then
                MySQL.Async.execute("UPDATE tulcars_cars SET seller = 0, vehicleProps = 0, price = 0 WHERE id = @id",
                    {
						["@id"] = id
                    }
                )
                MySQL.Async.execute("INSERT INTO owned_vehicles (owner, vehicle, type, state, plate) VALUES (@sellerIdentifier, @vehProps, @type, @stored, @plate)",
                    {
						["@sellerIdentifier"] = xPlayer["identifier"],
                        ["@vehProps"] = result[1]["vehicleProps"],
                        ["@type"] = "car",
						["@stored"] = 1,
						["@plate"] = json.decode(result[1]["vehicleProps"]).plate,
                    }
                )	
                TriggerClientEvent("pz_tulcars:refreshVehicles", -1)				
				completed = true
			end

        end

        cb(completed)
    end)
end)

function RetrievePlayerVehicles(newIdentifier, cb)
	local identifier = newIdentifier

	local yourVehicles = {}

	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @identifier", {['@identifier'] = identifier}, function(result) 

		for id, values in pairs(result) do

			local vehicle = json.decode(values.vehicle)
			local plate = values.plate

			table.insert(yourVehicles, { vehicle = vehicle, plate = plate })
		end

		cb(yourVehicles)

	end)
end

function UpdateCash(identifier, cash)
	local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

	if xPlayer ~= nil then
        xPlayer.addMoney(cash)

		TriggerClientEvent("pz:showNotification", xPlayer.source, "~g~[KOMIS]~s~ Ktoś kupił Twoje auto. Zysk: ~g~" .. cash .. "~s~$")
	else
		MySQL.Async.fetchAll('SELECT bank FROM users WHERE identifier = @identifier', { ["@identifier"] = identifier }, function(result)
			if result[1]["bank"] ~= nil then
				MySQL.Async.execute("UPDATE users SET bank = @newBank WHERE identifier = @identifier",
					{
						["@identifier"] = identifier,
						["@newBank"] = result[1]["bank"] + cash
					}
				)
			end
		end)
	end
end

ESX.RegisterServerCallback("pz_tulcars:BuyVehicle", function(source, cb, id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local seller = 0
	local vehicleProps = {}
	local price = 0
	local done = false
    MySQL.Async.fetchAll("SELECT seller, vehicleProps, price FROM tulcars_cars WHERE id = @id", {["@id"] = id}, function(result)
        if result[1] ~= nil then
			seller = result[1]["seller"]
			vehicleProps = result[1]["vehicleProps"]
			price = result[1]["price"]
			
			if xPlayer.getMoney() >= price or price == 0 then
				xPlayer.removeMoney(price)
				UpdateCash(seller, price)			
                MySQL.Async.execute("UPDATE tulcars_cars SET seller = 0, vehicleProps = 0, price = 0 WHERE id = @id", {
						["@id"] = id
				})
				MySQL.Async.execute('INSERT INTO owned_vehicles (plate, owner, vehicle, state) VALUES (@plate, @identifier, @vehicleProps, @state)',
					{
						["@plate"] = json.decode(result[1]["vehicleProps"]).plate,
						["@identifier"] = xPlayer["identifier"],
						["@vehicleProps"] = vehicleProps,
						["@state"] = 1			
					}
				)	
				TriggerClientEvent("pz_tulcars:refreshVehicles", -1)
				done = true
			end
        end
	cb(done, id)		
    end)	
end)

function PayRent(d, h, m)
	MySQL.Async.fetchAll('SELECT * FROM tulcars_cars WHERE price > 0', {}, function (result)
		for i=1, #result, 1 do
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i]["seller"])
			if xPlayer then
				xPlayer.removeAccountMoney('bank', 500)
				TriggerClientEvent('pz:showNotification', xPlayer.source, _U('paid_rent', 500))
			else
				MySQL.Sync.execute('UPDATE users SET bank = bank - @bank WHERE identifier = @identifier', {
					['@bank']       = 500,
					['@identifier'] = result[i]["seller"]
				})
			end

			TriggerEvent('pz_addonaccount:getSharedAccount', 'society_cardealer', function(account)
				account.addMoney(500)
			end)
		end
	end)
end

TriggerEvent('cron:runAt', 10, 0, PayRent)