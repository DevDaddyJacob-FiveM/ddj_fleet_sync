local commanders = {}
local syncs = {}


RegisterNetEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", function(vehNetId)
    commanders[vehNetId] = true
    logger:info(vehNetId .. " registered themselves as a commander")
end)


RegisterNetEvent("DevJacob:FleetSync:Server:ReleaseVehicleAsCommander", function(vehNetId)
    commanders[vehNetId] = nil
    for syncedVehNetId, commanderNetId in pairs(syncs) do
        if commanderNetId == netId then
            syncs[syncedVehNetId] = nil
        end
    end

    logger:info(vehNetId .. " released themselves as a commander")
end)


RegisterNetEvent("DevJacob:FleetSync:Server:SyncVehicleToCommander", function(vehNetId, commanderNetId)
    syncs[vehNetId] = commanderNetId
    
    local targets = {}
    for syncedVehNetId, _commanderNetId in pairs(syncs) do
        if _commanderNetId == commanderNetId then
            local syncedVehEntity = NetworkGetEntityFromNetworkId(syncedVehNetId) 
            if DoesEntityExist(syncedVehEntity) then
                table.insert(targets, {
                    vehNetId = syncedVehNetId,
                    owner = NetworkGetEntityOwner(syncedVehEntity)
                })
            end
        end
    end

    local commanderEntity = NetworkGetEntityFromNetworkId(commanderNetId) 
    if DoesEntityExist(commanderEntity) then
        table.insert(targets, {
            vehNetId = commanderNetId,
            owner = NetworkGetEntityOwner(commanderEntity)
        })
    end

    for i = 1, #targets do
        local target = targets[i]

        TriggerClientEvent(
            "DevJacob:FleetSync:Client:SyncVehicleNow",
            target.owner,
            target.vehNetId,
            commanderNetId
        )

        target = nil
    end
    
    targets = nil

    logger:debug(vehNetId .. " synced to commander id " .. commanderNetId)
end)


RegisterNetEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", function(vehNetId)
    if syncs[vehicelNetId] ~= nil then
        logger:debug(vehNetId .. " unsynced from commander id " .. commander)
    end

    syncs[vehNetId] = nil
end)


RegisterNetEvent("DevJacob:FleetSync:Server:DeadNetworkId", function(netId)
    commanders[netId] = nil

    for syncedVehNetId, commanderNetId in pairs(syncs) do
        if commanderNetId == netId or syncedVehNetId == netId then
            syncs[syncedVehNetId] = nil
        end
    end
end)


rpc.register("DevJacob:FleetSync:Server:IsVehicleCommander", function(source, cb, vehNetId)
    cb(commanders[vehNetId] == true)
end)


rpc.register("DevJacob:FleetSync:Server:GetCommanderForVehicle", function(source, cb, vehNetId)
    cb(syncs[vehNetId])
end)
