local EnteredKey = "KSA" 
local CorrectKey = "KSA"

local KeyGui = Instance.new("ScreenGui")
KeyGui.Parent = game.CoreGui
KeyGui.Name = "KSA_Key_System"

local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(0, 300, 0, 160)
KeyFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeyFrame.Parent = KeyGui
KeyFrame.Active = true
KeyFrame.Draggable = true

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.Text = "الرجاء إدخل المفتاح (Password):"
KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
KeyTitle.Parent = KeyFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(0, 240, 0, 40)
KeyInput.Position = UDim2.new(0.1, 0, 0.35, 0)
KeyInput.Text = ""
KeyInput.PlaceholderText = "اكتب المفتاح هنا..."
KeyInput.Parent = KeyFrame

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0, 120, 0, 35)
SubmitBtn.Position = UDim2.new(0.3, 0, 0.7, 0)
SubmitBtn.Text = "تأكيد"
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Parent = KeyFrame

SubmitBtn.MouseButton1Click:Connect(function()
    if KeyInput.Text == CorrectKey then
        KeyFrame:Destroy()
        local TimerLabel = Instance.new("TextLabel")
        TimerLabel.Size = UDim2.new(0, 200, 0, 50)
        TimerLabel.Position = UDim2.new(0.45, 0, 0.1, 0)
        TimerLabel.TextSize = 24
        TimerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        TimerLabel.BackgroundTransparency = 1
        TimerLabel.Parent = KeyGui
        for i = 6, 0, -1 do
            TimerLabel.Text = "جاري التشغيل خلال: " .. i .. " ثوانٍ"
            task.wait(1)
        end
        KeyGui:Destroy()
        local success, err = pcall(StartMainScript)
        if not success then warn("خطأ في تشغيل السكربت: " .. tostring(err)) end
    else
        KeyInput.Text = ""
        KeyInput.PlaceholderText = "المفتاح خاطئ! جرب مجدداً."
    end
end)

function StartMainScript()
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local Coords = {
        fishing = Vector3.new(150, 6, -250),
        cooking = Vector3.new(-45, 6, 85),
        janitor = Vector3.new(80, 6, -10),
        stocker = Vector3.new(-130, 6, 40)
    }

    getgenv().AutoFarmActive = false
    getgenv().CurrentJob = "none"
    getgenv().GroundMode = "عادي" 
    getgenv().SelectedRodMode = "السنارة على حسب المستوى"
    getgenv().SelectedBaitMode = "الطعم على حسب المستوى"
    getgenv().VehicleFarm = false

    getgenv().HideNameActive = false
    getgenv().UndergroundOnLowHealth = false
    getgenv().AutoResetOn31 = false
    getgenv().AutoRespawnButton = false

    local function SafeMoveTo(targetPosition)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart and targetPosition then
            humanoid.WalkSpeed = 30
            if getgenv().VehicleFarm then
                local vehicle = workspace:FindFirstChild("Vehicle") or workspace:FindFirstChild("Bike") or character:FindFirstChild("Vehicle")
                if vehicle and vehicle:FindFirstChild("DriveSeat") and not vehicle.DriveSeat.Occupant then
                    vehicle.DriveSeat:Sit(humanoid)
                end
            end
            if getgenv().GroundMode == "تحت الأرض" then
                rootPart.CFrame = CFrame.new(targetPosition.X, targetPosition.Y - 8, targetPosition.Z)
                task.wait(0.1)
                return
            end
            humanoid:MoveTo(targetPosition)
        end
    end

    local function UpdateEquipment()
        pcall(function()
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local level = leaderstats and (leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("المستوى")) and leaderstats.Level.Value or 1
            if getgenv().SelectedRodMode == "السنارة على حسب المستوى" then
                local targetRodName = "DefaultRod"
                if level >= 50 then targetRodName = "GoldenRod"
                elseif level >= 25 then targetRodName = "ProRod"
                elseif level >= 10 then targetRodName = "IronRod" end
                local backpackRod = LocalPlayer.Backpack:FindFirstChild(targetRodName)
                if backpackRod and LocalPlayer.Character then
                    LocalPlayer.Character.Humanoid:EquipTool(backpackRod)
                end
            end
            if getgenv().SelectedBaitMode == "الطعم على حسب المستوى" then
                local RemoteBait = ReplicatedStorage:FindFirstChild("EquipBait", true) or ReplicatedStorage:FindFirstChild("BaitRemote", true)
                if RemoteBait and RemoteBait:IsA("RemoteEvent") then
                    if level >= 30 then RemoteBait:FireServer("PremiumBait")
                    else RemoteBait:FireServer("NormalBait") end
                end
            end
        end)
    end

    task.spawn(function()
        while task.wait(0.3) do
            if getgenv().AutoFarmActive and getgenv().CurrentJob ~= "none" then
                local targetPos = Coords[getgenv().CurrentJob]
                if targetPos then
                    UpdateEquipment()
                    SafeMoveTo(targetPos)
                    if getgenv().CurrentJob == "fishing" then
                        pcall(function()
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then 
                                LocalPlayer.Character.Humanoid:EquipTool(tool)
                                tool:Activate()
                            end
                        end)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                if getgenv().UndergroundOnLowHealth and humanoid.Health <= 15 and humanoid.Health > 0 then
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -5, 0) * CFrame.fromEulerAnglesXYZ(0, 0.05, 0)
                    rootPart.Velocity = Vector3.new(0,0,0)
                end
                if getgenv().AutoResetOn31 and math.floor(humanoid.Health) == 31 then
                    humanoid.Health = 0
                end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if getgenv().HideNameActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(function()
                LocalPlayer.Character.Humanoid.DisplayName = "....."
                if LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head:FindFirstChildOfClass("BillboardGui") then
                    LocalPlayer.Character.Head:FindFirstChildOfClass("BillboardGui").Enabled = false
                end
            end)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(char)
        if getgenv().AutoRespawnButton then
            task.wait(6.1)
            pcall(function()
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                for _, gui in pairs(PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") and (string.find(string.lower(gui.Text), "respawn") or string.find(gui.Text, "إعادة") or string.find(gui.Text, "حياه")) then
                        for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                            connection:Fire()
                        end
                    end
                end
            end)
        end
    end)

    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = "KSA_Advanced_Hub"

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 480, 0, 320)
    MainFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 140, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Sidebar.Parent = MainFrame

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 340, 1, 0)
    TabContainer.Position = UDim2.new(0, 140, 0, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    local FarmPage = Instance.new("ScrollingFrame")
    FarmPage.Size = UDim2.new(1, 0, 1, 0)
    FarmPage.BackgroundTransparency = 1
    FarmPage.Visible = true
    FarmPage.Parent = TabContainer

    local EssentialsPage = Instance.new("ScrollingFrame")
    EssentialsPage.Size = UDim2.new(1, 0, 1, 0)
    EssentialsPage.BackgroundTransparency = 1
    EssentialsPage.Visible = false
    EssentialsPage.Parent = TabContainer

    local L1 = Instance.new("UIListLayout") L1.Parent = FarmPage; L1.Padding = UDim.new(0,5)
    local L2 = Instance.new("UIListLayout") L2.Parent = EssentialsPage; L2.Padding = UDim.new(0,5)

    local Tab1Btn = Instance.new("TextButton")
    Tab1Btn.Size = UDim2.new(1, 0, 0, 50)
    Tab1Btn.Text = "1. التفريم"
    Tab1Btn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    Tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1Btn.Parent = Sidebar

    local Tab2Btn = Instance.new("TextButton")
    Tab2Btn.Size = UDim2.new(1, 0, 0, 50)
    Tab2Btn.Position = UDim2.new(0, 0, 0, 55)
    Tab2Btn.Text = "2. أشياء لازم تفعلها"
    Tab2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2Btn.Parent = Sidebar

    Tab1Btn.MouseButton1Click:Connect(function()
        FarmPage.Visible = true; EssentialsPage.Visible = false
        Tab1Btn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
        Tab2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)

    Tab2Btn.MouseButton1Click:Connect(function()
        FarmPage.Visible = false; EssentialsPage.Visible = true
        Tab1Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Tab2Btn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    end)

    local JobBtn = Instance.new("TextButton")
    JobBtn.Size = UDim2.new(0, 320, 0, 40)
    JobBtn.Text = "اختر الوظائف 🔽"
    JobBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    JobBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    JobBtn.Parent = FarmPage

    local JobDropdown = Instance.new("Frame")
    JobDropdown.Size = UDim2.new(0, 320, 0, 160)
    JobDropdown.Visible = false
    JobDropdown.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    JobDropdown.Parent = FarmPage
    local JL = Instance.new("UIListLayout") JL.Parent = JobDropdown

    JobBtn.MouseButton1Click:Connect(function() JobDropdown.Visible = not JobDropdown.Visible end)

    local jobs = {fishing = "صيد", janitor = "مكنسة", cooking = "طبخ", stocker = "صناديق"}
    for k, v in pairs(jobs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 40)
        b.Text = v
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Parent = JobDropdown
        b.MouseButton1Click:Connect(function()
            getgenv().CurrentJob = k
            JobBtn.Text = "الوظيفة المختارة: " .. v
            JobDropdown.Visible = false
        end)
    end

    local ToggleFarmBtn = Instance.new("TextButton")
    ToggleFarmBtn.Size = UDim2.new(0, 320, 0, 40)
    ToggleFarmBtn.Text = "تفعيل التفريم: OFF"
    ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    ToggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFarmBtn.Parent = FarmPage

    ToggleFarmBtn.MouseButton1Click:Connect(function()
        getgenv().AutoFarmActive = not getgenv().AutoFarmActive
        if getgenv().AutoFarmActive then
            ToggleFarmBtn.Text = "تفعيل التفريم: ON"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        else
            ToggleFarmBtn.Text = "تفعيل التفريم: OFF"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        end
    end)

    local GroundBtn = Instance.new("TextButton")
    GroundBtn.Size = UDim2.new(0, 320, 0, 40)
    GroundBtn.Text = "الموقع الأرضي: عادي"
    GroundBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    GroundBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GroundBtn.Parent = FarmPage

    GroundBtn.MouseButton1Click:Connect(function()
        if getgenv().GroundMode == "عادي" then
            getgenv().GroundMode = "تحت الأرض"
            GroundBtn.Text = "الموقع الأرضي: تحت الأرض 🟢"
        else
            getgenv().GroundMode = "عادي"
            GroundBtn.Text = "الموقع الأرضي: عادي ⚪"
        end
    end)

    local RodBtn = Instance.new("TextButton")
    RodBtn.Size = UDim2.new(0, 320, 0, 40)
    RodBtn.Text = "وش السنارة اللي تبغاها: حسب المستوى"
    RodBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    RodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RodBtn.Parent = FarmPage

    local BaitBtn = Instance.new("TextButton")
    BaitBtn.Size = UDim2.new(0, 320, 0, 40)
    BaitBtn.Text = "نوع الطعم: الطعم على حسب المستوى"
    BaitBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BaitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BaitBtn.Parent = FarmPage

    local VehicleBtn = Instance.new("TextButton")
    VehicleBtn.Size = UDim2.new(0, 320, 0, 40)
    VehicleBtn.Text = "التفريم بمركبة (سيكل/سيارة): OFF"
    VehicleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    VehicleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VehicleBtn.Parent = FarmPage

    VehicleBtn.MouseButton1Click:Connect(function()
        getgenv().VehicleFarm = not getgenv().VehicleFarm
        if getgenv().VehicleFarm then
            VehicleBtn.Text = "التفريم بمركبة: ON"
            VehicleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        else
            VehicleBtn.Text = "التفريم بمركبة: OFF"
            VehicleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        end
    end)

    local function CreateToggle(text, targetGenv, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 320, 0, 45)
        btn.Text = text .. ": OFF"
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = parent

        btn.MouseButton1Click:Connect(function()
            getgenv()[targetGenv] = not getgenv()[targetGenv]
            if getgenv()[targetGenv] then
                btn.Text = text .. ": ON 🟩"
                btn.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
            else
                btn.Text = text .. ": OFF 🟥"
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end)
    end

    CreateToggle("إخفاء اسمك وعرض (.....)", "HideNameActive", EssentialsPage)
    CreateToggle("ينزلك تحت الأرض إذا دمك 15 فما تحت", "UndergroundOnLowHealth", EssentialsPage)
    CreateToggle("إذا عشت وصار دمك 31 يعمل إعادة حياة", "AutoResetOn31", EssentialsPage)
    CreateToggle("الضغط التلقائي على الـ Respawn بعد الموت", "AutoRespawnButton", EssentialsPage)
end
