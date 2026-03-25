local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local inventoryGui = playerGui:WaitForChild("InventoryGui")
local container = inventoryGui:WaitForChild("InventoryContainer")
local safePocket = container:WaitForChild("SafePocketFrame")
local hotbar = container:WaitForChild("HotbarFrame")

local updateUIEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("UpdateInventoryUI")

local DropItemRequest = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DropItemRequest")

local UserInputService = game:GetService("UserInputService")
local dropZone = inventoryGui:WaitForChild("DropZoneFrame")
local dragIcon = inventoryGui:WaitForChild("DragIcon")

local dragIconText = dragIcon:FindFirstChild("ItemName", true)

local isDragging = false
local dragStartPos = nil
local draggingItemName = ""
local sourceSlot = nil
local sourceSlotName = ""

local DEADZONE = 15

local allSlots = { safePocket:WaitForChild("SafeSlot1") }
for i = 1, 7 do
    table.insert(allSlots, hotbar:WaitForChild("Slot" .. tostring(i)))
end

for _, slot in ipairs(allSlots) do
    local button = slot:FindFirstChild("ItemName", true)
    if button then
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if button.Text ~= "" then
                    dragStartPos = input.Position
                    draggingItemName = button.Text
                    sourceSlot = button
                    sourceSlotName = slot.Name
                    isDragging = false
                end
            end
        end)
    end
end

UserInputService.InputChanged:Connect(function(input)
    if dragStartPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentPos = input.Position

        local distance = (Vector2.new(currentPos.X, currentPos.Y) - Vector2.new(dragStartPos.X, dragStartPos.Y)).Magnitude

        if not isDragging and distance > DEADZONE then
            isDragging = true

            dropZone.Visible = true
            dragIcon.Visible = true
            
            if dragIconText then
                dragIconText.Text = draggingItemName
            else
                warn("Error: DragIcon内にItemNameテキストラベルが見つかりません！")
            end

            sourceSlot.TextTransparency = 0.7
        end
        if isDragging then
            dragIcon.Position = UDim2.new(0, currentPos.X, 0, currentPos.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if dragStartPos and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then

        if isDragging then
            local currentPos = input.Position

            local minX = dropZone.AbsolutePosition.X
            local maxX = minX + dropZone.AbsoluteSize.X
            local minY = dropZone.AbsolutePosition.Y
            local maxY = minY + dropZone.AbsoluteSize.Y

            if currentPos.X >= minX and currentPos.X <= maxX and currentPos.Y >= minY and currentPos.Y <= maxY then
                print("アイテムがドロップゾーンにドロップされました: " .. draggingItemName)

                DropItemRequest:FireServer(sourceSlotName, draggingItemName)
            else
                print("ドロップゾーンの外だったので、アイテムはドロップされませんでした。")
            end

            dropZone.Visible = false
            dragIcon.Visible = false

            if sourceSlot then
                sourceSlot.TextTransparency = 0
            end
        end

        dragStartPos = nil
        isDragging = false
        draggingItemName = ""
        sourceSlot = nil
    end
end)

local function onInventoryUpdated(myItems)
    print("[PC側] UIの更新を開始します")
    local safeSlotTarget = safePocket:WaitForChild("SafeSlot1")
    local safeTextLabel = safeSlotTarget:FindFirstChild("ItemName", true)

    if safeTextLabel then
        safeTextLabel.Text = myItems.SafePocket or ""
    end

    for i = 1, 7 do
        local slotName = "Slot" .. tostring(i)
        local targetSlot = hotbar:WaitForChild(slotName)

        if targetSlot then
            local textLabel = targetSlot:FindFirstChild("ItemName", true)
            if textLabel then
                textLabel.Text = myItems.Hotbar[i] or ""
            end
        end
    end
end

updateUIEvent.OnClientEvent:Connect(onInventoryUpdated)