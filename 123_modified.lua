local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ================= CONFIG =================
local espInventoryEnabled = true
local espEnabledStatus = false
local MAX_DISTANCE = 2000
local UPDATE_INTERVAL = 1

local AllowedUserIDs = {
    [9660032322] = true,
    [9680871870] = true,
    [7909497107] = true,
    [9443560044] = true,
    [10983064661] = true,
    [9034198439] = true,
    [9886939282] = true,
    [9090000346] = true,
    [2041444475] = true,
    [9435614564] = true,
    [9835423112] = true,
    [9781601906] = true,
    [3691056715] = true,
    [9444790877] = true,
}

local function CheckUserID()
    return AllowedUserIDs[LocalPlayer.UserId] == true
end

local RARITY_COLORS = {
    Common = Color3.fromRGB(255, 255, 255),
    Uncommon = Color3.fromRGB(99, 255, 52),
    Rare = Color3.fromRGB(51, 170, 255),
    Epic = Color3.fromRGB(237, 44, 255),
    Legendary = Color3.fromRGB(255, 150, 0),
    Omega = Color3.fromRGB(255, 20, 51),
}

local BillboardCache = {}
local nameCache = {}

-- ================= INVENTORY ESP =================
local function getRealName(tool)
    if not tool or not tool.Name then return nil end

    local originalName = tool.Name
    local lowerName = originalName:lower()

    local cleaned = lowerName
        :gsub("%d+$", "")
        :gsub("_%d+$", "")
        :gsub("%s*%d+%s*$", "")
        :gsub("[%s_]+", " ")
        :gsub("([^%w%s])", "")
        :match("^%s*(.-)%s*$")

    if cleaned:find("fishing") or cleaned:find("rod")
        or cleaned:find("canne") or cleaned:find("pêche") then
        if cleaned:find("ultimate") or cleaned:find("ult") then
            return "Ultimate Fishing Rod"
        elseif cleaned:find("advanced") then
            return "Advanced Fishing Rod"
        elseif cleaned:find("pro") then
            return "Pro Fishing Rod"
        else
            return "Regular Fishing Rod"
        end
    end

    if nameCache[originalName] then
        return nameCache[originalName]
    end

    local handle = tool:FindFirstChild("Handle")
    local fallbackName = cleaned

    for _, folder in ipairs({
        ReplicatedStorage:FindFirstChild("Items"),
        StarterPack
    }) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    local match = true

                    if handle then
                        for _, child in ipairs(handle:GetChildren()) do
                            if not item.Handle:FindFirstChild(child.Name) then
                                match = false
                                break
                            end
                        end
                    else
                        match = false
                    end

                    if match then
                        nameCache[originalName] = item.Name
                        return item.Name
                    end
                end
            end
        end
    end

    nameCache[originalName] = fallbackName
    return fallbackName
end

local function updateInventoryESP(player)
    local billboard = BillboardCache[player]
    if not billboard then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        billboard.Enabled = false
        return
    end

    local localChar = LocalPlayer.Character
    if localChar and localChar:FindFirstChild("HumanoidRootPart") then
        local distance = (localChar.HumanoidRootPart.Position -
            char.HumanoidRootPart.Position).Magnitude

        if distance > MAX_DISTANCE then
            billboard.Enabled = false
            return
        end
    end

    local container = billboard:FindFirstChild("EspContainer")
    if not container then return end
    container:ClearAllChildren()

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 2)
    layout.Parent = container

    local tools = {}

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower() ~= "fists" then
                table.insert(tools, tool)
            end
        end
    end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower() ~= "fists" then
            table.insert(tools, tool)
        end
    end

    billboard.Enabled = espInventoryEnabled and (#tools > 0)

    for _, tool in ipairs(tools) do
        local name = getRealName(tool)
        if name then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 180, 0, 14)
            label.BackgroundTransparency = 1
            label.Text = name
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 11
            label.TextStrokeTransparency = 0.4

            local rarity = tool:GetAttribute("RarityName")
                or tool:GetAttribute("Rarity")

            label.TextColor3 = RARITY_COLORS[rarity]
                or Color3.new(1, 1, 1)

            label.Parent = container
        end
    end
end

local function createInventoryESP(player)
    if player == LocalPlayer then return end

    local function setup(character)
        local root = character:WaitForChild("HumanoidRootPart", 15)
        if not root then return end

        if BillboardCache[player] then
            BillboardCache[player]:Destroy()
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FixedUnderfootESP"
        billboard.Size = UDim2.new(0, 200, 0, 150)
        billboard.StudsOffset = Vector3.new(0, -3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = MAX_DISTANCE
        billboard.Parent = root

        local container = Instance.new("Frame")
        container.Name = "EspContainer"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboard

        BillboardCache[player] = billboard
        updateInventoryESP(player)

        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                updateInventoryESP(player)
            end
        end)

        character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                updateInventoryESP(player)
            end
        end)

        local playerBackpack = player:WaitForChild("Backpack", 5)
        if playerBackpack then
            playerBackpack.ChildAdded:Connect(function()
                updateInventoryESP(player)
            end)
            playerBackpack.ChildRemoved:Connect(function()
                updateInventoryESP(player)
            end)
        end

        task.spawn(function()
            while character.Parent and billboard.Parent do
                updateInventoryESP(player)
                task.wait(UPDATE_INTERVAL)
            end
        end)
    end

    player.CharacterAdded:Connect(setup)
    if player.Character then
        setup(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createInventoryESP(player)
end
Players.PlayerAdded:Connect(createInventoryESP)

-- ================= PLAYER ESP =================
local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function removeESP(character)
    if not character then return end

    local head = character:FindFirstChild("Head")
    if head then
        local nameBillboard = head:FindFirstChild("AnouarNameHP")
        if nameBillboard then
            nameBillboard:Destroy()
        end
    end

    local highlight = character:FindFirstChild("AnouarHighlight")
    if highlight then
        highlight:Destroy()
    end
end

local function applyESP(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end

    removeESP(character)

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid or not isAlive(character) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AnouarNameHP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 160, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName ~= player.Name
        and (player.DisplayName .. " (@" .. player.Name .. ")")
        or player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -6, 0, 5)
    hpBg.Position = UDim2.new(0, 3, 0, 16)
    hpBg.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBg.Parent = billboard
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpFill.Parent = hpBg
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

    local hpText = Instance.new("TextLabel")
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.TextColor3 = Color3.new(1, 1, 1)
    hpText.TextStrokeTransparency = 0
    hpText.TextSize = 8
    hpText.Parent = hpBg

    local function updateHP()
        if humanoid.Parent and isAlive(character) then
            local ratio = math.clamp(
                humanoid.Health / humanoid.MaxHealth, 0, 1
            )
            hpFill.Size = UDim2.new(ratio, 0, 1, 0)
            hpText.Text = math.floor(humanoid.Health)
                .. "/" .. math.floor(humanoid.MaxHealth)
        else
            removeESP(character)
        end
    end

    humanoid.HealthChanged:Connect(updateHP)
    humanoid.Died:Connect(function()
        removeESP(character)
    end)

    updateHP()

    local highlight = Instance.new("Highlight")
    highlight.Name = "AnouarHighlight"
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Parent = character
end

local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end

    task.delay(0.6, function()
        removeESP(character)
        if espEnabledStatus then
            applyESP(character)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end
end)

-- ================= UI =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Rayiz_KING"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.4, 0, 0.65, 0)
MainFrame.Position = UDim2.new(0.3, 0, 0.18, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local ProtectedLabel = Instance.new("TextLabel")
ProtectedLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
ProtectedLabel.Position = UDim2.new(0.1, 0, 0.02, 0)
ProtectedLabel.BackgroundTransparency = 1
ProtectedLabel.Text = "✅ Authorized User | ID: " .. LocalPlayer.UserId
ProtectedLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
ProtectedLabel.TextScaled = true
ProtectedLabel.Font = Enum.Font.SourceSansBold
ProtectedLabel.Parent = MainFrame

local MainDrag = Instance.new("Frame")
MainDrag.Size = UDim2.new(1, 0, 0.1, 0)
MainDrag.BackgroundTransparency = 1
MainDrag.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 40)
ToggleButton.Position = UDim2.new(0.9, 0, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.Text = "Open"
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.TextScaled = true
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)

-- هذا الزر مستقل عن ESP: سحبه يحرك الزر فقط.
local ToggleDrag = Instance.new("Frame")
ToggleDrag.Size = UDim2.new(1, 0, 1, 0)
ToggleDrag.BackgroundTransparency = 1
ToggleDrag.Parent = ToggleButton

local ESPInventoryToggle = Instance.new("TextButton")
ESPInventoryToggle.Size = UDim2.new(0.8, 0, 0.12, 0)
ESPInventoryToggle.Position = UDim2.new(0.1, 0, 0.12, 0)
ESPInventoryToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
ESPInventoryToggle.Text = "ESP Inventory: ON"
ESPInventoryToggle.TextScaled = true
ESPInventoryToggle.Parent = MainFrame
Instance.new("UICorner", ESPInventoryToggle).CornerRadius = UDim.new(0, 8)

local ESPToggle = Instance.new("TextButton")
ESPToggle.Size = UDim2.new(0.8, 0, 0.12, 0)
ESPToggle.Position = UDim2.new(0.1, 0, 0.26, 0)
ESPToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ESPToggle.Text = "ESP: OFF"
ESPToggle.TextScaled = true
ESPToggle.Parent = MainFrame
Instance.new("UICorner", ESPToggle).CornerRadius = UDim.new(0, 8)

local function makeDraggable(frame, dragArea)
    local dragging = false
    local startPos
    local startInput

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input.Position
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - startInput

            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- تحريك النافذة وتحريك زر الفتح مستقلان تماماً عن حالة ESP.
makeDraggable(MainFrame, MainDrag)
makeDraggable(ToggleButton, ToggleDrag)

ESPToggle.MouseButton1Click:Connect(function()
    espEnabledStatus = not espEnabledStatus

    ESPToggle.Text = "ESP: "
        .. (espEnabledStatus and "ON" or "OFF")

    ESPToggle.BackgroundColor3 = espEnabledStatus
        and Color3.fromRGB(0, 255, 0)
        or Color3.fromRGB(255, 0, 0)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if espEnabledStatus then
                applyESP(player.Character)
            else
                removeESP(player.Character)
            end
        end
    end
end)

ESPInventoryToggle.MouseButton1Click:Connect(function()
    espInventoryEnabled = not espInventoryEnabled

    ESPInventoryToggle.Text = "ESP Inventory: "
        .. (espInventoryEnabled and "ON" or "OFF")

    ESPInventoryToggle.BackgroundColor3 = espInventoryEnabled
        and Color3.fromRGB(0, 255, 0)
        or Color3.fromRGB(255, 0, 0)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateInventoryESP(player)
        end
    end
end)

local guiOpen = false

ToggleButton.MouseButton1Click:Connect(function()
    guiOpen = not guiOpen
    MainFrame.Visible = guiOpen
    ToggleButton.Text = guiOpen and "Close" or "Open"
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.G then
        guiOpen = not guiOpen
        MainFrame.Visible = guiOpen
        ToggleButton.Visible = not guiOpen
    end
end)

-- تحديث ESP بدون أي ارتباط بالزر المتحرك.
task.spawn(function()
    while true do
        if espEnabledStatus then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head and not head:FindFirstChild("AnouarNameHP") then
                        applyESP(player.Character)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

task.wait(6)
getgenv().script_mode = "PVP"
loadstring(game:HttpGet("https://raw.githubusercontent.com/hermanos-dev/hermanos-hub/refs/heads/main/Loader.lua"))()
