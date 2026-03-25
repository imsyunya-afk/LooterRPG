local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)
local InventoryManager = require(script.Parent.InventoryManager)

local function onItemPickedUp(prompt, player)
    local itemName = prompt.Parent.Name
    local itemInfo = ItemData[itemName]

    if itemInfo then
        if InventoryManager.isInventoryFull(player) then
            print(player.Name .. " のインベントリはいっぱいです！ " .. itemName .. " を拾うことができません。")
            return
        end
        prompt.Enabled = false
        InventoryManager.addItem(player, itemName)
        print(player.Name .. " picked up: " .. itemInfo.Name)
        task.wait(0.05)
		prompt.Parent:Destroy()
    else
        print("Error: " .. itemName .. " はカタログにありません！")
    end

end

ProximityPromptService.PromptTriggered:Connect(onItemPickedUp)

local DropItemRequest = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DropItemRequest")
local ItemTemplate = ReplicatedStorage:WaitForChild("ItemTemplates")

DropItemRequest.OnServerEvent:Connect(function(player, slotName, clientItemName)
    local actualItemName = InventoryManager.removeItem(player, slotName)
    if actualItemName then
        print(player.Name .. " が " .. actualItemName .. " をドロップしました。")

        local template = ItemTemplate:FindFirstChild(actualItemName)

        if template then
            local newDrop = template:Clone()
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local spawnPos = hrp.Position + (hrp.CFrame.LookVector * 2) + Vector3.new(0, 0, 0)
                newDrop.Position = spawnPos
                newDrop.Parent = workspace

                local throwForce = (hrp.CFrame.LookVector * 15) + Vector3.new(0, 25, 0)
                newDrop.AssemblyLinearVelocity = throwForce
            end
        else
            warn("Error: " .. actualItemName .. " のテンプレートが見つかりません！")
        end
    end
end)

local SwapItemRequest = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SwapItemRequest")

SwapItemRequest.OnServerEvent:Connect(function(player, slot1Name, slot2Name)
    
    InventoryManager.swapItems(player, slot1Name, slot2Name)
end)