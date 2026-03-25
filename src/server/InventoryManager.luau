local InventoryManager = {}
local playerInventories = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local updateUIEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("UpdateInventoryUI")

function InventoryManager.isInventoryFull(player)
    local myItems = playerInventories[player.UserId]
    if not myItems then return false end

    if myItems.SafePocket == nil or myItems.SafePocket == "" then
        return false
    end

    for i = 1, 7 do
        if myItems.Hotbar[i] == nil or myItems.Hotbar[i] == "" then
            return false
        end
    end

    return true
end

function InventoryManager.addItem(player, itemName)
    if not playerInventories[player.UserId] then
        playerInventories[player.UserId] = { SafePocket = nil, Hotbar = {} }
    end

    local myItems = playerInventories[player.UserId]
    if myItems.SafePocket == nil or myItems.SafePocket == "" then
        myItems.SafePocket = itemName
    else
        for i = 1, 7 do
            if myItems.Hotbar[i] == nil or myItems.Hotbar[i] == "" then
                myItems.Hotbar[i] = itemName
                break
            end
        end
    end

    print(player.Name .. " のインベントリに " .. itemName .. " が追加されました。")
    updateUIEvent:FireClient(player, myItems)
end

function InventoryManager.removeItem(player, slotName)
    local myItems = playerInventories[player.UserId]
    if not myItems then return false end

    local removedItemName = nil

    if slotName == "SafeSlot1" then
        removedItemName = myItems.SafePocket
        myItems.SafePocket = ""
    else
        local index = tonumber(string.match(slotName, "%d+"))
        if index then
            removedItemName = myItems.Hotbar[index]
            myItems.Hotbar[index] = ""
        end
    end

    if removedItemName == nil or removedItemName == "" then
        return false
    end
    updateUIEvent:FireClient(player, myItems)

    return removedItemName
end

Players.PlayerRemoving:Connect(function(player)
    if playerInventories[player.UserId] then
        playerInventories[player.UserId] = nil
        print(player.Name .. " のインベントリデータが削除されました。")
    end
end)

return InventoryManager