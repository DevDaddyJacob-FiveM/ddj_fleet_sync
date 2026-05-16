local logLabel = "DDJ-FleetSync"
Logger = {}

---@param message string
function Logger.debug(message, ...)
    print("[" .. logLabel .. "] DEBUG: " .. message)
end

---@param condition boolean
---@param message string
function Logger.debugIf(condition, message, ...)
    if condition == true then
        print("[" .. logLabel .. "] DEBUG: " .. message)
    end
end

---@param message string
function Logger.info(message, ...)
    print("[" .. logLabel .. "] INFO: " .. message)
end

---@param condition boolean
---@param message string
function Logger.infoIf(condition, message, ...)
    if condition == true then
        print("[" .. logLabel .. "] INFO: " .. message)
    end
end

---@param message string
function Logger.warn(message, ...)
    print("[" .. logLabel .. "] WARN: " .. message)
end

---@param condition boolean
---@param message string
function Logger.warnIf(condition, message, ...)
    if condition == true then
        print("[" .. logLabel .. "] WARN: " .. message)
    end
end

---@param message string
function Logger.error(message, ...)
    print("[" .. logLabel .. "] ERROR: " .. message)
end

---@param condition boolean
---@param message string
function Logger.errorIf(condition, message, ...)
    if condition == true then
        print("[" .. logLabel .. "] ERROR: " .. message)
    end
end