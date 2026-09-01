--// TRAINING COMBAT HUD V17 - ANIME IMAGE BACKGROUND
--// For your own Roblox Studio experience.
--// LocalScript -> StarterPlayer > StarterPlayerScripts
--//
--// FIXES:
--// 1) Player ESP
--// 2) AIM uses the Test4-style camera method
--// 3) Sticky target: when target leaves FOV it is released without a forced jump
--// 4) Team Check works for players
--// 5) R6/R15 target point fallback
--// 6) CurrentCamera is reacquired continuously, including Lobby -> Match camera changes
--// 7) GUI survives character respawn
--// 8) Visual presets do not destroy the game's existing Sky
--// 9) Screen zoom uses FOV instead of forcing a third-person camera
--//
--// IMPORTANT FOR A TRUE TELEPORT TO ANOTHER PLACE:
--// Put this LocalScript in StarterPlayerScripts of EVERY place
--// (Lobby place AND Match place). A LocalScript cannot execute in a
--// different Roblox place unless that place also contains it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local CFG = {
	AimEnabled = true,
	ESPEnabled = true,
	TeamCheck = true,
	VisibleCheck = true,

	AimFOV = 105,
	AimDistance = 650,
	AimStrength = 0.72,
	ReacquireTime = 0.06,
	AimHeadBias = 0.72,

		-- ESP
	ESPMaxDistance = 1200,

	-- Screen zoom. This changes FOV, not camera mode.
	ScreenZoomEnabled = false,
	ScreenFOV = 78,

	-- Visuals
	VisualsEnabled = true,
	VisualPreset = "SUNSET",
	KillSoundEnabled = true,
	KillSoundId = "rbxassetid://8857409671",
	KillSoundVolume = 0.85,
	UseExistingSky = true,

	-- Upload the provided anime image to Roblox and paste its asset id here.
	AnimeBackgroundImage = "rbxassetid://105131757272307",
	AnimeBackgroundTransparency = 0.22,

	BoxColor = Color3.fromRGB(174, 92, 255),
	Accent = Color3.fromRGB(205, 120, 255),
	White = Color3.fromRGB(255,255,255),
	Dark = Color3.fromRGB(13,11,20),
	Dark2 = Color3.fromRGB(25,20,34),
	Good = Color3.fromRGB(72,235,125),
	Warn = Color3.fromRGB(255,205,70),
	Bad = Color3.fromRGB(255,70,90),
}

local currentTarget = nil
local lastAcquire = 0
local lastCamera = nil

local esp = {}
local playerConnections = {}

--==================================================
-- CLEAN OLD COPIES
--==================================================

for _, name in ipairs({
	"TrainingCombatHUD",
	"TrainingCombatHUD_V16",
	"TrainingCombatHUD_V15",
	"MobileCombatUI",
}) do
	local old = PlayerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

pcall(function()
	RunService:UnbindFromRenderStep("TrainingCombatHUD_Aim")
end)

--==================================================
-- HELPERS
--==================================================

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function makeLabel(parent, text, size, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = CFG.White
	l.TextSize = size or 12
	l.Font = font or Enum.Font.GothamMedium
	l.Parent = parent
	return l
end

local function makeButton(parent, name, text)
	local b = Instance.new("TextButton")
	b.Name = name
	b.BackgroundColor3 = CFG.Dark2
	b.BackgroundTransparency = .03
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = CFG.White
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Active = true
	b.Selectable = false
	b.ZIndex = 50
	b.Parent = parent
	corner(b, 9)
	stroke(b, CFG.BoxColor, 1.2, .25)

	b.MouseEnter:Connect(function()
		TweenService:Create(
			b,
			TweenInfo.new(.12),
			{BackgroundColor3 = CFG.BoxColor}
		):Play()
	end)

	b.MouseLeave:Connect(function()
		TweenService:Create(
			b,
			TweenInfo.new(.12),
			{BackgroundColor3 = b:GetAttribute("Active") and CFG.BoxColor or CFG.Dark2}
		):Play()
	end)

	return b
end

local function setToggle(button, enabled, onText, offText)
	button:SetAttribute("Active", enabled)
	button.Text = enabled and onText or offText
	button.BackgroundColor3 = enabled and CFG.BoxColor or CFG.Dark2
end

local function disconnect(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingCombatHUD_V16"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

-- FOV circle
local fov = Instance.new("Frame")
fov.Name = "AimFOV"
fov.AnchorPoint = Vector2.new(.5,.5)
fov.Position = UDim2.fromScale(.5,.5)
fov.Size = UDim2.fromOffset(CFG.AimFOV*2, CFG.AimFOV*2)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.ZIndex = 5
fov.Parent = gui
corner(fov,999)
stroke(fov,CFG.Accent,1.5,.28)

local centerDot = Instance.new("Frame")
centerDot.AnchorPoint = Vector2.new(.5,.5)
centerDot.Position = UDim2.fromScale(.5,.5)
centerDot.Size = UDim2.fromOffset(4,4)
centerDot.BackgroundColor3 = CFG.White
centerDot.BorderSizePixel = 0
centerDot.ZIndex = 6
centerDot.Parent = gui
corner(centerDot,999)

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(.5,.5)
panel.Position = UDim2.fromScale(.5,.5)
panel.Size = UDim2.fromOffset(330,405)
panel.BackgroundColor3 = CFG.Dark
panel.BackgroundTransparency = .18
panel.BorderSizePixel = 0
panel.ZIndex = 40
panel.Parent = gui
corner(panel,15)
stroke(panel,CFG.BoxColor,1.5,.18)

local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,CFG.Dark2),
	ColorSequenceKeypoint.new(1,CFG.Dark),
})
gradient.Parent = panel

-- Anime image background. Roblox requires the image to be uploaded as an asset first.
local animeBackground = Instance.new("ImageLabel")
animeBackground.Name = "AnimeBackground"
animeBackground.AnchorPoint = Vector2.new(.5,.5)
animeBackground.Position = UDim2.fromScale(.5,.5)
animeBackground.Size = UDim2.fromScale(1,1)
animeBackground.BackgroundTransparency = 1
animeBackground.BorderSizePixel = 0
animeBackground.Image = CFG.AnimeBackgroundImage
animeBackground.ImageTransparency = CFG.AnimeBackgroundTransparency
animeBackground.ScaleType = Enum.ScaleType.Crop
animeBackground.ZIndex = 41
animeBackground.Active = false
animeBackground.Parent = panel
corner(animeBackground,15)

local animeShade = Instance.new("Frame")
animeShade.Name = "AnimeBackgroundShade"
animeShade.Size = UDim2.fromScale(1,1)
animeShade.BackgroundColor3 = Color3.fromRGB(8,7,14)
animeShade.BackgroundTransparency = .42
animeShade.BorderSizePixel = 0
animeShade.ZIndex = 42
animeShade.Active = false
animeShade.Parent = panel
corner(animeShade,15)

if CFG.AnimeBackgroundImage == "rbxassetid://PUT_IMAGE_ASSET_ID_HERE" then
    animeBackground.ImageTransparency = 1
end

local title = makeLabel(panel,"TRAINING  //  V16",14,Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(14,8)
title.Size = UDim2.new(1,-60,0,24)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = makeLabel(panel,"MATCH-SAFE  •  R6/R15  •  PLAYER ONLY",7,Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(15,28)
subtitle.Size = UDim2.new(1,-30,0,14)
subtitle.TextColor3 = Color3.fromRGB(160,145,175)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local close = makeButton(panel,"Close","×")
close.Position = UDim2.new(1,-42,0,8)
close.Size = UDim2.fromOffset(28,27)
close.TextSize = 18

local aimButton = makeButton(panel,"AimToggle","AIM  •  ON")
aimButton.Position = UDim2.fromOffset(12,54)
aimButton.Size = UDim2.fromOffset(150,34)

local espButton = makeButton(panel,"ESPToggle","ESP  •  ON")
espButton.Position = UDim2.fromOffset(169,54)
espButton.Size = UDim2.fromOffset(150,34)

local teamButton = makeButton(panel,"TeamToggle","TEAM  •  ON")
teamButton.Position = UDim2.fromOffset(12,92)
teamButton.Size = UDim2.fromOffset(150,34)

local zoomButton = makeButton(panel,"ZoomToggle","SCREEN ZOOM  •  OFF")
zoomButton.Position = UDim2.fromOffset(169,92)
zoomButton.Size = UDim2.fromOffset(150,34)

local visualsButton = makeButton(panel,"VisualsToggle","VISUALS  •  ON")
visualsButton.Position = UDim2.fromOffset(12,130)
visualsButton.Size = UDim2.fromOffset(150,34)

local skyButton = makeButton(panel,"SkyToggle","SKY  •  SUNSET")
skyButton.Position = UDim2.fromOffset(169,130)
skyButton.Size = UDim2.fromOffset(150,34)

local killSoundButton = makeButton(panel,"KillSoundToggle","KILL SOUND  •  ON")
killSoundButton.Position = UDim2.fromOffset(12,172)
killSoundButton.Size = UDim2.fromOffset(150,34)

local fovLabel = makeLabel(panel,"AIM FOV",9,Enum.Font.GothamBold)
fovLabel.Position = UDim2.fromOffset(12,218)
fovLabel.Size = UDim2.fromOffset(60,26)
fovLabel.TextColor3 = Color3.fromRGB(170,155,185)
fovLabel.TextXAlignment = Enum.TextXAlignment.Left

local fovMinus = makeButton(panel,"FOVMinus","−")
fovMinus.Position = UDim2.fromOffset(76,216)
fovMinus.Size = UDim2.fromOffset(36,30)

local fovValue = makeLabel(panel,tostring(CFG.AimFOV),10,Enum.Font.GothamBold)
fovValue.Position = UDim2.fromOffset(118,216)
fovValue.Size = UDim2.fromOffset(45,30)
fovValue.TextColor3 = CFG.Accent

local fovPlus = makeButton(panel,"FOVPlus","+")
fovPlus.Position = UDim2.fromOffset(166,216)
fovPlus.Size = UDim2.fromOffset(36,30)

local zoomLabel = makeLabel(panel,"SCREEN FOV  "..CFG.ScreenFOV,8,Enum.Font.GothamMedium)
zoomLabel.Position = UDim2.fromOffset(215,218)
zoomLabel.Size = UDim2.fromOffset(105,28)
zoomLabel.TextColor3 = Color3.fromRGB(160,145,175)
zoomLabel.TextXAlignment = Enum.TextXAlignment.Right

local visualInfo = makeLabel(panel,"ATMOSPHERE  •  BLOOM  •  COLOR  •  SUN RAYS",7,Enum.Font.GothamMedium)
visualInfo.Position = UDim2.fromOffset(12,260)
visualInfo.Size = UDim2.new(1,-28,0,14)
visualInfo.TextColor3 = Color3.fromRGB(145,130,160)
visualInfo.TextXAlignment = Enum.TextXAlignment.Left

local status = makeLabel(panel,"TARGET: NONE",9,Enum.Font.GothamBold)
status.Position = UDim2.fromOffset(12,284)
status.Size = UDim2.new(1,-28,0,18)
status.TextColor3 = Color3.fromRGB(165,150,180)
status.TextXAlignment = Enum.TextXAlignment.Left

local mode = makeLabel(panel,"SEARCH: PLAYERS ONLY",7,Enum.Font.GothamMedium)
mode.Position = UDim2.fromOffset(12,308)
mode.Size = UDim2.new(1,-28,0,14)
mode.TextColor3 = Color3.fromRGB(130,115,145)
mode.TextXAlignment = Enum.TextXAlignment.Left

local openButton = makeButton(gui,"Open","☰")
openButton.AnchorPoint = Vector2.new(1,0)
openButton.Position = UDim2.new(1,-18,.5,-23)
openButton.Size = UDim2.fromOffset(45,45)
openButton.TextSize = 20
openButton.Visible = false
openButton.ZIndex = 60

-- The panel opens centered on screen; the launcher appears after closing.


--==================================================
-- MOBILE ANIMATIONS
--==================================================

local panelOpenSize = panel.Size
local panelClosedSize = UDim2.fromOffset(20,20)
local tweenInfo = TweenInfo.new(.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tweenInfoFast = TweenInfo.new(.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animatePanel(show)
	if show then
		panel.Visible = true
		panel.Size = panelClosedSize
		panel.BackgroundTransparency = .35
		TweenService:Create(panel,tweenInfo,{
			Size = panelOpenSize,
			BackgroundTransparency = .18
		}):Play()
	else
		local tw = TweenService:Create(panel,tweenInfo,{
			Size = panelClosedSize,
			BackgroundTransparency = .35
		})
		tw.Completed:Connect(function()
			panel.Visible = false
		end)
		tw:Play()
	end
end

local function buttonPulse(button)
	local original = button.Size
	local small = UDim2.new(
		original.X.Scale, math.max(original.X.Offset-4,1),
		original.Y.Scale, math.max(original.Y.Offset-3,1)
	)

	TweenService:Create(button,tweenInfoFast,{Size=small}):Play()
	task.delay(.07,function()
		if button.Parent then
			TweenService:Create(button,tweenInfoFast,{Size=original}):Play()
		end
	end)
end

local oldClose = close.Activated
close.Activated:Connect(function()
	animatePanel(false)
	task.delay(.24,function()
		openButton.Visible = true
		openButton.Size = UDim2.fromOffset(20,20)
		TweenService:Create(openButton,tweenInfo,{
			Size=UDim2.fromOffset(45,45)
		}):Play()
	end)
end)

openButton.Activated:Connect(function()
	openButton.Visible = false
	animatePanel(true)
end)

for _,button in ipairs({
	aimButton,espButton,teamButton,zoomButton,
	visualsButton,skyButton,fovMinus,fovPlus
}) do
	button.Activated:Connect(function()
		buttonPulse(button)
	end)
end


--==================================================
-- V13_ANIME_GUI
--==================================================

local V13_Gradient = Instance.new("UIGradient")
V13_Gradient.Rotation = 25
V13_Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,18,52)),
    ColorSequenceKeypoint.new(.5, Color3.fromRGB(18,32,60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(52,20,60))
})
V13_Gradient.Parent = panel

local V13_Glow = Instance.new("UIStroke")
V13_Glow.Thickness = 2
V13_Glow.Transparency = .25
V13_Glow.Color = Color3.fromRGB(190,130,255)
V13_Glow.Parent = panel

local V13_Decor = Instance.new("Frame")
V13_Decor.Name = "AnimeDecor"
V13_Decor.BackgroundTransparency = 1
V13_Decor.Size = UDim2.fromScale(1,1)
V13_Decor.ZIndex = 43
V13_Decor.ClipsDescendants = true
V13_Decor.Active = false
V13_Decor.Parent = panel

local V13_Rng = Random.new()

-- Anime-inspired background: moon, glow, stars and drifting sakura particles.
-- No external asset IDs are required, so it works in a clean Roblox place.
local moon = Instance.new("Frame")
moon.Name = "AnimeMoon"
moon.AnchorPoint = Vector2.new(1,0)
moon.Position = UDim2.new(1,-18,0,12)
moon.Size = UDim2.fromOffset(82,82)
moon.BackgroundColor3 = Color3.fromRGB(235,220,255)
moon.BackgroundTransparency = .08
moon.BorderSizePixel = 0
moon.ZIndex = 1
moon.Parent = V13_Decor
corner(moon,999)
local moonGlow = Instance.new("UIStroke")
moonGlow.Thickness = 7
moonGlow.Transparency = .78
moonGlow.Color = Color3.fromRGB(205,155,255)
moonGlow.Parent = moon

local horizon = Instance.new("Frame")
horizon.Name = "AnimeHorizon"
horizon.AnchorPoint = Vector2.new(.5,1)
horizon.Position = UDim2.new(.5,0,1,0)
horizon.Size = UDim2.new(1,0,.30,0)
horizon.BackgroundColor3 = Color3.fromRGB(10,8,22)
horizon.BackgroundTransparency = .18
horizon.BorderSizePixel = 0
horizon.ZIndex = 1
horizon.Parent = V13_Decor

local function makeStar()
    local star = Instance.new("TextLabel")
    star.BackgroundTransparency = 1
    star.Text = "✦"
    star.TextColor3 = Color3.fromRGB(235,215,255)
    star.TextSize = V13_Rng:NextInteger(8,16)
    star.Font = Enum.Font.GothamBold
    star.Position = UDim2.fromScale(V13_Rng:NextNumber(.03,.97), V13_Rng:NextNumber(.05,.88))
    star.Size = UDim2.fromOffset(20,20)
    star.ZIndex = 44
    star.Parent = V13_Decor
    task.spawn(function()
        while star.Parent do
        TweenService:Create(star,TweenInfo.new(V13_Rng:NextNumber(1.4,2.8),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                TextTransparency = .75,
                Rotation = 15
            }):Play()
            task.wait(1.4)
            if not star.Parent then break end
            TweenService:Create(star,TweenInfo.new(V13_Rng:NextNumber(1.4,2.8),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                TextTransparency = .15,
                Rotation = -15
            }):Play()
            task.wait(1.4)
        end
    end)
end

for _=1,14 do makeStar() end

for _=1,10 do
    local p = Instance.new("Frame")
    local s = V13_Rng:NextInteger(2,4)
    p.Size = UDim2.fromOffset(s,s)
    p.Position = UDim2.fromScale(V13_Rng:NextNumber(.02,.98),V13_Rng:NextNumber(.05,.95))
    p.BackgroundColor3 = Color3.fromRGB(225,205,255)
    p.BackgroundTransparency = .45
    p.BorderSizePixel = 0
    p.ZIndex = 44
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1,0)
    c.Parent = p
    p.Parent = V13_Decor

    task.spawn(function()
        while p.Parent do
            local tw = TweenService:Create(
                p,
                TweenInfo.new(V13_Rng:NextNumber(2.5,4.5),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                {
                    Position=UDim2.fromScale(V13_Rng:NextNumber(.02,.98),V13_Rng:NextNumber(.05,.95)),
                    BackgroundTransparency=.8
                }
            )
            tw:Play()
            tw.Completed:Wait()
            p.BackgroundTransparency=.45
        end
    end)
end

for _=1,7 do
    local petal = Instance.new("TextLabel")
    petal.BackgroundTransparency = 1
    petal.Text = "✿"
    petal.TextColor3 = Color3.fromRGB(255,185,225)
    petal.TextTransparency = .25
    petal.TextSize = V13_Rng:NextInteger(10,18)
    petal.Font = Enum.Font.Gotham
    petal.Size = UDim2.fromOffset(24,24)
    petal.Position = UDim2.fromScale(V13_Rng:NextNumber(.02,.95),V13_Rng:NextNumber(.12,.9))
    petal.ZIndex = 44
    petal.Parent = V13_Decor
    task.spawn(function()
        while petal.Parent do
            local x = V13_Rng:NextNumber(.02,.95)
            local y = V13_Rng:NextNumber(.10,.9)
            local tw = TweenService:Create(petal,TweenInfo.new(V13_Rng:NextNumber(3.5,6),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                Position=UDim2.fromScale(x,y),
                Rotation=V13_Rng:NextInteger(-40,40)
            })
            tw:Play()
            tw.Completed:Wait()
        end
    end)
end

for _,child in ipairs(panel:GetChildren()) do
    if child:IsA("GuiObject") and child ~= V13_Decor and child ~= animeBackground and child ~= animeShade then
        child.ZIndex = math.max(child.ZIndex,50)
    end
end

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = panel.Position
	end
end)

title.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart

	panel.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)

--==================================================
-- TARGET HELPERS
--==================================================

local function getTeamValue(model)
	if not model then return nil end

	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return player.Team
	end

	local teamAttribute = model:GetAttribute("Team")
	if teamAttribute ~= nil then
		return teamAttribute
	end

	local teamValue = model:FindFirstChild("Team")
	if teamValue and teamValue:IsA("StringValue") then
		return teamValue.Value
	end

	if teamValue and teamValue:IsA("ObjectValue") then
		return teamValue.Value
	end

	return nil
end

local function sameTeam(modelOrPlayer)
	if not CFG.TeamCheck then
		return false
	end

	local localTeam = LocalPlayer.Team
	if not localTeam then
		return false
	end

	local targetTeam

	if typeof(modelOrPlayer) == "Instance" and modelOrPlayer:IsA("Player") then
		targetTeam = modelOrPlayer.Team
	else
		targetTeam = getTeamValue(modelOrPlayer)
	end

	if targetTeam == nil then
		return false
	end

	if typeof(targetTeam) == "Instance" then
		return targetTeam == localTeam
	end

	return tostring(targetTeam) == localTeam.Name
end

local function getHumanoid(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

local function getRoot(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart")
end

local function isAlive(model)
	local hum = getHumanoid(model)
	return hum ~= nil and hum.Health > 0
end

local function getAimPoint(model)
	if not model then return nil end

	local head = model:FindFirstChild("Head")
	local upper = model:FindFirstChild("UpperTorso")
	local torso = model:FindFirstChild("Torso")
	local root = model:FindFirstChild("HumanoidRootPart")

	-- Test4 uses the head. Keep head-first behavior.
	if head and head:IsA("BasePart") then
		return head.Position
	end

	if upper and upper:IsA("BasePart") then
		return upper.Position
	end

	if torso and torso:IsA("BasePart") then
		return torso.Position
	end

	if root and root:IsA("BasePart") then
		return root.Position
	end

	return nil
end

local function isValidPlayer(player)
	if not player or player == LocalPlayer then
		return false
	end

	if CFG.TeamCheck and sameTeam(player) then
		return false
	end

	local character = player.Character
	if not character or not character.Parent then
		return false
	end

	return isAlive(character) and getRoot(character) ~= nil
end

--==================================================
-- VISIBILITY / FOV
--==================================================

local function pointOnScreen(camera, point)
	local screen, visible = camera:WorldToViewportPoint(point)

	if not visible or screen.Z <= 0 then
		return nil
	end

	return Vector2.new(screen.X,screen.Y)
end

local function inFOV(camera, point)
	local screen = pointOnScreen(camera,point)
	if not screen then return false end

	local center = Vector2.new(
		camera.ViewportSize.X/2,
		camera.ViewportSize.Y/2
	)

	return (screen-center).Magnitude <= CFG.AimFOV
end

local function visibleFromCamera(camera, point, model)
	if not CFG.VisibleCheck then
		return true
	end

	local origin = camera.CFrame.Position
	local direction = point-origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		model,
	}
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin,direction,params)

	return result == nil
end

--==================================================
-- TEST4-STYLE TARGET SEARCH
--==================================================

local function getClosestTarget(camera)
	if not camera then return nil end

	local center = Vector2.new(
		camera.ViewportSize.X/2,
		camera.ViewportSize.Y/2
	)

	local best = nil
	local bestDistance = CFG.AimFOV

	-- Players
	for _,player in ipairs(Players:GetPlayers()) do
		if isValidPlayer(player) then
			local character = player.Character
			local root = getRoot(character)
			local point = getAimPoint(character)

			if root and point then
				local worldDistance =
					(root.Position-camera.CFrame.Position).Magnitude

				if worldDistance <= CFG.AimDistance then
					local screen, visible =
						camera:WorldToViewportPoint(point)

					if visible and screen.Z > 0 then
						local screenPoint =
							Vector2.new(screen.X,screen.Y)

						local distance =
							(screenPoint-center).Magnitude

						if distance < bestDistance
							and visibleFromCamera(camera,point,character) then

							bestDistance = distance
							best = {
								kind = "Player",
								player = player,
								model = character,
								point = point,
							}
						end
					end
				end
			end
		end
	end

	return best
end

local function targetStillValid(target,camera)
	if not target or not camera then
		return false
	end

	local model = target.model
	if not model or not model.Parent then
		return false
	end

	if not isAlive(model) then
		return false
	end

	if target.kind ~= "Player" then
		return false
	end

	local player = target.player

	if not isValidPlayer(player) then
		return false
	end

	if player.Character ~= model then
		return false
	end

	local point = getAimPoint(model)
	if not point then
		return false
	end

	local root = getRoot(model)
	if not root then
		return false
	end

	if (root.Position-camera.CFrame.Position).Magnitude
		> CFG.AimDistance then
		return false
	end

	-- Critical fix:
	-- When the locked target leaves FOV, release it.
	-- Do NOT immediately choose another target in the same frame.
	local screen = pointOnScreen(camera, point)
	if not screen then
		return false
	end
	local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
	if (screen-center).Magnitude > CFG.AimFOV * 1.20 then
		return false
	end

	if not visibleFromCamera(camera,point,model) then
		return false
	end

	target.point = point

	return true
end

--==================================================
-- AIM
--==================================================

RunService:BindToRenderStep(
	"TrainingCombatHUD_Aim",
	Enum.RenderPriority.Last.Value + 10,
	function(dt)

		local camera = Workspace.CurrentCamera

		if camera ~= lastCamera then
			lastCamera = camera
			currentTarget = nil
			lastAcquire = 0

			if camera then
				status.Text = "CAMERA READY • AIM ON"
			else
				status.Text = "WAITING FOR CAMERA"
			end
		end

		if not CFG.AimEnabled then
			currentTarget = nil
			status.Text = "AIM: OFF"
			return
		end

		if not camera then
			currentTarget = nil
			status.Text = "WAITING FOR CAMERA"
			return
		end

		-- Existing target gets first priority.
		if currentTarget then
			if targetStillValid(currentTarget,camera) then
				local point = currentTarget.point
				local desired =
					CFrame.lookAt(camera.CFrame.Position,point)

				local alpha = math.clamp(
					CFG.AimStrength *
					math.max(dt*60,.5),
					0,
					1
				)

				camera.CFrame =
					camera.CFrame:Lerp(desired,alpha)

				local model = currentTarget.model
				local hum = getHumanoid(model)
				local hp = hum and math.floor(hum.Health) or 0

				status.Text =
					"TARGET: "
					.. model.Name
					.. "  ["
					.. hp
					.. " HP]"

				status.TextColor3 = CFG.Accent
				return
			end

			-- Release only. No same-frame forced switch.
			currentTarget = nil
			status.Text = "TARGET: NONE"
			status.TextColor3 =
				Color3.fromRGB(165,150,180)

			lastAcquire = os.clock()
			return
		end

		-- Small reacquire delay prevents flicker when a target
		-- crosses the edge of the FOV.
		local now = os.clock()

		if now-lastAcquire < CFG.ReacquireTime then
			return
		end

		local candidate = getClosestTarget(camera)

		if candidate then
			currentTarget = candidate
			lastAcquire = now
		end
	end
)

--==================================================
-- ESP
--==================================================

local function destroyESP(key)
	local data = esp[key]
	if not data then return end

	disconnect(data.connection)

	if data.highlight then
		data.highlight:Destroy()
	end

	if data.billboard then
		data.billboard:Destroy()
	end

	esp[key] = nil
end

local function createESPForModel(key,model,displayName,store)
	if not CFG.ESPEnabled then
		return
  end

  if not model or not model.Parent then
		return
	end

	local hum = getHumanoid(model)
	local root = getRoot(model)

	if not hum or not root then
		return
	end

	destroyESP(key)

	local highlight = Instance.new("Highlight")
	highlight.Name = "TrainingESP_Highlight"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = CFG.BoxColor
	highlight.FillTransparency = .87
	highlight.OutlineColor = CFG.Accent
	highlight.OutlineTransparency = .05
	highlight.Parent = gui

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrainingESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(145,110)
	billboard.StudsOffset = Vector3.new(0,2.9,0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CFG.ESPMaxDistance
	billboard.Parent = gui

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(.5,.5)
	box.Position = UDim2.fromScale(.5,.58)
	box.Size = UDim2.fromScale(.58,.74)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Parent = billboard
	stroke(box,CFG.BoxColor,1.6,.04)

	local nameLabel =
		makeLabel(billboard,displayName or model.Name,10,Enum.Font.GothamBold)
	nameLabel.AnchorPoint = Vector2.new(.5,1)
	nameLabel.Position = UDim2.new(.5,0,.18,0)
	nameLabel.Size = UDim2.fromOffset(145,18)
	nameLabel.TextStrokeTransparency = .45

	local hpBack = Instance.new("Frame")
	hpBack.AnchorPoint = Vector2.new(0,.5)
	hpBack.Position = UDim2.new(.13,0,.58,0)
	hpBack.Size = UDim2.fromOffset(5,76)
	hpBack.BackgroundColor3 = Color3.fromRGB(45,40,52)
	hpBack.BorderSizePixel = 0
	hpBack.Parent = billboard
	corner(hpBack,99)

	local hpFill = Instance.new("Frame")
	hpFill.AnchorPoint = Vector2.new(0,1)
	hpFill.Position = UDim2.fromScale(0,1)
	hpFill.Size = UDim2.fromScale(1,1)
	hpFill.BackgroundColor3 = CFG.Good
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBack
	corner(hpFill,99)

	local distanceLabel =
		makeLabel(billboard,"",8,Enum.Font.GothamMedium)
	distanceLabel.AnchorPoint = Vector2.new(.5,0)
	distanceLabel.Position = UDim2.new(.5,0,.92,0)
	distanceLabel.Size = UDim2.fromOffset(145,14)
	distanceLabel.TextColor3 = Color3.fromRGB(190,175,205)

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not CFG.ESPEnabled
			or not model.Parent
			or not hum.Parent
			or not root.Parent
			or hum.Health <= 0 then

			destroyESP(key)
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then return end

		local distance =
			(root.Position-camera.CFrame.Position).Magnitude

		local ratio =
			math.clamp(
				hum.Health/math.max(hum.MaxHealth,1),
				0,
				1
			)

		hpFill.Size = UDim2.fromScale(1,ratio)

		if ratio > .5 then
			hpFill.BackgroundColor3 = CFG.Good
		elseif ratio > .25 then
			hpFill.BackgroundColor3 = CFG.Warn
		else
			hpFill.BackgroundColor3 = CFG.Bad
		end

		distanceLabel.Text = math.floor(distance).." studs"

		local player = Players:GetPlayerFromCharacter(model)
		local hidden = false

		if player and CFG.TeamCheck then
			hidden = sameTeam(player)
		elseif not player and CFG.TeamCheck then
			hidden = sameTeam(model)
		end

		local enabled = CFG.ESPEnabled and distance <= CFG.ESPMaxDistance

		highlight.Enabled = enabled and not hidden
		billboard.Enabled = enabled and not hidden

		-- Subtle distance scaling, based on the good Test4 behavior.
		local height = math.clamp(
			70 / math.max(distance/20,.7),
			45,
			100
		)

		billboard.Size = UDim2.fromOffset(
			height*.7,
			height
		)
	end)

	store[key] = {
		highlight = highlight,
		billboard = billboard,
		connection = connection,
	}
end

--==================================================
-- KILL SOUND
--==================================================

local SoundService = game:GetService("SoundService")
local killSound = SoundService:FindFirstChild("TrainingKillSound")
if not killSound then
	killSound = Instance.new("Sound")
	killSound.Name = "TrainingKillSound"
	killSound.Parent = SoundService
end
killSound.SoundId = CFG.KillSoundId
killSound.Volume = CFG.KillSoundVolume
killSound.Looped = false

local function playKillSound()
	if not CFG.KillSoundEnabled then return end
	pcall(function()
		killSound.TimePosition = 0
		killSound:Play()
	end)
end

local function hookKillDetection(player, character)
	if player == LocalPlayer or not character then return end
	local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	if not hum then return end
	disconnect(playerConnections[tostring(player.UserId).."_death"])
	local key = tostring(player.UserId).."_death"
	playerConnections[key] = hum.Died:Connect(function()
		-- Prefer the conventional creator/killer tag used by many Roblox experiences.
		local tag = hum:FindFirstChild("creator") or hum:FindFirstChild("Creator") or hum:FindFirstChild("killer") or hum:FindFirstChild("Killer")
		local killer = tag and tag.Value
		if killer == LocalPlayer then
			playKillSound()
		end
	end)
end

--==================================================
-- PLAYER ESP SETUP
--==================================================

local function setupPlayer(player)
	if player == LocalPlayer then return end

	disconnect(playerConnections[player])

	if player.Character then
		hookKillDetection(player, player.Character)
		task.defer(function()
			if player.Character and CFG.ESPEnabled then
				createESPForModel(
					player,
					player.Character,
					player.DisplayName,
					esp
				)
			end
		end)
	end

	playerConnections[player] =
		player.CharacterAdded:Connect(function(character)
		hookKillDetection(player, character)
			if currentTarget
				and currentTarget.kind == "Player"
				and currentTarget.player == player then

				currentTarget = nil
			end

			task.wait(.15)

			if character.Parent and CFG.ESPEnabled then
				createESPForModel(
					player,
					character,
					player.DisplayName,
					esp
				)
			end
		end)
end

for _,player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	if currentTarget
		and currentTarget.kind == "Player"
		and currentTarget.player == player then

		currentTarget = nil
	end

	destroyESP(player)
	disconnect(playerConnections[player])
	playerConnections[player] = nil
	disconnect(playerConnections[tostring(player.UserId).."_death"])
	playerConnections[tostring(player.UserId).."_death"] = nil
end)

--==================================================
-- VISUALS
--==================================================

local function getEffect(className,name)
	local object = Lighting:FindFirstChild(name)

	if object and object:IsA(className) then
		return object
	end

	if object then
		object:Destroy()
	end

	local newObject = Instance.new(className)
	newObject.Name = name
	newObject.Parent = Lighting

	return newObject
end

local function disableTrainingEffects()
	for _,name in ipairs({
		"TrainingAtmosphere",
		"TrainingBloom",
		"TrainingColorGrade",
		"TrainingSunRays",
		"TrainingDepthOfField",
	}) do
		local obj = Lighting:FindFirstChild(name)
		if obj and obj:IsA("PostEffect") or obj and obj:IsA("Atmosphere") then
			obj.Enabled = false
		end
	end
end

local function applyVisuals()
	if not CFG.VisualsEnabled then
		disableTrainingEffects()
		return
	end

	local atmosphere =
		getEffect("Atmosphere","TrainingAtmosphere")

	local bloom =
		getEffect("BloomEffect","TrainingBloom")

	local color =
		getEffect("ColorCorrectionEffect","TrainingColorGrade")

	local rays =
		getEffect("SunRaysEffect","TrainingSunRays")

	local dof =
		getEffect("DepthOfFieldEffect","TrainingDepthOfField")

	atmosphere.Enabled = true
	bloom.Enabled = true
	color.Enabled = true
	rays.Enabled = true
	dof.Enabled = true

	atmosphere.Density = .20
	atmosphere.Offset = .10
	atmosphere.Haze = .65
	atmosphere.Glare = .18
	atmosphere.Color = Color3.fromRGB(215,220,255)
	atmosphere.Decay = Color3.fromRGB(150,120,180)

	bloom.Intensity = .15
	bloom.Size = 24
	bloom.Threshold = 1.05

	color.Brightness = .025
	color.Contrast = .10
	color.Saturation = .08
	color.TintColor = Color3.fromRGB(248,242,255)

	rays.Intensity = .045
	rays.Spread = .82

	dof.NearIntensity = 0
	dof.FarIntensity = .018
	dof.FocusDistance = 75
	dof.InFocusRadius = 48

	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = .55
	Lighting.EnvironmentSpecularScale = .72

	if CFG.VisualPreset == "SUNSET" then
		Lighting.ClockTime = 17.1
		Lighting.Brightness = 2.1
		Lighting.ExposureCompensation = .08

	elseif CFG.VisualPreset == "CLEAR" then
		Lighting.ClockTime = 13.2
		Lighting.Brightness = 2.4
		Lighting.ExposureCompensation = .05

		atmosphere.Density = .12
		atmosphere.Haze = .28
		atmosphere.Glare = .10
		atmosphere.Color = Color3.fromRGB(205,225,255)
		atmosphere.Decay = Color3.fromRGB(180,195,225)

	elseif CFG.VisualPreset == "NIGHT" then
		Lighting.ClockTime = 22
		Lighting.Brightness = 1.25
		Lighting.ExposureCompensation = -.05

		atmosphere.Density = .27
		atmosphere.Haze = .85
		atmosphere.Glare = .025
		atmosphere.Color = Color3.fromRGB(100,115,180)
		atmosphere.Decay = Color3.fromRGB(35,40,85)

		color.Contrast = .14
		color.Saturation = -.02
		bloom.Intensity = .11

	elseif CFG.VisualPreset == "CINEMATIC" then
		Lighting.ClockTime = 18
		Lighting.Brightness = 1.65
		Lighting.ExposureCompensation = .02

		atmosphere.Density = .24
		atmosphere.Haze = 1.0
		atmosphere.Glare = .16
		atmosphere.Color = Color3.fromRGB(225,210,255)
		atmosphere.Decay = Color3.fromRGB(105,80,145)

		bloom.Intensity = .22
		color.Contrast = .17
		color.Saturation = .04
		dof.FarIntensity = .055
		dof.FocusDistance = 70
		dof.InFocusRadius = 40
	end
end

applyVisuals()

task.spawn(function()
	while gui.Parent do
		if CFG.VisualsEnabled then
			pcall(applyVisuals)
		end
		task.wait(1.0)
	end
end)

--==================================================
-- CAMERA / SCREEN ZOOM
--==================================================

local savedFOV = nil

local function applyScreenZoom()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	if CFG.ScreenZoomEnabled then
		if savedFOV == nil then
			savedFOV = camera.FieldOfView
		end

		camera.FieldOfView = CFG.ScreenFOV
	else
		if savedFOV ~= nil then
			camera.FieldOfView = savedFOV
			savedFOV = nil
		end
	end
end

--==================================================
-- BUTTONS
--==================================================

local function refreshAim()
	setToggle(
		aimButton,
		CFG.AimEnabled,
		"AIM  •  ON",
		"AIM  •  OFF"
	)

	fov.Visible = CFG.AimEnabled
	centerDot.Visible = CFG.AimEnabled

	if not CFG.AimEnabled then
		currentTarget = nil
	end
end

local function refreshESP()
	setToggle(
		espButton,
		CFG.ESPEnabled,
		"ESP  •  ON",
		"ESP  •  OFF"
	)

	if not CFG.ESPEnabled then
		for key in pairs(esp) do
			destroyESP(key)
		end

	else
		for _,player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer
				and player.Character then

				createESPForModel(
					player,
					player.Character,
					player.DisplayName,
					esp
				)
			end
		end

	end
end

local function refreshTeam()
	setToggle(
		teamButton,
		CFG.TeamCheck,
		"TEAM  •  ON",
		"TEAM  •  OFF"
	)

	currentTarget = nil
end

local function refreshZoom()
	setToggle(
		zoomButton,
		CFG.ScreenZoomEnabled,
		"SCREEN ZOOM  •  ON",
		"SCREEN ZOOM  •  OFF"
	)

	zoomLabel.Text = "SCREEN FOV  "..CFG.ScreenFOV
	applyScreenZoom()
end

local function refreshKillSoundButton()
	setToggle(
		killSoundButton,
		CFG.KillSoundEnabled,
		"KILL SOUND  •  ON",
		"KILL SOUND  •  OFF"
	)
end

local function refreshVisualButtons()
	setToggle(
		visualsButton,
		CFG.VisualsEnabled,
		"VISUALS  •  ON",
		"VISUALS  •  OFF"
	)

	skyButton.Text = "SKY  •  "..CFG.VisualPreset
end

local function updateFOV()
	CFG.AimFOV = math.clamp(CFG.AimFOV,45,180)

	fovValue.Text = tostring(CFG.AimFOV)

	fov.Size =
		UDim2.fromOffset(
			CFG.AimFOV*2,
			CFG.AimFOV*2
		)

	currentTarget = nil
end

aimButton.Activated:Connect(function()
	CFG.AimEnabled = not CFG.AimEnabled
	refreshAim()
end)

espButton.Activated:Connect(function()
	CFG.ESPEnabled = not CFG.ESPEnabled
	refreshESP()
end)

teamButton.Activated:Connect(function()
	CFG.TeamCheck = not CFG.TeamCheck
	refreshTeam()
end)

zoomButton.Activated:Connect(function()
	CFG.ScreenZoomEnabled = not CFG.ScreenZoomEnabled
	refreshZoom()
end)

killSoundButton.Activated:Connect(function()
	CFG.KillSoundEnabled = not CFG.KillSoundEnabled
	refreshKillSoundButton()
end)

visualsButton.Activated:Connect(function()
	CFG.VisualsEnabled = not CFG.VisualsEnabled
	applyVisuals()
	refreshVisualButtons()
end)

local presets = {"SUNSET","CLEAR","NIGHT","CINEMATIC"}

skyButton.Activated:Connect(function()
	local index = table.find(
		presets,
		CFG.VisualPreset
	) or 1

	index += 1

	if index > #presets then
		index = 1
	end

	CFG.VisualPreset = presets[index]

	applyVisuals()
	refreshVisualButtons()
end)

fovMinus.Activated:Connect(function()
	CFG.AimFOV -= 5
	updateFOV()
end)

fovPlus.Activated:Connect(function()
	CFG.AimFOV += 5
	updateFOV()
end)

--==================================================
-- FOV / CAMERA / MATCH REFRESH
--==================================================

RunService.RenderStepped:Connect(function()
	fov.Size =
		UDim2.fromOffset(
			CFG.AimFOV*2,
			CFG.AimFOV*2
		)

	-- CurrentCamera can be replaced by a match camera.
	-- Do not keep a stale camera reference.
	local camera = Workspace.CurrentCamera

	if camera ~= lastCamera then
		lastCamera = camera
		currentTarget = nil
		lastAcquire = 0
		savedFOV = nil
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	currentTarget = nil
	lastAcquire = 0
	savedFOV = nil

	task.wait(.4)

	applyScreenZoom()
	refreshESP()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	lastCamera = nil
	currentTarget = nil
	lastAcquire = 0
	savedFOV = nil

	task.defer(function()
		applyScreenZoom()
	end)
end)

--==================================================
-- CONTINUOUS WORLD REFRESH
--==================================================
-- Refresh player characters that appear after the match starts.

task.spawn(function()
	while gui.Parent do
		if CFG.ESPEnabled then
			for _,player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer
					and player.Character
					and not esp[player] then

					createESPForModel(
						player,
						player.Character,
						player.DisplayName,
						esp
					)
				end
			end

		end

		task.wait(.25)
	end
end)

--==================================================
-- START
--==================================================

refreshAim()
refreshESP()
refreshTeam()
refreshZoom()
refreshVisualButtons()
refreshKillSoundButton()
updateFOV()

print("[TrainingCombatHUD V19] Loaded - MOBILE MATCH + VISUALS + KILL SOUND")
