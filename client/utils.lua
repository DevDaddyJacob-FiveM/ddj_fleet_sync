local cache = {}
cache.hash = {}


function getHash(str)
    local hash = cache.hash[str]

    if not hash then
        hash = joaat(str)
        cache.hash[str] = hash
    end

    return hash
end


function getFleetEntryFromModelHash(modelHash)
    for fleetName, fleet in pairs(Config["VehicleFleets"]) do
        for i = 1, #fleet.vehicles do
            local vehicle = fleet.vehicles[i]

            if modelHash == getHash(vehicle) then
                return {
                    fleetName = fleetName,
                    fleet = fleet
                }
            end
        end
    end

    return nil
end


function getFleetEntryFromModelName(modelName)
    return getFleetEntryFromModelHash(getHash(modelName))
end


function getLightingExtrasForModelHash(fleet, modelHash)
    local result = {}

    for lightingName, data in pairs(fleet.lightingExtras) do
        local extra = nil

        -- Loop through the names in the data and try to find matching hash
        for modelName, extraData in pairs(data) do
            if modelHash == getHash(modelName) then
                extra = extraData.extra
                break                
            end
        end

        result[lightingName] = extra
    end

    return result
end


function getNearbyVehicles(coords, maxDistance)
	local ped = PlayerPedId()
	local playerVeh = GetVehiclePedIsIn(ped, false)
	local vehicles = GetGamePool("CVehicle")
	local nearby = {}
	local count = 0
	maxDistance = maxDistance or 2.0

	for i = 1, #vehicles do
		local vehicle = vehicles[i]

		if not playerVeh or vehicle ~= playerVeh then
			local vehicleCoords = GetEntityCoords(vehicle)
			local distance = #(coords - vehicleCoords)

			if distance < maxDistance then
				count += 1
				nearby[count] = {
					vehicle = vehicle,
					coords = vehicleCoords
				}
			end
		end
	end

	return nearby
end


function findFleetVehiclesInRange(fleet, excludedVehicleHandles)
    excluded = excluded or {}
    local vehicles = {}

    local fleetModelHashes = {}
    for i = 1, #fleetData.vehicles do
        table.insert(fleetModelHashes, getHash(fleetData.vehicles[i]))
    end
    
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)

    local nearby = getNearbyVehicles(pedCoords, Config["CommanderRadius"])
    for i = 1, #nearby do
        local vehHandle = nearby[i].vehicle
        local vehModelHash = GetEntityModel(vehHandle)

        if
            table.hasValue(fleetModelHashes, vehModelHash) == true
            and table.hasValue(excluded, vehHandle) == false
        then
            table.insert(vehicles, vehHandle)
        end
    end

    return vehicles
end