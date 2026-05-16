function ternary(condition, trueValue, falseValue)
    if condition then
        return trueValue
    else
        return falseValue
    end
end


---@param self table
---@param value any
---@return boolean isInTable
---@author DevDaddyJacob
function table.hasValue(self, value)
    for _, val in pairs(self) do
        if val == value then
            return true
        end
    end

    return false
end