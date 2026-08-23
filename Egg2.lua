-- Kecuya Hub | Steal An Egg (Game-Adapted & Production-Ready)
-- Owner: @kecuya
-- Mobile & PC Fully Supported

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Kecuya Hub | Steal An Egg",
    LoadingTitle = "Initializing Kecuya Hub...",
    LoadingSubtitle = "by @kecuya",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- ==================== SETTINGS & CONFIG ====================
local Settings = {
    AutoSteal = false,
    PrioritizeBest = true,
    TargetRarity = "All",
    TargetMutation = "All",
    TargetLocation = "All",
    FlightSpeed = 85,
    SafeHeight = 18
}

local RarityList = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
local MutationList = {"All", "None", "Golden", "Rainbow", "Shiny"}
local LocationList = {"All", "Spawn", "Desert", "Volcano", "Cyber", "Ocean"}

local RarityMultiplier = {
    ["Common"] = 1, ["Uncommon"] = 1.5, ["Rare"] = 2.5,
    ["Epic"] = 5, ["Legendary"] = 10, ["Mythic"] = 25, ["Divine"] = 100
}

local MutationMultiplier = {
    ["None"] = 1, ["Shiny"] = 2, ["Golden"] = 3.5, ["Rainbow"] = 7
}

-- ==================== STATE MANAGEMENT ====================
local CurrentTaskThread = nil
local LinearVelocity, AlignOrientation, Attachment
local StealRemote = nil

-- ==================== ANTI-AFK (BACKGROUND) ====================
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- ==================== LOCATE GAME REMOTES ====================
local function FindStealRemote()
    if StealRemote and StealRemote.Parent then return StealRemote end
    
    local packages = ReplicatedStorage:FindFirstChild("Packages") or ReplicatedStorage:FindFirstChild("Remotes")
    if packages then
        StealRemote = packages:FindFirstChild("StealEgg", true) or packages:FindFirstChild("GrabEgg", true)
    end
    if not StealRemote then
        StealRemote = ReplicatedStorage:FindFirstChild("StealEgg", true) or ReplicatedStorage:FindFirstChild("GrabEgg", true)
    end
    return StealRemote
end

-- ==================== LOCATE CONTAINERS & PLAYER BASE ====================
local function GetEggContainer()
    return Workspace:FindFirstChild("ActiveEggs") 
        or Workspace:FindFirstChild("Eggs") 
        or Workspace:FindFirstChild("SpawnedEggs") 
        or Workspace:FindFirstChild("Spawns") 
        or Workspace
end

local function GetPlayerPlot()
    local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            local ownerAttr = plot:GetAttribute("Owner") or (plot:FindFirstChild("Owner") and plot.Owner.Value)
            if ownerAttr and (tostring(ownerAttr) == LocalPlayer.Name or tostring(ownerAttr) == tostring(LocalPlayer.UserId)) then
                return plot
            end
        end
    end
    return nil
end

local function GetSafeZoneCFrame()
    local plot = GetPlayerPlot()
    if plot then
        local delivery = plot:FindFirstChild("DeliveryZone", true) 
            or plot:FindFirstChild("Deposit", true) 
            or plot:FindFirstChild("Base", true) 
            or plot.PrimaryPart 
            or plot:FindFirstChildWhichIsA("BasePart", true)
        if delivery then
            return delivery.CFrame + Vector3.new(0, Settings.SafeHeight, 0)
        end
    end

    local globalSpawn = Workspace:FindFirstChild("SpawnLocation", true) or Workspace:FindFirstChild("SafeZone", true)
    if globalSpawn and globalSpawn:IsA("BasePart") then
        return globalSpawn.CFrame + Vector3.new(0, Settings.SafeHeight, 0)
    end

    return CFrame.new(0, Settings.SafeHeight + 20, 0)
end

-- ==================== EGG EVALUATION & FILTERING ====================
local function GetEggData(eggObj)
    local rarity = eggObj:GetAttribute("Rarity") 
        or (eggObj:FindFirstChild("Rarity") and eggObj.Rarity.Value) 
        or "Common"
    local mutation = eggObj:GetAttribute("Mutation") 
        or (eggObj:FindFirstChild("Mutation") and eggObj.Mutation.Value) 
        or "None"
    local location = eggObj:GetAttribute("Location") 
        or (eggObj.Parent and eggObj.Parent.Name) 
        or "Spawn"
    local rawValue = eggObj:GetAttribute("Value") 
        or (eggObj:FindFirstChild("Value") and eggObj.Value.Value) 
        or 1

    return tostring(rarity), tostring(mutation), tostring(location), tonumber(rawValue) or 1
end

local function MatchesFilter(rarity, mutation, location)
    if Settings.TargetLocation ~= "All" and not string.find(location:lower(), Settings.TargetLocation:lower()) then
        return false
    end
    if Settings.TargetRarity ~= "All" and not string.find(rarity:lower(), Settings.TargetRarity:lower()) then
        return false
    end
    if Settings.TargetMutation ~= "All" and not string.find(mutation:lower(), Settings.TargetMutation:lower()) then
        return false
    end
    return true
end

local function GetBestTargetEgg()
    local container = GetEggContainer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local bestEgg = nil
    local maxWeight = -1

    for _, obj in pairs(container:GetChildren()) do
        if not obj or not obj.Parent then continue end
        
        local isEggModel = obj:IsA("Model") or obj:IsA("BasePart")
        if isEggModel then
            local rarity, mutation, location, baseValue = GetEggData(obj)
            if MatchesFilter(rarity, mutation, location) then
                local eggPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if eggPart then
                    local dist = (hrp.Position - eggPart.Position).Magnitude
                    
                    local rMult = RarityMultiplier[rarity] or 1
                    local mMult = MutationMultiplier[mutation] or 1
                    
                    local weight = (baseValue * rMult * mMult) / math.max(dist * 0.05, 1)
                    if not Settings.PrioritizeBest then
                        weight = 10000 / math.max(dist, 1)
                    end

                    if weight > maxWeight then
                        maxWeight = weight
                        bestEgg = obj
                    end
                end
            end
        end
    end

    return bestEgg
end

-- ==================== FLIGHT CONTROLLER (AUTONOMOUS) ====================
local function SetupFlightPhysics()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not Attachment or Attachment.Parent ~= hrp then
        Attachment = Instance.new("Attachment", hrp)
    end

    if not LinearVelocity or LinearVelocity.Parent ~= hrp then
        LinearVelocity = Instance.new("LinearVelocity")
        LinearVelocity.MaxForce = 1e9
        LinearVelocity.VectorVelocity = Vector3.zero
        LinearVelocity.Attachment0 = Attachment
        LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        LinearVelocity.Parent = hrp
    end

    if not AlignOrientation or AlignOrientation.Parent ~= hrp then
        AlignOrientation = Instance.new("AlignOrientation")
        AlignOrientation.MaxTorque = 1e9
        AlignOrientation.Responsiveness = 200
        AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AlignOrientation.Attachment0 = Attachment
        AlignOrientation.CFrame = hrp.CFrame
        AlignOrientation.Parent = hrp
    end
end

local function CleanupFlightPhysics()
    if LinearVelocity then LinearVelocity:Destroy() LinearVelocity = nil end
    if AlignOrientation then AlignOrientation:Destroy() AlignOrientation = nil end
    if Attachment then Attachment:Destroy() Attachment = nil end
end

local function FlyToTarget(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    SetupFlightPhysics()

    while Settings.AutoSteal and char and hrp and humanoid and humanoid.Health > 0 do
        local currentPos = hrp.Position
        local targetPos = targetCFrame.Position
        local delta = (targetPos - currentPos)
        local distance = delta.Magnitude

        if distance <= 2.5 then
            LinearVelocity.VectorVelocity = Vector3.zero
            break
        end

        local direction = delta.Unit
        LinearVelocity.VectorVelocity = direction * math.min(Settings.FlightSpeed, distance * 5)
        AlignOrientation.CFrame = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))

        task.wait(0.03)
    end

    return true
end

-- ==================== INTERACTION & STEAL VERIFICATION ====================
local function ExecuteStealInteraction(eggObj)
    if not eggObj or not eggObj.Parent then return false end

    -- 1. Try Remote Event Interaction
    local remote = FindStealRemote()
    if remote then
        pcall(function() remote:FireServer(eggObj) end)
        pcall(function() remote:InvokeServer(eggObj) end)
    end

    -- 2. Try ProximityPrompt
    local prompt = eggObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        fireproximityprompt(prompt)
    end

    -- 3. Try Direct Touch Interaction
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local eggPart = eggObj:IsA("BasePart") and eggObj or eggObj.PrimaryPart or eggObj:FindFirstChildWhichIsA("BasePart", true)

    if hrp and eggPart then
        firetouchinterest(hrp, eggPart, 0)
        task.wait(0.05)
        firetouchinterest(hrp, eggPart, 1)
    end

    task.wait(0.3)

    -- Verification check: Carried Object or Removed Egg
    local isCarrying = char:FindFirstChild("CarriedEgg") or char:FindFirstChildOfClass("Tool")
    local isRemoved = (eggObj.Parent == nil)

    return isCarrying ~= nil or isRemoved
end

-- ==================== CORE AUTO-STEAL CYCLE ====================
local function StopAutoFarm()
    if CurrentTaskThread then
        task.cancel(CurrentTaskThread)
        CurrentTaskThread = nil
    end
    CleanupFlightPhysics()
end

local function StartAutoFarm()
    StopAutoFarm()

    CurrentTaskThread = task.spawn(function()
        while Settings.AutoSteal do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not hrp or not humanoid or humanoid.Health <= 0 then
                CleanupFlightPhysics()
                task.wait(1)
                continue
            end

            -- 1. SCAN & SELECT BEST EGG
            local targetEgg = GetBestTargetEgg()

            if targetEgg and targetEgg.Parent then
                local eggPart = targetEgg:IsA("BasePart") and targetEgg or targetEgg.PrimaryPart or targetEgg:FindFirstChildWhichIsA("BasePart", true)
                
                if eggPart then
                    local eggPos = eggPart.Position

                    -- 2. FLY TO EGG AT SAFE HEIGHT
                    local approachPos = CFrame.new(eggPos + Vector3.new(0, Settings.SafeHeight, 0))
                    FlyToTarget(approachPos)

                    -- 3. DESCEND & STEAL
                    if Settings.AutoSteal and targetEgg and targetEgg.Parent then
                        local grabPos = CFrame.new(eggPos + Vector3.new(0, 2, 0))
                        FlyToTarget(grabPos)
                        
                        -- 4. VERIFY STEAL
                        ExecuteStealInteraction(targetEgg)
                    end
                end
            end

            -- 5. FLY TO SAFE ZONE / BASE
            if Settings.AutoSteal then
                local safeCFrame = GetSafeZoneCFrame()
                FlyToTarget(safeCFrame)
                
                -- Verify Delivery / Return Wait
                task.wait(0.4)
            end

            task.wait(0.1)
        end
        CleanupFlightPhysics()
    end)
end

-- Auto-Recovery on Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    if Settings.AutoSteal then
        task.wait(1.5)
        StartAutoFarm()
    end
end)

-- ==================== KECUYA HUB GUI ====================

local MainTab = Window:CreateTab("Auto-Farm", 4483362458)
local FilterTab = Window:CreateTab("Filters", 4483362458)
local ConfigTab = Window:CreateTab("Flight Settings", 4483362458)

MainTab:CreateToggle({
    Name = "Enable Auto-Steal Cycle",
    CurrentValue = false,
    Callback = function(Value)
        Settings.AutoSteal = Value
        if Value then
            StartAutoFarm()
        else
            StopAutoFarm()
        end
    end
})

MainTab:CreateToggle({
    Name = "Prioritize Best Value Eggs",
    CurrentValue = true,
    Callback = function(Value)
        Settings.PrioritizeBest = Value
    end
})

FilterTab:CreateDropdown({
    Name = "Target Location",
    Options = LocationList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetLocation = Option
    end
})

FilterTab:CreateDropdown({
    Name = "Target Rarity",
    Options = RarityList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetRarity = Option
    end
})

FilterTab:CreateDropdown({
    Name = "Target Mutation",
    Options = MutationList,
    CurrentOption = "All",
    Callback = function(Option)
        Settings.TargetMutation = Option
    end
})

ConfigTab:CreateSlider({
    Name = "Flight Speed",
    Range = {30, 150},
    Increment = 5,
    CurrentValue = 85,
    Callback = function(Value)
        Settings.FlightSpeed = Value
    end
})

ConfigTab:CreateSlider({
    Name = "Safe Travel Height",
    Range = {5, 40},
    Increment = 1,
    CurrentValue = 18,
    Callback = function(Value)
        Settings.SafeHeight = Value
    end
})

Rayfield:Notify({
    Title = "Kecuya Hub Active",
    Content = "Скрипт полностью адаптирован под механики Steal an Egg!",
    Duration = 4,
    Image = 4483362458
})
