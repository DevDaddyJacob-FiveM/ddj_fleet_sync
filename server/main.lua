local commanders = {}
local syncs = {}


RegisterNetEvent("DevJacob:FleetSync:Server:RegisterVehicleAsCommander", function(vehNetId)
    commanders[vehNetId] = true
    Logger.debugIf(Config["DebugMode"], vehNetId .. " registered themselves as a commander")
end)


RegisterNetEvent("DevJacob:FleetSync:Server:ReleaseVehicleAsCommander", function(vehNetId)
    commanders[vehNetId] = nil
    for syncedVehNetId, commanderNetId in pairs(syncs) do
        if commanderNetId == netId then
            syncs[syncedVehNetId] = nil
        end
    end

    Logger.debugIf(Config["DebugMode"], vehNetId .. " released themselves as a commander")
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

    Logger.debugIf(Config["DebugMode"], vehNetId .. " synced to commander id " .. commanderNetId)
end)


RegisterNetEvent("DevJacob:FleetSync:Server:UnsyncVehicleFromCommander", function(vehNetId)
    if syncs[vehicelNetId] ~= nil then
        Logger.debugIf(Config["DebugMode"], vehNetId .. " unsynced from commander id " .. commander)
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


RegisterNetEvent("DevJacob:FleetSync:Server:IsVehicleCommander", function(vehNetId, cb)
    cb(commanders[vehNetId] == true)
end)


RegisterNetEvent("DevJacob:FleetSync:Server:GetCommanderForVehicle", function(vehNetId, cb)
    cb(syncs[vehNetId])
end)
