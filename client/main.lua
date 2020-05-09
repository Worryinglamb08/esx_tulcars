ESX = nil

PlayerData = {}
emptySlots = {}

local refreshing = false
Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)

        TriggerEvent("esx:getSharedObject", function(response)
            ESX = response
        end)
    end

    if ESX.IsPlayerLoaded() then
		PlayerData = ESX.GetPlayerData()
		RemoveVehicles()
		Citizen.Wait(1000)
		SpawnVehicles()
		SpawnFlyingVehicle()
		Citizen.Wait(1000)
		LoadSellPlace()
		CreateBlip()
    end

end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
	PlayerData = ESX.GetPlayerData()
	RemoveVehicles()
	Citizen.Wait(1000)	
	SpawnVehicles()	
	SpawnFlyingVehicle()
	Citizen.Wait(1000)
	LoadSellPlace()
	CreateBlip()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent("esx_tulcars:refreshVehicles")
AddEventHandler("esx_tulcars:refreshVehicles", function()
	RemoveVehicles()
	Citizen.Wait(1000)
	SpawnVehicles()
	Citizen.Wait(500)
	LoadSellPlace()
end)

function CreateBlip()
	local SellPos = Config.BlipLocation
	local Blip = AddBlipForCoord(SellPos["x"], SellPos["y"], SellPos["z"])
	SetBlipSprite (Blip, 488)
	SetBlipDisplay(Blip, 4)
	SetBlipScale  (Blip, 1.0)
	SetBlipColour (Blip, 59)
	SetBlipCategory(blip, 3)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Tulcars LP")
	EndTextCommandSetBlipName(Blip)
	SetBlipAsShortRange(Blip, true)	
end

function LoadSellPlace()
	emptySlots = {}
	local loaded = false
	while not loaded do
		ESX.TriggerServerCallback("esx_tulcars:retrieveVehicles", function(vehicles)
			for i = 1, #vehicles, 1 do
				if string.len(vehicles[i]["seller"]) > 1 then			
					table.insert(emptySlots, {["id"] = nil})
				else
					table.insert(emptySlots, {["id"] = i})
				end
			end
		end)	
		loaded = true
	end
	Citizen.CreateThread(function()		
		while true do
			local sleepThread = 500
			if refreshing then
				Citizen.Wait(1500)
				refreshing = false
			end
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			local dstCheck
			for i = 1, #Config.VehiclePositions, 1 do
				if emptySlots[i] ~= nil and emptySlots[i]["id"] ~= nil then
					dstCheck = GetDistanceBetweenCoords(pedCoords, Config.VehiclePositions[i]["x"], Config.VehiclePositions[i]["y"], Config.VehiclePositions[i]["z"], true)
					if dstCheck <= 15.0 then
						sleepThread = 5
						DrawMarker(1, Config.VehiclePositions[i]["x"], Config.VehiclePositions[i]["y"], Config.VehiclePositions[i]["z"], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.2, 255, 255, 255, 255, false, true, 2, false, false, false, false)
					end
					if dstCheck <= 3.0 then
						local temp1 =  Config.VehiclePositions[i]["z"]+2.0
						local temp = vector3(Config.VehiclePositions[i]["x"], Config.VehiclePositions[i]["y"], temp1)
						temp1 = temp1 + 0.5
						ESX.Game.Utils.DrawText3D(temp, "~g~[E] ~y~ Wystaw auto ~r~(500$/dzień postoju)" , 1.0)		
						temp = vector3(Config.VehiclePositions[i]["x"], Config.VehiclePositions[i]["y"], temp1)
						ESX.Game.Utils.DrawText3D(temp, "[SLOT" .. i .. "]" , 1.0)								
					end
					if dstCheck <= 3.0 then
						if IsControlJustPressed(0, 38) then
							if IsPedInAnyVehicle(ped, false) then
								local vehicleProperties = ESX.Game.GetVehicleProperties(GetVehiclePedIsIn(ped, false))
								ESX.TriggerServerCallback("esx_tulcars:IsVehiclePlayerProperty", function(callback)
									if callback then
										OpenSellMenu(GetVehiclePedIsIn(ped, false), i)											
									else
										ESX.ShowNotification("To auto ~r~nie~w~ należy do Ciebie!")				
									end
								end, vehicleProperties["plate"])
							else
								ESX.ShowNotification("Musisz siedzieć w ~g~aucie~s~!")
							end
						end
					end
				elseif Config.VehiclePositions[i]["entityId"] ~= nil then
					local vehCoords = GetEntityCoords(Config.VehiclePositions[i]["entityId"])
					dstCheck = GetDistanceBetweenCoords(pedCoords, vehCoords, true)
					if dstCheck <= 5.0 then
						sleepThread = 5
						local temp1 = vehCoords.z+1.5
						local temp = vector3(vehCoords.x, vehCoords.y, temp1)
						
						ESX.Game.Utils.DrawText3D(temp, "~g~[E] ~y~" .. Config.VehiclePositions[i]["price"] .. " ~g~$", 1.5)
						if IsPedInVehicle(ped, Config.VehiclePositions[i]["entityId"], true) then	
							if IsControlJustPressed(0, 38) then
								OpenBuyMenu(i)
							end
						end
					end
				end				
			end
			Citizen.Wait(sleepThread)
		end
	end)
end
function OpenBuyMenu(id)
	ESX.TriggerServerCallback("esx_tulcars:GetInfoAboutVehicle", function(vehicle)
		local seller = vehicle[1]["seller"]
		local vehProps = vehicle[1]["vehProps"]
		local price = vehicle[1]["price"]
		local isOwner = vehicle[1]["isOwner"]
		local elements = {}
		if isOwner then
			table.insert(elements, { ["label"] = '<span style="color:green">Anuluj ofertę', ["value"] = "cancel" })	
		else
			table.insert(elements, { ["label"] = 'Cena pojazu: <span style="color:green">'.. price .. '</span> $', ["value"] = "price" })
			table.insert(elements, { ["label"] = '<span style="color:yellow">Kup pojazd</span>', ["value"] = "accept" })				
			if vehProps.modBrakes ~= nil then
				table.insert(elements, { ["label"] = '<span style="color:white">' .. vehProps.modBrakes .. '</span> : Hamulce'})
			end
			
			if vehProps.modEngine ~= nil then
				table.insert(elements, { ["label"] = '<span style="color:white">' .. vehProps.modEngine .. '</span> : Silnik'})
			end
			
			if vehProps.modSuspension ~= nil then
				table.insert(elements, { ["label"] = '<span style="color:white">' .. vehProps.modSuspension .. '</span> : Zawieszenie'})
			end	
			
			if vehProps.modTransmission ~= nil then
				table.insert(elements, { ["label"] = '<span style="color:white">' .. vehProps.modTransmission .. '</span> : Skrzynia'})
			end	
			
			if vehProps.modTurbo ~= nil then
				local printText
				if vehProps.modTurbo == true then
					printText = "TAK"
				else
					printText = "NIE"
				end
				table.insert(elements, { ["label"] = '<span style="color:white">' .. printText .. '</span> : Turbo'})
			end					
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_veh',
			{
				title    = "Tulcars LP",
				align    = 'left',
				elements = elements
			},
		function(data, menu)
			local action = data.current.value

			if action == "accept" then
				ESX.TriggerServerCallback("esx_tulcars:BuyVehicle", function(valid)
					if valid then
						local VehPos = Config.VehiclePositions
						DeleteVehicle(VehPos[id]["entityId"])
						ESX.ShowNotification("Zakupiłeś pojazd za " .. price .. " $!")
						menu.close()
					else
						ESX.ShowNotification("~r~Niepowodzenie.")
						menu.close()
					end
		
				end, id)
			elseif action == "cancel" then
				ESX.TriggerServerCallback("esx_tulcars:Cancel", function(completed)
					if completed then
						DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
						ESX.ShowNotification("Anulowałeś ofertę sprzedaży!")
						menu.close()
					else
						ESX.ShowNotification("~r~Niepowodzenie.")
						menu.close()
					end
				end, id)
			end
		end, function(data, menu)
			menu.close()
		end)			
	end, id)
end
function OpenSellMenu(veh, id, price)
	local elements = {}
	local vehProps = ESX.Game.GetVehicleProperties(veh)

	if price then
		table.insert(elements, { ["label"] = '<span style="color:red"> >> <span style="color:green">Zmień cenę -' .. price .. ' $ <span style="color:red"><<</span>', ["value"] = "price" })
		table.insert(elements, { ["label"] = '<span style="color:red"> >> <span style="color:green">Zaakceptuj <span style="color:red"><<</span>', ["value"] = "accept" })	
	else 
		table.insert(elements, { ["label"] = '<span style="color:cyan"> Za postawienie auta : <span style="color:green">300$<span style="color:cyan">. Co 24h : <span style="color:green">500$<span style="color:cyan">.</span>', ["value"] = ""})	
		table.insert(elements, { ["label"] = '<span style="color:red"> >> <span style="color:green">Ustaw cenę.<span style="color:red"> << </span>', ["value"] = "price"})
	end
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_veh',
		{
			title    = "Tulcars LP",
			align    = 'left',
			elements = elements
		},
	function(data, menu)
		local action = data.current.value

		if action == "price" then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_veh_price',
				{
					title = "Ustaw cenę:"
				},
			function(data2, menu2)

				local vehPrice = tonumber(data2.value)

				menu2.close()
				menu.close()

				OpenSellMenu(veh, id, vehPrice)
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif action == "accept" then
			ESX.TriggerServerCallback("esx_tulcars:TryToCreateOffer", function(valid)
				if valid then
					DeleteVehicle(veh)
					TeleportPlayerToCoords()
					ESX.ShowNotification("Wystawiłeś ~g~pojazd~s~ na sprzedaż - " .. price .. " $")
					menu.close()
				else
					ESX.ShowNotification("~r~Niepowodzenie.")
				end
	
			end, vehProps, price, id)
		end
	end, function(data, menu)
		menu.close()
	end)	
end

TeleportPlayerToCoords = function()
	local TeleportCoords = Config.TeleportLocation
	Teleport(TeleportCoords)	
end

function Teleport(table)
	DoScreenFadeOut(100)
	Citizen.Wait(750)
	ESX.Game.Teleport(PlayerPedId(), table)
	DoScreenFadeIn(100)
end

function RemoveVehicles()
	emptySlots = {}
	local VehPos = Config.VehiclePositions
	for i = 1, #VehPos, 1 do
		local veh, distance = ESX.Game.GetClosestVehicle(VehPos[i])

		if DoesEntityExist(veh) and distance <= 2.0 then
			DeleteVehicle(veh)
		end
	end
end

function SpawnFlyingVehicle()
	local VehPos = Config.FlyingCarLocation
	local vehicleProps = vehicles
	LoadModel('schafter5')
	vehicle = CreateVehicle('schafter5', VehPos["x"], VehPos["y"], VehPos["z"], VehPos["a"], false)
	SetEntityRotation(vehicle, 25.0, 20.0, -25.0, 1, true)
	FreezeEntityPosition(vehicle, true)
	SetEntityAsMissionEntity(vehicle, true, true)
	SetModelAsNoLongerNeeded('schafter5')
	SetEntityInvincible(vehicle, true)		
end

function SpawnVehicles()
	local VehPos = Config.VehiclePositions
	refreshing = true
	ESX.TriggerServerCallback("esx_tulcars:retrieveVehicles", function(vehicles)
		for i = 1, #vehicles, 1 do
			if string.len(vehicles[i]["seller"]) > 1 then
				local vehicleProps = vehicles[i]["vehProps"]

				LoadModel(vehicleProps["model"])

				VehPos[i]["entityId"] = CreateVehicle(vehicleProps["model"], VehPos[i]["x"], VehPos[i]["y"], VehPos[i]["z"] + 0.800, VehPos[i]["a"], false)
				FreezeEntityPosition(VehPos[i]["entityId"], true)
				VehPos[i]["price"] = vehicles[i]["price"]
				VehPos[i]["owner"] = vehicles[i]["owner"]

				ESX.Game.SetVehicleProperties(VehPos[i]["entityId"], vehicleProps)

				FreezeEntityPosition(VehPos[i]["entityId"], true)

				SetEntityAsMissionEntity(VehPos[i]["entityId"], true, true)
				SetModelAsNoLongerNeeded(vehicleProps["model"])	
				SetEntityInvincible(VehPos[i]["entityId"], true)				
	--			table.insert(emptySlots, {["id"] = nil})
			else
	--			table.insert(emptySlots, {["id"] = i})
			end
		end
	end)
end

LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)

		Citizen.Wait(1)
	end
end
