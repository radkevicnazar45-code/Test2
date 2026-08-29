-- DELTA BOOT TEST
-- This MUST run before any other part of the original script.
local __bootPlayers = game:GetService("Players")
local __bootPlayer = __bootPlayers.LocalPlayer
local __bootGui = Instance.new("ScreenGui")
__bootGui.Name = "StealEgg_BootTest"
__bootGui.ResetOnSpawn = false
__bootGui.Parent = __bootPlayer:WaitForChild("PlayerGui")

local __bootLabel = Instance.new("TextLabel")
__bootLabel.Size = UDim2.new(0, 420, 0, 70)
__bootLabel.Position = UDim2.new(0.5, -210, 0, 20)
__bootLabel.Text = "STEAL EGG: BOOT TEST WORKS"
__bootLabel.TextScaled = true
__bootLabel.Parent = __bootGui

task.wait(2)

--====================================================================--
--           STEAL AN EGG: COMPLETE ALL-IN-ONE AUTO FARM               --
--====================================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Delta-friendly startup diagnostic: ordinary Roblox GUI APIs only.
local _diagGui
local _diagLabel
local function DIAG(msg)
    pcall(function()
        if not _diagGui or not _diagGui.Parent then
            _diagGui = Instance.new("ScreenGui")
            _diagGui.Name = "StealEgg_Diagnostic"
            _diagGui.ResetOnSpawn = false
            _diagGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

            _diagLabel = Instance.new("TextLabel")
            _diagLabel.Size = UDim2.new(0, 420, 0, 55)
            _diagLabel.Position = UDim2.new(0.5, -210, 0, 20)
            _diagLabel.BackgroundTransparency = 0.15
            _diagLabel.TextScaled = true
            _diagLabel.Text = ""
            _diagLabel.Parent = _diagGui
        end
        _diagLabel.Text = "STEAL EGG: " .. tostring(msg)
    end)
end

DIAG("1/6 script started")

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- CONFIGURATION & GLOBAL STATE
------------------------------------------------------------------------
local Config = {
    FlySpeed = 50,
    StuckTimeout = 15,
    EffectColor = Color3.fromRGB(0, 255, 200),
    EnableWings = true,
    Rarities = {
        Divine = true,   -- Prior priority 1
        Eternal = true,  -- Priority 2
        Secret = true    -- Priority 3
    }
}

DIAG("2/6 services loaded")

local State = {
    IsFarming = false,
    CurrentStatus = "Idle",
    CurrentTarget = nil,
    TargetRarity = "None",
    HoldProgress = 0,
    IsNight = false,
    NightCycleDoneThisNight = false,
    TreadmillActive = false,
    BodyVelocity = nil,
    BodyGyro = nil,
    WingsModel = nil,
    AuraAttachment = nil,
    CurrentThread = nil
}

------------------------------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------------------------------
local function GetCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
        return char, char.HumanoidRootPart, char.Humanoid
    end
    return nil, nil, nil
end

local function GetTargetCFrame(object)
    if not object or not object.Parent then return nil end
    if object:IsA("Model") then
        if object.PrimaryPart then
            return object.PrimaryPart.CFrame
        else
            return object:GetBoundingBox()
        end
    elseif object:IsA("BasePart") then
        return object.CFrame
    end
    return nil
end

------------------------------------------------------------------------
-- REAL FLIGHT SYSTEM (BodyVelocity + BodyGyro)
------------------------------------------------------------------------
local function StopFlight()
    if State.BodyVelocity then
        State.BodyVelocity:Destroy()
        State.BodyVelocity = nil
    end
    if State.BodyGyro then
        State.BodyGyro:Destroy()
        State.BodyGyro = nil
    end
    local _, hrp, hum = GetCharacter()
    if hum then
        hum.PlatformStand = false
    end
end

local function FlyToCFrame(targetCFrame)
    if not targetCFrame then return false end
    local char, hrp, hum = GetCharacter()
    if not char then return false end

    StopFlight()

    hum.PlatformStand = true

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bg.P = 9e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    State.BodyGyro = bg

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(4e5, 4e5, 4e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    State.BodyVelocity = bv

    local startTime = tick()
    local reached = false

    while State.IsFarming and (tick() - startTime < Config.StuckTimeout) do
        local currentChar, currentHrp, currentHum = GetCharacter()
        if not currentChar or currentHum.Health <= 0 then
            StopFlight()
            return false
        end

        local targetPos = targetCFrame.Position
        local currentPos = currentHrp.Position
        local delta = targetPos - currentPos
        local distance = delta.Magnitude

        if distance <= 3 then
            reached = true
            break
        end

        local direction = delta.Unit
        bv.Velocity = direction * Config.FlySpeed
        bg.CFrame = CFrame.new(currentPos, targetPos)

        task.wait()
    end

    StopFlight()
    return reached
end

------------------------------------------------------------------------
-- ANTI-AFK SYSTEM
------------------------------------------------------------------------
task.spawn(function()
    local Vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        Vu:Button2Down(Vector2.zero, Workspace.CurrentCamera.CFrame)
        task.wait(1)
        Vu:Button2Up(Vector2.zero, Workspace.CurrentCamera.CFrame)
    end)
end)

------------------------------------------------------------------------
-- VISUAL EFFECTS & WINGS
------------------------------------------------------------------------
local function ClearWings()
    if State.WingsModel then
        State.WingsModel:Destroy()
        State.WingsModel = nil
    end
end

local function CreateWings()
    ClearWings()
    if not Config.EnableWings then return end

    local char = GetCharacter()
    if not char then return end

    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then return end

    local model = Instance.new("Model")
    model.Name = "EnergyWings"

    local function buildFeather(size, cframeOffset)
        local part = Instance.new("Part")
        part.Size = size
        part.Material = Enum.Material.Neon
        part.Color = Config.EffectColor
        part.CanCollide = false
        part.Anchored = false

        local att = Instance.new("Attachment", part)
        local pe = Instance.new("ParticleEmitter", att)
        pe.Texture = "rbxassetid://243098098"
        pe.Color = ColorSequence.new(Config.EffectColor)
        pe.Size = NumberSequence.new(0.4, 0)
        pe.Lifetime = NumberRange.new(0.2, 0.4)
        pe.Rate = 20

        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = part
        weld.C0 = cframeOffset
        weld.Parent = part

        part.Parent = model
    end

    buildFeather(Vector3.new(0.3, 2.2, 0.3), CFrame.new(-1.2, 1, 0.5) * CFrame.Angles(0, 0, math.rad(-35)))
    buildFeather(Vector3.new(0.3, 1.8, 0.3), CFrame.new(-2.0, 1.6, 0.5) * CFrame.Angles(0, 0, math.rad(-55)))
    buildFeather(Vector3.new(0.3, 2.2, 0.3), CFrame.new(1.2, 1, 0.5) * CFrame.Angles(0, 0, math.rad(35)))
    buildFeather(Vector3.new(0.3, 1.8, 0.3), CFrame.new(2.0, 1.6, 0.5) * CFrame.Angles(0, 0, math.rad(55)))

    model.Parent = char
    State.WingsModel = model
end

local function UpdateVisualsColor(color)
    Config.EffectColor = color
    if State.WingsModel then
        for _, part in ipairs(State.WingsModel:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = color
                local att = part:FindFirstChildOfClass("Attachment")
                if att then
                    local pe = att:FindFirstChildOfClass("ParticleEmitter")
                    if pe then pe.Color = ColorSequence.new(color) end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- DAY / NIGHT DETECTION
------------------------------------------------------------------------
local function IsNightTime()
    local clock = Lighting.ClockTime
    return (clock >= 18 or clock < 6)
end

------------------------------------------------------------------------
-- EGG SCANNER & INTERACTION
------------------------------------------------------------------------
local function GetEggRarity(egg)
    local attr = tostring(
        egg:GetAttribute("Rarity")
        or egg:GetAttribute("EggType")
        or egg.Name
    )
    local lowerAttr = string.lower(attr)
    if string.find(lowerAttr, "divine") then return "Divine", 1 end
    if string.find(lowerAttr, "eternal") then return "Eternal", 2 end
    if string.find(lowerAttr, "secret") then return "Secret", 3 end
    return nil, 999
end

local function FindBestEgg()
    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if not eggsFolder then return nil, "None" end

    local char, hrp = GetCharacter()
    if not hrp then return nil, "None" end

    local bestEgg = nil
    local bestPriority = 999
    local bestRarity = "None"
    local shortestDist = math.huge

    for _, egg in ipairs(eggsFolder:GetDescendants()) do
        if egg.Parent and (egg:IsA("Model") or egg:IsA("BasePart")) then
            local rarity, priority = GetEggRarity(egg)
            if rarity and Config.Rarities[rarity] then
                local eggCFrame = GetTargetCFrame(egg)
                if eggCFrame then
                    local dist = (hrp.Position - eggCFrame.Position).Magnitude
                    if priority < bestPriority then
                        bestPriority = priority
                        bestEgg = egg
                        bestRarity = rarity
                        shortestDist = dist
                    elseif priority == bestPriority and dist < shortestDist then
                        bestEgg = egg
                        bestRarity = rarity
                        shortestDist = dist
                    end
                end
            end
        end
    end

    return bestEgg, bestRarity
end

local function InteractWithEgg(egg)
    if not egg or not egg.Parent then return false end

    local prompt = egg:FindFirstChildOfClass("ProximityPrompt") or egg:FindFirstChild("ProximityPrompt", true)
    if not prompt then
        for _, obj in ipairs(egg:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                prompt = obj
                break
            end
        end
    end

    if not prompt then return false end

    local holdTime = prompt.HoldDuration > 0 and prompt.HoldDuration or 0.5
    local elapsed = 0

    local firePromptApi = rawget(_G, "fireproximityprompt")
    local usingFirePrompt = type(firePromptApi) == "function"
    if usingFirePrompt then
        local ok = pcall(function()
            firePromptApi(prompt)
        end)
        if not ok then
            usingFirePrompt = false
        end
    end

    if not usingFirePrompt then
        local ok = pcall(function()
            prompt:InputHoldBegin()
        end)
        if not ok then
            State.HoldProgress = 0
            return false
        end
    end

    while State.IsFarming and elapsed < holdTime do
        local char, hrp, hum = GetCharacter()
        if not char or hum.Health <= 0 or not egg.Parent then
            if not usingFirePrompt then pcall(function() prompt:InputHoldEnd() end) end
            State.HoldProgress = 0
            return false
        end

        task.wait(0.1)
        elapsed = elapsed + 0.1
        State.HoldProgress = math.clamp(elapsed / holdTime, 0, 1)
    end

    if not usingFirePrompt then
        pcall(function() prompt:InputHoldEnd() end)
    end
    State.HoldProgress = 0

    if elapsed >= holdTime and egg.Parent then
        return true
    end
    return false
end

------------------------------------------------------------------------
-- TREADMILL INTERACTION
------------------------------------------------------------------------
local function MountTreadmill()
    local treadmill = Workspace:FindFirstChild("Treadmill", true)
    if not treadmill then
        State.TreadmillActive = false
        return false
    end

    local cf = GetTargetCFrame(treadmill)
    if not cf then
        State.TreadmillActive = false
        return false
    end

    local arrived = FlyToCFrame(cf)
    if not arrived or not State.IsFarming then
        State.TreadmillActive = false
        return false
    end

    State.TreadmillActive = true

    local char, hrp, hum = GetCharacter()
    if hum then
        local anim = treadmill:FindFirstChild("RunAnimation")
        if anim and anim:IsA("Animation") then
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            local track = animator:LoadAnimation(anim)
            track:Play()
        end
    end

    return true
end

local function DismountTreadmill()
    State.TreadmillActive = false
    local char, hrp, hum = GetCharacter()
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
    end
end

------------------------------------------------------------------------
-- CORE AUTO FARM LOOP
------------------------------------------------------------------------
local function RunFarmCycle()
    while State.IsFarming do
        local isNight = IsNightTime()
        State.IsNight = isNight

        if not isNight then
            State.NightCycleDoneThisNight = false
            State.CurrentStatus = "Daytime: On Treadmill"
            State.CurrentTarget = nil
            State.TargetRarity = "None"

            if not State.TreadmillActive then
                MountTreadmill()
            end
            task.wait(2)
        else
            if State.NightCycleDoneThisNight then
                State.CurrentStatus = "Night finished: On Treadmill"
                if not State.TreadmillActive then
                    MountTreadmill()
                end
                task.wait(2)
            else
                DismountTreadmill()

                local waitSpot = Workspace:FindFirstChild("WaitSpot", true)
                local safeZone = Workspace:FindFirstChild("SafeZone", true)

                if not waitSpot or not safeZone then
                    State.CurrentStatus = "Error: Missing Map Spots!"
                    task.wait(3)
                else
                    State.CurrentStatus = "Night: Flying to WaitSpot"
                    local arrivedWait = FlyToCFrame(GetTargetCFrame(waitSpot))

                    if arrivedWait and State.IsFarming then
                        State.CurrentStatus = "Waiting for Egg Respawn..."
                        task.wait(2)

                        State.CurrentStatus = "Scanning Eggs..."
                        local targetEgg, rarity = FindBestEgg()

                        local cycleCompleted = false

                        if targetEgg then
                            State.CurrentTarget = targetEgg
                            State.TargetRarity = rarity
                            State.CurrentStatus = "Flying to " .. rarity .. " Egg"

                            local eggCFrame = GetTargetCFrame(targetEgg)
                            local arrivedEgg = eggCFrame and FlyToCFrame(eggCFrame)

                            if arrivedEgg and targetEgg.Parent and State.IsFarming then
                                State.CurrentStatus = "Capturing Egg..."
                                local captured = InteractWithEgg(targetEgg)

                                if captured and State.IsFarming then
                                    State.CurrentStatus = "Flying to SafeZone"
                                    local safeCFrame = GetTargetCFrame(safeZone)
                                    local arrivedSafe = safeCFrame and FlyToCFrame(safeCFrame)

                                    if arrivedSafe and State.IsFarming then
                                        State.CurrentStatus = "Delivery Complete!"
                                        cycleCompleted = true
                                        task.wait(1)
                                    else
                                        State.CurrentStatus = "Delivery Failed! Retrying..."
                                    end
                                else
                                    State.CurrentStatus = "Capture Failed! Retrying..."
                                end
                            else
                                State.
                CurrentStatus = "Egg lost during flight! Retrying..."
                            end
                        else
                            State.CurrentStatus = "No target rarity found! Retrying..."
                        end
                    end

                    if cycleCompleted then
                        State.NightCycleDoneThisNight = true
                        State.CurrentTarget = nil
                        State.TargetRarity = "None"
                        MountTreadmill()
                    else
                        State.NightCycleDoneThisNight = false
                        State.CurrentTarget = nil
                        State.TargetRarity = "None"
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(0.5)
    end
    StopFlight()
    DismountTreadmill()
    ClearWings()
end

DIAG("4/6 reached farm definition")

local function StartAutoFarm()
    if State.IsFarming then return end
    State.IsFarming = true
    State.NightCycleDoneThisNight = false
    State.CurrentTarget = nil
    State.TargetRarity = "None"
    State.CurrentStatus = "Starting Auto Farm..."
    CreateWings()
    State.CurrentThread = task.spawn(RunFarmCycle)
end

local function StopAutoFarm()
    State.IsFarming = false
    State.CurrentStatus = "Stopped"
    State.CurrentTarget = nil
    State.TargetRarity = "None"
    State.HoldProgress = 0
    StopFlight()
    DismountTreadmill()
    ClearWings()
end

------------------------------------------------------------------------
-- MODERN MOBILE-FRIENDLY GUI SYSTEM
------------------------------------------------------------------------
DIAG("3/6 reached GUI definition")

local function BuildGUI()
    local oldGui = PlayerGui:FindFirstChild("StealEggGUI")
    if oldGui then oldGui:Destroy() end
    
    local oldCoreGui = CoreGui:FindFirstChild("StealEggGUI")
    if oldCoreGui then pcall(function() oldCoreGui:Destroy() end) end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggGUI"
    ScreenGui.ResetOnSpawn = false
    
    -- Safe GUI parenting. Executor-specific APIs are optional and protected.
    local parented = false

    local gethuiApi = rawget(_G, "gethui")
    if type(gethuiApi) == "function" then
        local ok, hui = pcall(gethuiApi)
        if ok and hui then
            local setOk = pcall(function()
                ScreenGui.Parent = hui
            end)
            parented = setOk and ScreenGui.Parent ~= nil
        end
    end

    local synApi = rawget(_G, "syn")
    if not parented and type(synApi) == "table" and type(synApi.protect_gui) == "function" then
        local ok = pcall(function()
            synApi.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        end)
        parented = ok and ScreenGui.Parent ~= nil
    end

    if not parented then
        local ok = pcall(function()
            ScreenGui.Parent = PlayerGui
        end)
        parented = ok and ScreenGui.Parent ~= nil
    end

    if not parented or not ScreenGui.Parent then
        return false
    end

    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true

    -- Floating Open/Close Icon
    local ToggleIcon = Instance.new("TextButton")
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
    ToggleIcon.Position = UDim2.new(0, 15, 0.4, 0)
    ToggleIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    ToggleIcon.Text = "EGG"
    ToggleIcon.TextColor3 = Config.EffectColor
    ToggleIcon.Font = Enum.Font.GothamBold
    ToggleIcon.TextSize = 14
    ToggleIcon.Visible = false
    ToggleIcon.Parent = ScreenGui
    Instance.new("UICorner", ToggleIcon).CornerRadius = UDim.new(0, 12)

    local strokeIcon = Instance.new("UIStroke", ToggleIcon)
    strokeIcon.Color = Config.EffectColor
    strokeIcon.Thickness = 2

    -- Main Container Window
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -220)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Config.EffectColor
    mainStroke.Thickness = 2

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundTransparency = 1
    Header.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "STEAL AN EGG: HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -40, 0, 5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.Parent = Header

    -- Scroll Area
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -20, 1, -55)
    Scroll.Position = UDim2.new(0, 10, 0, 45)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 520)
    Scroll.Parent = MainFrame

    local layout = Instance.new("UIListLayout", Scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)

    -- Start/Stop Toggle Button
    local StartBtn = Instance.new("TextButton")
    StartBtn.Size = UDim2.new(1, 0, 0, 45)
    StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
    StartBtn.Text = "START AUTO FARM"
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 15
    StartBtn.LayoutOrder = 1
    StartBtn.Parent = Scroll
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 10)

    -- Status Dashboard Panel
    local StatusBox = Instance.new("Frame")
    StatusBox.Size = UDim2.new(1, 0, 0, 110)
    StatusBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    StatusBox.LayoutOrder = 2
    StatusBox.Parent = Scroll
    Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 10)

    local function createStatusLabel(pos, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = pos
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = StatusBox
        return lbl
    end

    local lblStatus = createStatusLabel(UDim2.new(0, 10, 0, 8), "Status: Idle")
    local lblTarget = createStatusLabel(UDim2.new(0, 10, 0, 28), "Target: None")
    local lblRarity = createStatusLabel(UDim2.new(0, 10, 0, 48), "Rarity: None")
    local lblTime = createStatusLabel(UDim2.new(0, 10, 0, 68), "Time: Daytime")
    local lblHold = createStatusLabel(UDim2.new(0, 10, 0, 88), "Hold Progress: 0%")

    -- Rarity Toggles
    local RarityBox = Instance.new("Frame")
    RarityBox.Size = UDim2.new(1, 0, 0, 50)
    RarityBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    RarityBox.LayoutOrder = 3
    RarityBox.Parent = Scroll
    Instance.new("UICorner", RarityBox).CornerRadius = UDim.new(0, 10)

    local function createRarityToggle(name, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 85, 0, 32)
        btn.Position = UDim2.new(0, posX, 0, 9)
        btn.BackgroundColor3 = Config.Rarities[name] and Color3.fromRGB(40, 140, 90) or Color3.fromRGB(50, 50, 60)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = RarityBox
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            Config.Rarities[name] = not Config.Rarities[name]
            btn.BackgroundColor3 = Config.Rarities[name] and Color3.fromRGB(40, 140, 90) or Color3.fromRGB(50, 50, 60)
        end)
    end

    createRarityToggle("Divine", 10)
    createRarityToggle("Eternal", 105)
    createRarityToggle("Secret", 200)

    -- Fly Speed Slider
    local SpeedBox = Instance.new("Frame")
    SpeedBox.Size = UDim2.new(1, 0, 0, 60)
    SpeedBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    SpeedBox.LayoutOrder = 4
    SpeedBox.Parent = Scroll
    Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 10)

    local SpeedLbl = Instance.new("TextLabel")
    SpeedLbl.Size = UDim2.new(1, -20, 0, 20)
    SpeedLbl.Position = UDim2.new(0, 10, 0, 5)
    SpeedLbl.BackgroundTransparency = 1
    SpeedLbl.Text = "Fly Speed: " .. tostring(Config.FlySpeed)
    SpeedLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    SpeedLbl.Font = Enum.Font.Gotham
    SpeedLbl.TextSize = 12
    SpeedLbl.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLbl.Parent = SpeedBox

    local SpeedSlider = Instance.new("TextButton")
    SpeedSlider.Size = UDim2.new(1, -20, 0, 20)
    SpeedSlider.Position = UDim2.new(0, 10, 0, 30)
    SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    SpeedSlider.Text = ""
    SpeedSlider.Parent = SpeedBox
    Instance.new("UICorner", SpeedSlider).CornerRadius = UDim.new(0, 6)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(Config.FlySpeed / 150, 0, 1, 0)
    Fill.BackgroundColor3 = Config.EffectColor
    Fill.BorderSizePixel = 0
    Fill.Parent = SpeedSlider
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 6)

    local dragging = false
    local function updateSpeed(input)
        local pos = math.clamp((input.Position.X - SpeedSlider.AbsolutePosition.X) / SpeedSlider.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Config.FlySpeed = math.floor(20 + (pos * 130))
        SpeedLbl.Text = "Fly Speed: " .. tostring(Config.FlySpeed)
    end

    SpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSpeed(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSpeed(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Wings & Color Themes
    local VisualsBox = Instance.new("Frame")
    VisualsBox.Size = UDim2.new(1, 0, 0, 80)
    VisualsBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    VisualsBox.LayoutOrder = 5
    VisualsBox.Parent = Scroll
    Instance.new("UICorner", VisualsBox).CornerRadius = UDim.new(0, 10)

    local WingsBtn = Instance.new("TextButton")
    WingsBtn.Size = UDim2.new(1, -20, 0, 30)
    WingsBtn.Position = UDim2.new(0, 10, 0, 8)
    WingsBtn.BackgroundColor3 = Config.EnableWings and Color3.fromRGB(40, 140, 90) or Color3.fromRGB(50, 50, 60)
    WingsBtn.Text = "Visual Wings: " .. (Config.EnableWings and "ENABLED" or "DISABLED")
    WingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    WingsBtn.Font = Enum.Font.GothamBold
    WingsBtn.TextSize = 12
    WingsBtn.Parent = VisualsBox
    Instance.new("UICorner", WingsBtn).CornerRadius = UDim.new(0, 6)

    WingsBtn.MouseButton1Click:Connect(function()
        Config.EnableWings = not Config.EnableWings
        WingsBtn.Text = "Visual Wings: " .. (Config.EnableWings and "ENABLED" or "DISABLED")
        WingsBtn.BackgroundColor3 = Config.EnableWings and Color3.fromRGB(40, 140, 90) or Color3.fromRGB(50, 50, 60)
        if State.IsFarming then
            if Config.EnableWings then CreateWings() else ClearWings() end
        end
    end)

    local colors = {
        Color3.fromRGB(0, 255, 200),
        Color3.fromRGB(255, 50, 100),
        Color3.fromRGB(255, 200, 0),
        Color3.fromRGB(150, 50, 255)
    }

    for i, col in ipairs(colors) do
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0, 60, 0, 25)
        cBtn.Position = UDim2.new(0, 10 + (i - 1) * 70, 0, 46)
        cBtn.BackgroundColor3 = col
        cBtn.Text = ""
        cBtn.Parent = VisualsBox
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 5)

        cBtn.MouseButton1Click:Connect(function()
            UpdateVisualsColor(col)
            mainStroke.Color = col
            strokeIcon.Color = col
            ToggleIcon.TextColor3 = col
            Fill.BackgroundColor3 = col
        end)
    end

    -- Update UI Loop
    task.spawn(function()
        while task.wait(0.2) do
            if ScreenGui and ScreenGui.Parent then
                lblStatus.Text = "Status: " .. State.CurrentStatus
                lblTarget.Text = "Target: " .. (State.CurrentTarget and State.CurrentTarget.Name or "None")
                lblRarity.Text = "Rarity: " .. State.TargetRarity
                lblTime.Text = "Time: " .. (State.IsNight and "Nighttime 🌙" or "Daytime ☀️")
                lblHold.Text = "Hold Progress: " .. tostring(math.floor(State.HoldProgress * 100)) .. "%"
            end
        end
    end)

    -- Event Listeners
    StartBtn.MouseButton1Click:Connect(function()
        if State.IsFarming then
            StopAutoFarm()
            StartBtn.Text = "START AUTO FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
        else
            StartAutoFarm()
            StartBtn.Text = "STOP AUTO FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        ToggleIcon.Visible = true
    end)

    ToggleIcon.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        ToggleIcon.Visible = false
    end)

    return true
end

------------------------------------------------------------------------
-- CHARACTER RESPAWN HANDLER & INITIALIZATION
------------------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    StopAutoFarm()
    task.wait(1)
    local traceback = function(err)
        return tostring(err)
    end
    if type(debug) == "table" and type(debug.traceback) == "function" then
        traceback = debug.traceback
    end

    local ok, err = xpcall(BuildGUI, traceback)
    if not ok then
        warn("[StealEgg] GUI error after respawn:\n" .. tostring(err))
    end
end)

do
    -- Visible startup marker: if this appears, the script reached initialization.
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = "STEAL EGG",
            Text = "Script started — building GUI...",
            Duration = 4
        })
    end)

    local traceback = function(err)
        return tostring(err)
    end
    if type(debug) == "table" and type(debug.traceback) == "function" then
        traceback = debug.traceback
    end

    local ok, err = xpcall(BuildGUI, traceback)
    if not ok then
        warn("[StealEgg] Startup error:\n" .. tostring(err))
    else
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("SendNotification", {
                Title = "STEAL EGG",
                Text = "GUI loaded successfully.",
                Duration = 4
            })
        end)
        pcall(function()
            local gui = Instance.new("ScreenGui")
            gui.Name = "StealEggStartupError"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 10000
            gui.Parent = PlayerGui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 0, 90)
            label.Position = UDim2.new(0, 15, 0, 30)
            label.BackgroundTransparency = 0.1
            label.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextWrapped = true
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = "STEAL EGG ERROR\n" .. tostring(err)
            label.Parent = gui
            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)
        end)
    end
end
