local canSync = false

function isNetVehicleCommanderAsync(vehNetId)
    logger:trace("invoked | isNetVehicleCommanderAsync(" .. vehNetId .. ") invoked")

    local awaitable = promise.new()

    rpc.invoke("DevJacob:FleetSync:Server:IsVehicleCommander", function(value)
        logger:trace(
            "resolved | isNetVehicleCommanderAsync(" .. vehNetId .. ") => %s",
            tostring(value)
        )
        
        awaitable:resolve(value)
    end, vehNetId)

    return awaitable
end


function getCommanderForNetVehicleAsync(vehNetId)
    logger:trace("invoked | getCommanderForNetVehicleAsync(" .. vehNetId .. ") invoked")

    local awaitable = promise.new()

    rpc.invoke("DevJacob:FleetSync:Server:GetCommanderForVehicle", function(value)
        logger:trace(
            "resolved | getCommanderForNetVehicleAsync(" .. vehNetId .. ") => %s",
            tostring(value)
        )
        
        awaitable:resolve(value)
    end, vehNetId)

    return awaitable
end


function markNetIdAsDead(vehNetId)
    logger:trace("invoked | markNetIdAsDead(%s)", tostring(vehNetId))

    TriggerServerEvent("DevJacob:FleetSync:Server:DeadNetworkId", vehNetId)
end


function releaseNetVehicleAsCommander(vehNetId)
    logger:trace("invoked | releaseNetVehicleAsCommander(%s)", tostring(vehNetId))

    TriggerServerEvent("DevJacob:FleetSync:Server:ReleaseVehicleAsCommander", vehNetId)
end


function syncNetVehicleToCommander(vehNetId, closestCommanderNetId)
    logger:trace(
        "invoked | syncNetVehicleToCommander(%s, %s)",
        tostring(vehNetId),
        tostring(closestCommanderNetId)
    )

    TriggerServerEvent(
        "DevJacob:FleetSync:Server:SyncVehicleToCommander",
        vehNetId,
        closestCommanderNetId
    )
end


function unsyncNetVehicleFromCommander(vehNetId)
    TriggerServerEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", vehNetId)
end


function registerNetVehicleAsCommander(vehNetId)
    TriggerServerEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", vehNetId)
end


RegisterNetEvent("DevJacob:FleetSync:Client:SyncVehicleNow", function(vehicleNetId, commanderNetId)
    logger:debug("attempting to sync to net ID " .. vehicleNetId)
    
    if
        not NetworkDoesEntityExistWithNetworkId(vehicleNetId)
        and not NetworkDoesEntityExistWithNetworkId(commanderNetId)
    then
        markNetIdAsDead(vehicleNetId)
        return
    end


    local vehicleHandle = NetToVeh(vehicleNetId)
    local commanderHandle = NetToVeh(commanderNetId)
    if not DoesEntityExist(vehicleHandle) and not DoesEntityExist(commanderHandle) then
        markNetIdAsDead(vehicleNetId)
        return
    end

    logger:info("syncing to net ID " .. vehicleNetId)

    local commanderModel = GetEntityModel(commanderHandle)
    local fleetEntry = getFleetEntryFromModelHash(commanderModel)

    -- If we mimic extras, do so now
    if fleetEntry.fleet.copyExtras == true and fleetEntry.fleet.lightingExtras then
        local commanderExtraMap = getLightingExtrasForModelHash(commanderModel, fleetEntry.fleet)
        local myExtraMap = getLightingExtrasForModelHash(
            GetEntityModel(vehicleHandle),
            fleetEntry.fleet
        )

        for lightingName, commanderExtra in pairs(commanderExtraMap) do
            local myExtra = myExtraMap[lightingName]

            if myExtra == nil then
                goto continue
            end

            if
                DoesExtraExist(commanderHandle, commanderExtra)
                and DoesExtraExist(vehicleHandle, myExtra)
            then
                SetVehicleExtra(
                    vehicleHandle,
                    myExtra,
                    not IsVehicleExtraTurnedOn(commanderHandle, commanderExtra)
                )
            end

            ::continue::
        end
    end

    SetVehicleSiren(vehicleHandle, false)
    SetVehicleSiren(vehicleHandle, true)
end)


-- Movement tracking thread
Citizen.CreateThread(function()
    local lastSyncEntity = nil
    local lastPos = vector3(0.0, 0.0, 0.0)
    local timeStill = 0

    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle == nil or lastSyncEntity ~= vehicle then
            lastSyncEntity = vehicle
            canSync = false
            goto continue
        end


        -- Check if the vehicle siren is on
        if IsVehicleSirenOn(vehicle) == false then
            canSync = false
            goto continue
        end

        -- Preset the last pos if it's 0, 0, 0
        if lastSyncEntity ~= vehicle then
            lastPos = GetEntityCoords(vehicle)
            timeStill = 0
        end

        -- Check if the vehicle is a fleet vehicle
        local fleetEntry = getFleetEntryFromModelHash(GetEntityModel(vehicle))
        if nil == fleetEntry then 
            canSync = false
            goto continue
        end

        -- Check if the player has moved
        local currentPos = GetEntityCoords(vehicle)
        if #(currentPos - lastPos) <= 1.5 then
            timeStill = ternary(
                timeStill >= Config["IdleTimeRequired"],
                timeStill,
                timeStill + 500
            )
        else
            timeStill = 0
        end

        lastPos = currentPos
        lastSyncEntity = vehicle
        canSync = timeStill >= Config["IdleTimeRequired"]

        ::continue::
    end
end)


-- Sync Thread
Citizen.CreateThread(function()
    local _promise = nil
    local syncedEntity = nil

    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then vehicle = nil end

        if canSync == false or syncedEntity ~= vehicle then
            if vehicle == nil then
                syncedEntity = nil
                goto continue
            end
            
            local vehicleNetId = VehToNet(vehicle)
            local isCommander = Citizen.Await(isNetVehicleCommanderAsync(vehicleNetId))

            if isCommander == true then
                logger:info("vehicle net ID %s releasing commander", tostring(vehicleNetId))
                releaseNetVehicleAsCommander(vehicleNetId)
            else 
                unsyncNetVehicleFromCommander(vehicleNetId)
            end
            
            syncedEntity = vehicle

            goto continue
        end

        if vehicle == nil then
            goto continue
        end

        -- Check if the vehicle is a fleet vehicle
        local fleetEntry = getFleetEntryFromModelHash(GetEntityModel(vehicle))
        if nil == fleetEntry then 
            goto continue
        end

        -- Check if player's vehicle is a commander
        local vehicleNetId = VehToNet(vehicle)
        local isPlayerVehCommander = Citizen.Await(isNetVehicleCommanderAsync(vehicleNetId))


        -- Check if we have another fleet vehicle nearby
        local nearbyFleetVehs = findFleetVehiclesInRange(fleetEntry.fleet, { vehicle })
        
        if nearbyFleetVehs == nil or #nearbyFleetVehs == 0 then
            if isPlayerVehCommander == false then
                logger:info("registering vehicle net ID %s as commander", tostring(vehicleNetId))
                registerNetVehicleAsCommander(vehicleNetId)
            end

            goto continue
        end


        -- Ensure our commander exists if stored
        local syncedCommanderNetId = Citizen.Await(getCommanderForNetVehicleAsync(vehicleNetId))

        if isPlayerVehCommander == true then
            goto continue
        end

        local isSynced = syncedCommanderId ~= nil
        local myPos = GetEntityCoords(vehicle)
        if isSynced then
            -- If we are synced, ensure we are within the radius of the commander
            local myCommanderPos = GetEntityCoords(myCommanderHandle)

            if isSynced and #(myCommanderPos - myPos) > Config["CommanderRadius"] then
                logger:info("unsyncing from commander net ID %s", tostring(vehicleNetId))
                unsyncNetVehicleFromCommander(vehicleNetId)
                
                goto continue
            end
        else
            -- Try to find the closest commander
            local closestCommanderNetId = nil
            local lastCommanderDist = math.huge
            for i = 1, #nearbyFleetVehs do
                local targetVeh = nearbyFleetVehs[i]
                local targetVehNetId = VehToNet(targetVeh)

                local targetIsCommander = Citizen.Await(isNetVehicleCommanderAsync(targetVehNetId))

                if targetIsCommander then
                    local targetPos = GetEntityCoords(targetVeh)
                    local dist = #(targetPos - myPos)

                    if dist < lastCommanderDist then
                        closestCommanderNetId = targetVehNetId
                        lastCommanderDist = dist
                    end
                end
            end
            
            -- If none in the radius is a commander, become one
            if closestCommanderNetId == nil then
                logger:info("registering vehicle net ID %s as commander", tostring(vehicleNetId))
                registerNetVehicleAsCommander(vehicleNetId)

                goto continue
            end

            -- If we have a commander in range, sync to them
            if closestCommanderNetId ~= nil and closestCommanderNetId ~= syncedCommanderNetId then
                logger:info(
                    "syncing vehicle net ID %s to commander net ID %s",
                    tostring(vehicleNetId),
                    tostring(closestCommanderNetId)
                )
                syncNetVehicleToCommander(vehicleNetId, closestCommanderNetId)

                goto continue
            end
        end
        
        ::continue::
    end
end)