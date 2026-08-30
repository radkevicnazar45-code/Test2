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
                State.CurrentStatus = "Egg lost during flight! Retrying..."
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
local function BuildGUI()
    local oldGui = PlayerGui:FindFirstChild("StealEggGUI")
    if oldGui then oldGui:Destroy() end

    local oldCoreGui = CoreGui:FindFirstChild("StealEggGUI")
    if oldCoreGui then pcall(function() oldCoreGui:Destroy() end) end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Prefer normal PlayerGui first; fall back to executor GUI containers.
    local parented = pcall(function() ScreenGui.Parent = PlayerGui end)
    if not parented or not ScreenGui.Parent then
        local gethuiApi = rawget(_G, "gethui")
        if type(gethuiApi) == "function" then
            local ok, hui = pcall(gethuiApi)
            if ok and hui then
                parented = pcall(function() ScreenGui.Parent = hui end)
            end
        end
    end
    if (not parented or not ScreenGui.Parent) and CoreGui then
        parented = pcall(function() ScreenGui.Parent = CoreGui end)
    end
    if not ScreenGui.Parent then return false end

    local function corner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = obj
        return c
    end

    local function stroke(obj, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = obj
        return s
    end

    local function label(parent, text, size, position, fontSize, color)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(235, 238, 245)
        l.Font = Enum.Font.Gotham
        l.TextSize = fontSize or 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Size = size
        l.Position = position
        l.Parent = parent
        return l
    end

    local accent = Config.EffectColor

    -- Compact mobile window.
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0.82, 0, 0, 455)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 15, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    corner(MainFrame, 18)
    local mainStroke = stroke(MainFrame, accent, 1.5, 0.25)

    local maxSize = Instance.new("UISizeConstraint")
    maxSize.MaxSize = Vector2.new(390, 560)
    maxSize.MinSize = Vector2.new(285, 390)
    maxSize.Parent = MainFrame

    -- Header.
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 58)
    Header.BackgroundColor3 = Color3.fromRGB(19, 22, 31)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    corner(Header, 18)

    local Title = label(Header, "STEAL AN EGG", UDim2.new(1, -90, 0, 23), UDim2.new(0, 18, 0, 8), 17, Color3.fromRGB(255,255,255))
    Title.Font = Enum.Font.GothamBold
    label(Header, "AUTO FARM HUB", UDim2.new(1, -90, 0, 18), UDim2.new(0, 18, 0, 30), 10, Color3.fromRGB(150,158,175))

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 38, 0, 38)
    CloseBtn.Position = UDim2.new(1, -48, 0, 10)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(34, 37, 48)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(220,225,235)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 22
    CloseBtn.Parent = Header
    corner(CloseBtn, 12)

    -- Dragging for touch + mouse.
    local dragging = false
    local dragStart, startPos
    local dragInput
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            dragInput = input
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -20, 1, -68)
    Scroll.Position = UDim2.new(0, 10, 0, 62)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = accent
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new()
    Scroll.Parent = MainFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = Scroll

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 9)
    layout.Parent = Scroll

    local function panel(height, order)
        local p = Instance.new("Frame")
        p.Size = UDim2.new(1, 0, 0, height)
        p.BackgroundColor3 = Color3.fromRGB(21, 24, 33)
        p.BorderSizePixel = 0
        p.LayoutOrder = order
        p.Parent = Scroll
        corner(p, 13)
        stroke(p, Color3.fromRGB(48, 52, 66), 1, 0.35)
        return p
    end

    -- Main farm button.
    local StartBtn = Instance.new("TextButton")
    StartBtn.Size = UDim2.new(1, 0, 0, 50)
    StartBtn.BackgroundColor3 = Color3.fromRGB(38, 154, 104)
    StartBtn.Text = "▶  START AUTO FARM"
    StartBtn.TextColor3 = Color3.fromRGB(255,255,255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 14
    StartBtn.LayoutOrder = 1
    StartBtn.Parent = Scroll
    corner(StartBtn, 13)

    local statusPanel = panel(118, 2)
    label(statusPanel, "STATUS", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,8), 10, Color3.fromRGB(135,145,165)).Font = Enum.Font.GothamBold
    local lblStatus = label(statusPanel, "Idle", UDim2.new(1,-24,0,22), UDim2.new(0,12,0,27), 13)
    local lblTarget = label(statusPanel, "Target: None", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,52), 11, Color3.fromRGB(180,187,200))
    local lblRarity = label(statusPanel, "Rarity: None", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,72), 11, Color3.fromRGB(180,187,200))
    local lblTime = label(statusPanel, "☀ Daytime", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,92), 11, Color3.fromRGB(180,187,200))

    local rarityPanel = panel(78, 3)
    label(rarityPanel, "TARGET RARITIES", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,7), 10, Color3.fromRGB(135,145,165)).Font = Enum.Font.GothamBold

    local function createRarityToggle(name, x)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, -4, 0, 35)
        btn.Position = UDim2.new(x, 0, 0, 32)
        btn.BackgroundColor3 = Config.Rarities[name] and Color3.fromRGB(38, 154, 104) or Color3.fromRGB(45, 48, 59)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = rarityPanel
        corner(btn, 9)
        btn.MouseButton1Click:Connect(function()
            Config.Rarities[name] = not Config.Rarities[name]
            btn.BackgroundColor3 = Config.Rarities[name] and Color3.fromRGB(38,154,104) or Color3.fromRGB(45,48,59)
        end)
    end
    createRarityToggle("Divine", 0.02)
    createRarityToggle("Eternal", 0.35)
    createRarityToggle("Secret", 0.68)

    local speedPanel = panel(84, 4)
    local SpeedLbl = label(speedPanel, "FLY SPEED  •  " .. tostring(Config.FlySpeed), UDim2.new(1,-24,0,18), UDim2.new(0,12,0,8), 10, Color3.fromRGB(135,145,165))
    SpeedLbl.Font = Enum.Font.GothamBold

    local SpeedSlider = Instance.new("TextButton")
    SpeedSlider.Size = UDim2.new(1,-24,0,22)
    SpeedSlider.Position = UDim2.new(0,12,0,37)
    SpeedSlider.BackgroundColor3 = Color3.fromRGB(42,45,57)
    SpeedSlider.Text = ""
    SpeedSlider.AutoButtonColor = false
    SpeedSlider.Parent = speedPanel
    corner(SpeedSlider, 8)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(math.clamp(Config.FlySpeed / 150, 0, 1), 0, 1, 0)
    Fill.BackgroundColor3 = accent
    Fill.BorderSizePixel = 0
    Fill.Parent = SpeedSlider
    corner(Fill, 8)

    local draggingSpeed = false
    local function updateSpeed(input)
        local width = math.max(SpeedSlider.AbsoluteSize.X, 1)
        local pos = math.clamp((input.Position.X - SpeedSlider.AbsolutePosition.X) / width, 0, 1)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Config.FlySpeed = math.floor(20 + pos * 130)
        SpeedLbl.Text = "FLY SPEED  •  " .. tostring(Config.FlySpeed)
    end
    SpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSpeed = true
            updateSpeed(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSpeed(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSpeed = false
        end
    end)

    local visualPanel = panel(112, 5)
    label(visualPanel, "VISUALS", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,7), 10, Color3.fromRGB(135,145,165)).Font = Enum.Font.GothamBold

    local WingsBtn = Instance.new("TextButton")
    WingsBtn.Size = UDim2.new(1,-24,0,34)
    WingsBtn.Position = UDim2.new(0,12,0,30)
    WingsBtn.BackgroundColor3 = Config.EnableWings and Color3.fromRGB(38,154,104) or Color3.fromRGB(45,48,59)
    WingsBtn.Text = "WINGS  •  " .. (Config.EnableWings and "ON" or "OFF")
    WingsBtn.TextColor3 = Color3.fromRGB(255,255,255)
    WingsBtn.Font = Enum.Font.GothamBold
    WingsBtn.TextSize = 11
    WingsBtn.Parent = visualPanel
    corner(WingsBtn, 9)

    WingsBtn.MouseButton1Click:Connect(function()
        Config.EnableWings = not Config.EnableWings
        WingsBtn.Text = "WINGS  •  " .. (Config.EnableWings and "ON" or "OFF")
        WingsBtn.BackgroundColor3 = Config.EnableWings and Color3.fromRGB(38,154,104) or Color3.fromRGB(45,48,59)
        if State.IsFarming then
            if Config.EnableWings then CreateWings() else ClearWings() end
        end
    end)

    local colors = {
        Color3.fromRGB(0, 255, 200),
        Color3.fromRGB(255, 70, 115),
        Color3.fromRGB(255, 195, 45),
        Color3.fromRGB(155, 80, 255)
    }

    for i, col in ipairs(colors) do
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0, 42, 0, 22)
        cBtn.Position = UDim2.new(0, 14 + (i-1)*49, 0, 75)
        cBtn.BackgroundColor3 = col
        cBtn.Text = ""
        cBtn.Parent = visualPanel
        corner(cBtn, 7)
        cBtn.MouseButton1Click:Connect(function()
            UpdateVisualsColor(col)
            accent = col
            mainStroke.Color = col
            Fill.BackgroundColor3 = col
            Scroll.ScrollBarImageColor3 = col
        end)
    end

    local lblHold = label(Scroll, "Hold Progress: 0%", UDim2.new(1,0,0,18), UDim2.new(), 10, Color3.fromRGB(120,128,145))
    lblHold.LayoutOrder = 6

    local ToggleIcon = Instance.new("TextButton")
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.AnchorPoint = Vector2.new(0, 0.5)
    ToggleIcon.Size = UDim2.new(0, 52, 0, 52)
    ToggleIcon.Position = UDim2.new(0, 14, 0.5, 0)
    ToggleIcon.BackgroundColor3 = Color3.fromRGB(19,22,31)
    ToggleIcon.Text = "EGG"
    ToggleIcon.TextColor3 = accent
    ToggleIcon.Font = Enum.Font.GothamBold
    ToggleIcon.TextSize = 12
    ToggleIcon.Visible = false
    ToggleIcon.Parent = ScreenGui
    corner(ToggleIcon, 15)
    local iconStroke = stroke(ToggleIcon, accent, 1.5, 0.15)

    StartBtn.MouseButton1Click:Connect(function()
        if State.IsFarming then
            StopAutoFarm()
            StartBtn.Text = "▶  START AUTO FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(38,154,104)
        else
            StartAutoFarm()
            StartBtn.Text = "■  STOP AUTO FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(194,62,74)
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

    task.spawn(function()
        while ScreenGui.Parent do
            task.wait(0.2)
            if lblStatus.Parent then
                lblStatus.Text = State.CurrentStatus or "Idle"
                lblTarget.Text = "Target: " .. (State.CurrentTarget and State.CurrentTarget.Name or "None")
                lblRarity.Text = "Rarity: " .. (State.TargetRarity or "None")
                lblTime.Text = State.IsNight and "☾ Nighttime" or "☀ Daytime"
                lblHold.Text = "Hold Progress: " .. tostring(math.floor((State.HoldProgress or 0) * 100)) .. "%"
            else
                break
            end
        end
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
