-- Kecuya Hub | Steal An Egg Ultimate Script
-- Owner: @kecuya
-- Mobile & PC Supported

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Kecuya Hub | Steal An Egg",
    LoadingTitle = "Loading Kecuya Hub...",
    LoadingSubtitle = "by @kecuya",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ==================== ПЕРЕМЕННЫЕ И НАСТРОЙКИ ====================
local Settings = {
    FlySpeed = 70,
    IsFlying = false,
    AutoSteal = false,
    TargetRarity = "All",
    TargetMutation = "All",
    TargetLocation = "All",
    PriorityTopEggs = true,
    AntiCatchHeight = 12
}

local RarityList = {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
local MutationList = {"All", "None", "Golden", "Rainbow", "Shadow", "Shiny"}
local LocationList = {"All", "Main Area", "Desert Zone", "Volcano", "Cyber World", "Ocean"}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ==================== ЛЕТАТЕЛЬНЫЙ ДВИЖОК ====================
local BodyVelocity, BodyGyro

local function StartFlying()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = hrp

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    BodyGyro.CFrame = hrp.CFrame
    BodyGyro.Parent = hrp
end

local function StopFlying()
    if BodyVelocity then BodyVelocity:Destroy() end
    if BodyGyro then BodyGyro:Destroy() end
end

RunService.RenderStepped:Connect(function()
    if Settings.IsFlying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if BodyVelocity then
            BodyVelocity.Velocity = moveDir * Settings.FlySpeed
        end
        if BodyGyro then
            BodyGyro.CFrame = cam.CFrame
        end
    end
end)

-- ==================== ВАЛИДАЦИЯ ЯИЦ ====================
local function IsMatchingEgg(egg)
    if not egg:IsA("BasePart") and not egg:IsA("Model") then return false end
    
    local rarityAttr = egg:GetAttribute("Rarity") or egg.Name
    local mutationAttr = egg:GetAttribute("Mutation") or "None"
    local locAttr = egg:GetAttribute("Location") or egg.Parent.Name

    -- Проверка локации
    if Settings.TargetLocation ~= "All" and not string.find(locAttr:lower(), Settings.TargetLocation:lower()) then
        return false
    end
    -- Проверка редких видов
    if Settings.TargetRarity ~= "All" and not string.find(rarityAttr:lower(), Settings.TargetRarity:lower()) then
        return false
    end
    -- Проверка мутаций
    if Settings.TargetMutation ~= "All" and not string.find(mutationAttr:lower(), Settings.TargetMutation:lower()) then
        return false
    end

    return true
end

-- ==================== АВТО-ФАРМ ====================
task.spawn(function()
    while true do
        task.wait(0.2)
        if Settings.AutoSteal and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local targets = {}

            -- Сбор подходящих объектов
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("egg") and IsMatchingEgg(obj) then
                    table.insert(targets, obj)
                end
            end

            -- Сортировка топовых яиц по приоритету
            if Settings.PriorityTopEggs then
                table.sort(targets, function(a, b)
                    local rarityA = a:GetAttribute("Value") or 1
                    local rarityB = b:GetAttribute("Value") or 1
                    return rarityA > rarityB
                end)
            end

            -- Безопасный полёт к цели (сверху, чтобы не поймали)
            if #targets > 0 then
                local target = targets[1]
                local targetPos = target:IsA("Model") and target:GetPivot().Position or target.Position
                
                -- Подлёт над яйцом для защиты от игроков
                local safePos = targetPos + Vector3.new(0, Settings.AntiCatchHeight, 0)
                
                local tweenInfo = TweenInfo.new((hrp.Position - safePos).Magnitude / Settings.FlySpeed, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(safePos)})
                tween:Play()
                tween.Completed:Wait()

                -- Быстрое снижение и забор
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
                task.wait(0.3)
                
                -- Подъем обратно на безопасную высоту
                hrp.CFrame = CFrame.new(safePos)
            end
        end
    end
end)

-- ==================== ИНТЕРФЕЙС GUI ====================

local MainTab = Window:CreateTab("Auto-Farm", 4483362458)
local FilterTab = Window:CreateTab("Filters", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)

-- Auto-Farm Tab
MainTab:CreateToggle({
    Name = "Enable Fly-Steal (Безопасный Авто-Сбор)",
    CurrentValue = false,
    Callback = function(Value)
        Settings.AutoSteal = Value
        Settings.IsFlying = Value
        if Value then StartFlying() else StopFlying() end
    end
})

MainTab:CreateToggle({
    Name = "Prioritize Top Eggs (Топовые яйца первыми)",
    CurrentValue = true,
    Callback = function(Value)
        Settings.PriorityTopEggs = Value
    end
})

-- Filters Tab
FilterTab:CreateDropdown({
    Name = "Локация",
    Options = LocationList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetLocation = Option
    end
})

FilterTab:CreateDropdown({
    Name = "Редкость яйца",
    Options = RarityList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetRarity = Option
    end
})

FilterTab:CreateDropdown({
    Name = "Мутация",
    Options = MutationList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetMutation = Option
    end
})

-- Movement Tab
MovementTab:CreateSlider({
    Name = "Скорость полёта (Fly Speed)",
    Range = {30, 200},
    Increment = 5,
    CurrentValue = 70,
    Callback = function(Value)
        Settings.FlySpeed = Value
    end
})

MovementTab:CreateSlider({
    Name = "Высота безопасности (Anti-Catch Height)",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 12,
    Callback = function(Value)
        Settings.AntiCatchHeight = Value
    end
})

Rayfield:Notify({
    Title = "Kecuya Hub Loaded",
    Content = "Все системы и фильтры готовы к работе!",
    Duration = 4,
    Image = 4483362458
})
