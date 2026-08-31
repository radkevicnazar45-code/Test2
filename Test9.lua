--// TRAINING COMBAT HUD v4
--// Для СОБСТВЕННОЙ игры в Roblox Studio.
--// LocalScript: StarterPlayer > StarterPlayerScripts
--// R15/R6 | Mobile + PC
--// Aim Assist, stable ESP, HP, distance, Highlight, FOV, polished GUI, sky/atmosphere.
--// v4: более надёжный переход Lobby -> Match и повторное получение CurrentCamera.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local CFG = {
	AimEnabled = true,
	ESPEnabled = true,
	TeamCheck = true,
	VisibleCheck = false,

	AimFOV = 125,
	AimDistance = 650,
	AimSmoothness = 0.18,
	ReacquireTime = 0.06,

	-- 0 = body, 1 = head
	AimHeadBias = 0.72,

	BoxColor = Color3.fromRGB(174, 92, 255),
	Accent = Color3.fromRGB(205, 120, 255),
	White = Color3.fromRGB(255,255,255),
	Dark = Color3.fromRGB(13, 11, 20),
	Dark2 = Color3.fromRGB(25, 20, 34),
	Good = Color3.fromRGB(72, 235, 125),
	Warn = Color3.fromRGB(255, 205, 70),
	Bad = Color3.fromRGB(255, 70, 90),

	BeautifulSky = true,
}

local currentTarget = nil
local lastAcquire = 0
local lastCamera = nil

local esp = {}
local playerConnections = {}
local guiConnections = {}

--==================================================
-- CLEAN OLD COPY
--==================================================

local old = PlayerGui:FindFirstChild("TrainingCombatHUD")
if old then
	old:Destroy()
end

pcall(function()
	RunService:UnbindFromRenderStep("TrainingCombatHUD_Aim")
end)

--==================================================
-- BEAUTIFUL VISUALS
--==================================================

local function setupVisuals()

--==================================================
-- V5 VISUAL PRESET
--==================================================

local visualEnabled = true
local skyPreset = "SUNSET"

local function getOrCreate(className, name)
	local obj = Lighting:FindFirstChild(name)
	if obj and obj.ClassName == className then
		return obj
	end
	if obj then
		obj:Destroy()
	end
	local ok, created = pcall(function()
		return Instance.new(className)
	end)
	if not ok or not created then
		return nil
	end
	created.Name = name
	created.Parent = Lighting
	return created
end

local function applyVisualPreset()
	if not visualEnabled then
		local atmosphere = Lighting:FindFirstChild("TrainingAtmosphere")
		if atmosphere then atmosphere.Enabled = false end
		local bloom = Lighting:FindFirstChild("TrainingBloom")
		if bloom then bloom.Enabled = false end
		local cc = Lighting:FindFirstChild("TrainingColorGrade")
		if cc then cc.Enabled = false end
		local rays = Lighting:FindFirstChild("TrainingSunRays")
		if rays then rays.Enabled = false end
		return
	end

	local atmosphere = getOrCreate("Atmosphere","TrainingAtmosphere")
	if not atmosphere then return end
	atmosphere.Enabled = true
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.12
	atmosphere.Haze = 1.05
	atmosphere.Glare = 0.32
	atmosphere.Color = Color3.fromRGB(214,205,255)
	atmosphere.Decay = Color3.fromRGB(255,148,105)

	local bloom = getOrCreate("BloomEffect","TrainingBloom")
	bloom.Enabled = true
	bloom.Intensity = 0.18
	bloom.Size = 24
	bloom.Threshold = 1.05

	local cc = getOrCreate("ColorCorrectionEffect","TrainingColorGrade")
	cc.Enabled = true
	cc.Brightness = 0.03
	cc.Contrast = 0.12
	cc.Saturation = 0.10
	cc.TintColor = Color3.fromRGB(245,238,255)

	local rays = getOrCreate("SunRaysEffect","TrainingSunRays")
	rays.Enabled = true
	rays.Intensity = 0.075
	rays.Spread = 0.82

	Lighting.ClockTime = 17.15
	Lighting.Brightness = 2.25
	Lighting.ExposureCompensation = 0.10
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.72
	Lighting.Ambient = Color3.fromRGB(58,48,70)
	Lighting.OutdoorAmbient = Color3.fromRGB(135,116,154)
	Lighting.ColorShift_Top = Color3.fromRGB(255,220,205)
	Lighting.ColorShift_Bottom = Color3.fromRGB(80,65,110)

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChild("TrainingClouds")
		if not clouds then
			clouds = Instance.new("Clouds")
			clouds.Name = "TrainingClouds"
			clouds.Parent = terrain
		end
		clouds.Cover = 0.28
		clouds.Density = 0.42
		clouds.Color = Color3.fromRGB(210,198,225)
	end
end

local function applySkyPreset()
	local sky = Lighting:FindFirstChild("TrainingSky")
	if sky and not sky:IsA("Sky") then
		sky:Destroy()
		sky = nil
	end
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "TrainingSky"
		sky.Parent = Lighting
	end

	-- A Skybox is made from SIX image assets.
	-- These are Roblox Creator documentation sample faces.
	-- We use them instead of treating a model/pack asset as one texture.
	sky.SkyboxBk = "rbxassetid://162001887"
	sky.SkyboxDn = "rbxassetid://161998893"
	sky.SkyboxFt = "rbxassetid://162001897"
	sky.SkyboxLf = "rbxassetid://162001904"
	sky.SkyboxRt = "rbxassetid://162001919"
	sky.SkyboxUp = "rbxassetid://162001926"
	sky.SunAngularSize = 11
	sky.MoonAngularSize = 9
	sky.StarCount = 1800
end

pcall(applyVisualPreset)
pcall(applySkyPreset)

	if not CFG.BeautifulSky then return end

	local atmosphere = Lighting:FindFirstChild("TrainingAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "TrainingAtmosphere"
		atmosphere.Parent = Lighting
	end

	atmosphere.Density = 0.28
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(190, 205, 255)
	atmosphere.Decay = Color3.fromRGB(110, 100, 165)
	atmosphere.Glare = 0.16
	atmosphere.Haze = 0.75

	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.2
	Lighting.ExposureCompensation = 0.15
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.7
	Lighting.OutdoorAmbient = Color3.fromRGB(115, 105, 145)

	local cc = Lighting:FindFirstChild("TrainingColorGrade")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "TrainingColorGrade"
		cc.Parent = Lighting
	end

	cc.Brightness = 0.03
	cc.Contrast = 0.12
	cc.Saturation = 0.08
	cc.TintColor = Color3.fromRGB(245, 238, 255)

	local bloom = Lighting:FindFirstChild("TrainingBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "TrainingBloom"
		bloom.Parent = Lighting
	end

	bloom.Intensity = 0.18
	bloom.Size = 24
	bloom.Threshold = 1.15
end

setupVisuals()

--==================================================
-- GUI HELPERS
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingCombatHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

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

local function label(parent, text, size, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = CFG.White
	l.TextSize = size or 12
	l.Font = font or Enum.Font.GothamMedium
	l.Parent = parent
	return l
end

--==================================================
-- FOV
--==================================================

local fov = Instance.new("Frame")
fov.Name = "AimFOV"
fov.AnchorPoint = Vector2.new(0.5,0.5)
fov.Position = UDim2.fromScale(0.5,0.5)
fov.Size = UDim2.fromOffset(CFG.AimFOV*2, CFG.AimFOV*2)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.ZIndex = 3
fov.Parent = gui
corner(fov, 999)

local fovStroke = stroke(fov, CFG.Accent, 1.5, 0.3)

local centerDot = Instance.new("Frame")
centerDot.AnchorPoint = Vector2.new(0.5,0.5)
centerDot.Position = UDim2.fromScale(0.5,0.5)
centerDot.Size = UDim2.fromOffset(4,4)
centerDot.BackgroundColor3 = CFG.White
centerDot.BorderSizePixel = 0
centerDot.ZIndex = 4
centerDot.Parent = gui
corner(centerDot,999)

--==================================================
-- MAIN PANEL
--==================================================

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1,0)
panel.Position = UDim2.new(1,-14,0,14)
panel.Size = UDim2.fromOffset(285,245)
panel.BackgroundColor3 = CFG.Dark
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.ZIndex = 20
panel.Parent = gui
corner(panel,14)
stroke(panel, CFG.BoxColor, 1.4, 0.22)

local openButton = Instance.new("TextButton")
openButton.Name = "OpenMenu"
openButton.AnchorPoint = Vector2.new(1,0)
openButton.Position = UDim2.new(1,-14,0,14)
openButton.Size = UDim2.fromOffset(48,48)
openButton.BackgroundColor3 = CFG.Dark
openButton.BackgroundTransparency = 0.04
openButton.BorderSizePixel = 0
openButton.Text = "☰"
openButton.TextColor3 = CFG.White
openButton.TextSize = 22
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.ZIndex = 25
openButton.Parent = gui
corner(openButton,14)
stroke(openButton, CFG.BoxColor, 1.4, 0.22)

local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CFG.Dark2),
	ColorSequenceKeypoint.new(1, CFG.Dark),
})
gradient.Parent = panel

local title = label(panel, "TRAINING  //  COMBAT", 13, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(14,8)
title.Size = UDim2.new(1,-28,0,20)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseMenu"
closeButton.AnchorPoint = Vector2.new(1,0)
closeButton.Position = UDim2.new(1,-8,0,7)
closeButton.Size = UDim2.fromOffset(30,26)
closeButton.BackgroundTransparency = 1
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(210,195,225)
closeButton.TextSize = 22
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 24
closeButton.Parent = panel

local subtitle = label(panel, "V4  •  MATCH SAFE", 8, Enum.Font.GothamMedium)
subtitle.Position = UDim2.fromOffset(15,27)
subtitle.Size = UDim2.new(1,-30,0,13)
subtitle.TextColor3 = Color3.fromRGB(160,145,175)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local function makeToggle(name, text, y)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.fromOffset(12,y)
	b.Size = UDim2.new(0.5,-16,0,38)
	b.BackgroundColor3 = CFG.BoxColor
	b.BackgroundTransparency = 0.05
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = CFG.White
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.ZIndex = 22
	b.Parent = panel
	corner(b,10)
	return b
end

local aimButton = makeToggle("AimToggle","AIM  •  ON",50)
aimButton.Size = UDim2.fromOffset(123,36)

local espButton = makeToggle("ESPToggle","ESP  •  ON",92)
espButton.Size = UDim2.fromOffset(123,36)

local teamButton = makeToggle("TeamToggle","TEAM  •  ON",134)
teamButton.Size = UDim2.fromOffset(123,36)

local visualsButton = makeToggle("VisualsToggle","VISUALS  •  ON",50)
visualsButton.Position = UDim2.new(0.5,4,0,50)
visualsButton.Size = UDim2.fromOffset(123,36)

local skyButton = makeToggle("SkyToggle","SKY  •  WARM",92)
skyButton.Position = UDim2.new(0.5,4,0,92)
skyButton.Size = UDim2.fromOffset(123,36)

local fovLabel = label(panel,"AIM FOV",9,Enum.Font.GothamBold)
fovLabel.Position = UDim2.fromOffset(14,178)
fovLabel.Size = UDim2.fromOffset(60,14)
fovLabel.TextColor3 = Color3.fromRGB(170,155,185)
fovLabel.TextXAlignment = Enum.TextXAlignment.Left

local fovMinus = makeToggle("FOVMinus","−",176)
fovMinus.Size = UDim2.fromOffset(34,28)

local fovValue = label(panel,tostring(CFG.AimFOV),10,Enum.Font.GothamBold)
fovValue.Position = UDim2.fromOffset(92,176)
fovValue.Size = UDim2.fromOffset(50,28)
fovValue.TextColor3 = CFG.Accent

local fovPlus = makeToggle("FOVPlus","+",176)
fovPlus.Position = UDim2.fromOffset(148,176)
fovPlus.Size = UDim2.fromOffset(34,28)

local visualLabel = label(panel,"SUNSET  •  ATMOSPHERE  •  BLOOM  •  CLOUDS",7,Enum.Font.GothamMedium)
visualLabel.Position = UDim2.fromOffset(14,210)
visualLabel.Size = UDim2.new(1,-28,0,12)
visualLabel.TextColor3 = Color3.fromRGB(145,130,160)
visualLabel.TextXAlignment = Enum.TextXAlignment.Left

local status = label(panel,"TARGET: NONE",9,Enum.Font.GothamBold)
status.Position = UDim2.fromOffset(14,225)
status.Size = UDim2.new(1,-28,0,14)
status.TextColor3 = Color3.fromRGB(165,150,180)
status.TextXAlignment = Enum.TextXAlignment.Left

--==================================================
-- MENU OPEN / CLOSE
--==================================================

local menuOpen = true

local function setMenuOpen(value)
	menuOpen = value
	panel.Visible = value
	openButton.Visible = not value
end

closeButton.Activated:Connect(function()
	setMenuOpen(false)
end)

openButton.Activated:Connect(function()
	setMenuOpen(true)
end)

--==================================================
-- DRAGGABLE MOBILE PANEL
--==================================================

local dragging = false
local dragStart
local startPos

local function dragStartFn(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
	end
end

local function dragEndFn(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end

local function dragMoveFn(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - dragStart
	panel.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

table.insert(guiConnections, panel.InputBegan:Connect(dragStartFn))
table.insert(guiConnections, panel.InputEnded:Connect(dragEndFn))
table.insert(guiConnections, UserInputService.InputChanged:Connect(dragMoveFn))

--==================================================
-- AIM TARGETING
--==================================================

local function validTarget(player)
	if not player or player == LocalPlayer then
		return false
	end

	if CFG.TeamCheck
		and LocalPlayer.Team ~= nil
		and player.Team == LocalPlayer.Team then
		return false
	end

	local char = player.Character
	if not char or not char.Parent then
		return false
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	return hum ~= nil and hum.Health > 0 and root ~= nil
end

local function getAimPoint(char)
	if not char then return nil end

	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
	local root = char:FindFirstChild("HumanoidRootPart")

	if head and torso then
		return torso.Position:Lerp(head.Position, CFG.AimHeadBias)
	end

	return (head and head.Position)
		or (torso and torso.Position)
		or (root and root.Position)
end

local function isVisible(camera, point, character)
	if not CFG.VisibleCheck then
		return true
	end

	local origin = camera.CFrame.Position
	local direction = point - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		character,
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	return result == nil
end

local function findTarget(camera)
	if not camera or not camera.Parent then return nil end

	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X/2, viewport.Y/2)

	local best
	local bestScore = CFG.AimFOV

	for _, player in ipairs(Players:GetPlayers()) do
		if validTarget(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local point = char and getAimPoint(char)

			if root and point then
				local distance3D =
					(root.Position - camera.CFrame.Position).Magnitude

				if distance3D <= CFG.AimDistance then
					local screen, onScreen =
						camera:WorldToViewportPoint(point)

					if onScreen and screen.Z > 0 then
						local screenPoint =
							Vector2.new(screen.X,screen.Y)

						local d =
							(screenPoint-center).Magnitude

						if d < bestScore
							and isVisible(camera,point,char) then

							bestScore = d
							best = player
						end
					end
				end
			end
		end
	end

	return best
end

local function targetStillValid(player, camera)
	if not validTarget(player) then
		return false
	end

	if not camera then
		return false
	end

	local char = player.Character
	local point = getAimPoint(char)

	if not point then
		return false
	end

	local screen, onScreen =
		camera:WorldToViewportPoint(point)

	if not onScreen or screen.Z <= 0 then
		return false
	end

	local center =
		Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)

	if (Vector2.new(screen.X,screen.Y)-center).Magnitude
		> CFG.AimFOV then
		return false
	end

	return isVisible(camera,point,char)
end

--==================================================
-- MATCH-SAFE AIM
--==================================================

RunService:BindToRenderStep(
	"TrainingCombatHUD_Aim",
	Enum.RenderPriority.Last.Value + 100,
	function(dt)

		local camera = workspace.CurrentCamera

		if camera ~= lastCamera then
			-- Lobby -> Match часто создаёт/меняет камеру.
			lastCamera = camera
			currentTarget = nil
			lastAcquire = 0
			status.Text = "CAMERA READY"
		end

		if not CFG.AimEnabled then
			currentTarget = nil
			status.Text = "TARGET: NONE"
			return
		end

		if not camera then
			currentTarget = nil
			status.Text = "WAITING FOR CAMERA"
			return
		end

		local now = os.clock()

		if not currentTarget
			or not targetStillValid(currentTarget,camera)
			or now - lastAcquire >= CFG.ReacquireTime then

			local newTarget = findTarget(camera)

			if newTarget then
				currentTarget = newTarget
			elseif not validTarget(currentTarget) then
				currentTarget = nil
			end

			lastAcquire = now
		end

		if currentTarget and targetStillValid(currentTarget,camera) then
			local point = getAimPoint(currentTarget.Character)

			if point then
				local targetCF =
					CFrame.lookAt(camera.CFrame.Position,point)

				local alpha = math.clamp(
					CFG.AimSmoothness *
					math.max(dt * 60,0.5),
					0,
					1
				)

				camera.CFrame =
					camera.CFrame:Lerp(targetCF,alpha)

				local hum =
					currentTarget.Character:FindFirstChildOfClass("Humanoid")

				local hp =
					hum and math.floor(hum.Health) or 0

				status.Text =
					"TARGET: "
					.. currentTarget.DisplayName
					.. "  ["
					.. hp
					.. " HP]"

				status.TextColor3 = CFG.Accent
			else
				currentTarget = nil
			end
		else
			currentTarget = nil
			status.Text = "TARGET: NONE"
			status.TextColor3 =
				Color3.fromRGB(165,150,180)
		end
	end
)


--==================================================
-- V8 PLACE / MATCH AUTO-REINIT
--==================================================

local lastPlaceId = game.PlaceId
local lastCharacter = LocalPlayer.Character

local function reinitializeForNewMode()
	-- This function is intentionally idempotent: it can run repeatedly
	-- when a game swaps camera, character, team, or mode.
	currentTarget = nil
	lastAcquire = 0
	lastCamera = nil

	if not CFG.AimEnabled then
		CFG.AimEnabled = true
	end

	refreshAim()
	refreshESP()
	refreshTeam()
	refreshVisualButtons()
	updateFOV()

	if workspace.CurrentCamera then
		lastCamera = workspace.CurrentCamera
	end
end

LocalPlayer.CharacterAdded:Connect(function(character)
	lastCharacter = character
	task.wait(0.1)
	reinitializeForNewMode()
end)

LocalPlayer.CharacterRemoving:Connect(function()
	currentTarget = nil
	lastAcquire = 0
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	currentTarget = nil
	lastAcquire = 0
	lastCamera = workspace.CurrentCamera
end)

task.spawn(function()
	while gui.Parent do
		if game.PlaceId ~= lastPlaceId then
			lastPlaceId = game.PlaceId
			reinitializeForNewMode()
		end

		local character = LocalPlayer.Character
		if character ~= lastCharacter then
			lastCharacter = character
			reinitializeForNewMode()
		end

		if CFG.AimEnabled and not currentTarget then
			local camera = workspace.CurrentCamera
			if camera then
				local candidate = findTarget(camera)
				if candidate then
					currentTarget = candidate
					lastAcquire = os.clock()
				end
			end
		end

		task.wait(0.05)
	end
end



task.spawn(function()
	while gui.Parent do
		local cam = workspace.CurrentCamera

		if cam ~= lastCamera then
			lastCamera = cam
			currentTarget = nil
			lastAcquire = 0
		end

		-- Match systems often respawn/replace the camera or subject a few
		-- frames after teleporting the player. Keep reacquiring until stable.
		if cam and CFG.AimEnabled and not currentTarget then
			local candidate = findTarget(cam)
			if candidate then
				currentTarget = candidate
				lastAcquire = os.clock()
			end
		end

		task.wait(0.03)
	end
end)

--==================================================
-- ESP
--==================================================

local function destroyESP(player)
	local data = esp[player]
	if not data then return end

	if data.connection then
		data.connection:Disconnect()
	end

	if data.highlight then
		data.highlight:Destroy()
	end

	if data.billboard then
		data.billboard:Destroy()
	end

	esp[player] = nil
end

local function createESP(player, character)
	if player == LocalPlayer or not CFG.ESPEnabled then
		return
	end

	destroyESP(player)

	if not character or not character.Parent then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TrainingESP_Highlight"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = CFG.BoxColor
	highlight.FillTransparency = 0.86
	highlight.OutlineColor = CFG.Accent
	highlight.OutlineTransparency = 0.05
	highlight.Parent = gui

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrainingESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(145,110)
	billboard.StudsOffset = Vector3.new(0,2.9,0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CFG.AimDistance
	billboard.Parent = gui

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5,0.5)
	box.Position = UDim2.fromScale(0.5,0.58)
	box.Size = UDim2.fromScale(0.58,0.74)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Parent = billboard
	stroke(box,CFG.BoxColor,1.6,0.05)

	local nameLabel =
		label(billboard,player.DisplayName,11,Enum.Font.GothamBold)

	nameLabel.AnchorPoint = Vector2.new(0.5,1)
	nameLabel.Position = UDim2.new(0.5,0,0.18,0)
	nameLabel.Size = UDim2.fromOffset(145,18)
	nameLabel.TextStrokeTransparency = 0.5

	local hpBack = Instance.new("Frame")
	hpBack.AnchorPoint = Vector2.new(0,0.5)
	hpBack.Position = UDim2.new(0.13,0,0.58,0)
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
		label(billboard,"",8,Enum.Font.GothamMedium)

	distanceLabel.AnchorPoint = Vector2.new(0.5,0)
	distanceLabel.Position = UDim2.new(0.5,0,0.92,0)
	distanceLabel.Size = UDim2.fromOffset(145,14)
	distanceLabel.TextColor3 = Color3.fromRGB(190,175,205)

	local connection
	connection = RunService.RenderStepped:Connect(function()

		if not CFG.ESPEnabled
			or not character.Parent
			or not humanoid.Parent
			or not root.Parent
			or humanoid.Health <= 0 then

			destroyESP(player)
			return
		end

		local ratio =
			math.clamp(
				humanoid.Health /
				math.max(humanoid.MaxHealth,1),
				0,
				1
			)

		hpFill.Size = UDim2.fromScale(1,ratio)

		if ratio > 0.5 then
			hpFill.BackgroundColor3 = CFG.Good
		elseif ratio > 0.25 then
			hpFill.BackgroundColor3 = CFG.Warn
		else
			hpFill.BackgroundColor3 = CFG.Bad
		end

		local cam = workspace.CurrentCamera

		if cam then
			local dist =
				(root.Position-cam.CFrame.Position).Magnitude

			distanceLabel.Text =
				math.floor(dist).." studs"
		end

		local sameTeam =
			LocalPlayer.Team ~= nil
			and player.Team == LocalPlayer.Team

		local hidden =
			CFG.TeamCheck and sameTeam

		highlight.Enabled =
			CFG.ESPEnabled and not hidden

		billboard.Enabled =
			CFG.ESPEnabled and not hidden
	end)

	esp[player] = {
		highlight = highlight,
		billboard = billboard,
		connection = connection,
	}
end

--==================================================
-- PLAYER SETUP
--==================================================

local function disconnectPlayer(player)
	local connection = playerConnections[player]

	if connection then
		connection:Disconnect()
	end

	playerConnections[player] = nil
end

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	disconnectPlayer(player)

	if player.Character then
		task.defer(function()
			if player.Character then
				createESP(player,player.Character)
			end
		end)
	end

	playerConnections[player] =
		player.CharacterAdded:Connect(function(char)

			if currentTarget == player then
				currentTarget = nil
			end

			task.wait(0.15)

			if char.Parent then
				createESP(player,char)
			end
		end)
end

for _,player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)

	if currentTarget == player then
		currentTarget = nil
	end

	destroyESP(player)
	disconnectPlayer(player)
end)

--==================================================
-- BUTTONS
--==================================================

local function refreshAim()
	aimButton.Text =
		CFG.AimEnabled
		and "AIM  •  ON"
		or "AIM  •  OFF"

	aimButton.BackgroundColor3 =
		CFG.AimEnabled
		and CFG.BoxColor
		or CFG.Dark2

	fov.Visible = CFG.AimEnabled
	centerDot.Visible = CFG.AimEnabled

	if not CFG.AimEnabled then
		currentTarget = nil
	end
end

local function refreshESP()
	espButton.Text =
		CFG.ESPEnabled
		and "ESP  •  ON"
		or "ESP  •  OFF"

	espButton.BackgroundColor3 =
		CFG.ESPEnabled
		and CFG.BoxColor
		or CFG.Dark2

	if CFG.ESPEnabled then
		for _,player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player,player.Character)
			end
		end
	else
		for player in pairs(esp) do
			destroyESP(player)
		end
	end
end

local function refreshTeam()
	teamButton.Text =
		CFG.TeamCheck
		and "TEAM  •  ON"
		or "TEAM  •  OFF"

	teamButton.BackgroundColor3 =
		CFG.TeamCheck
		and CFG.BoxColor
		or CFG.Dark2

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


--==================================================
-- V5 MENU CONTROLS
--==================================================

local function refreshVisualButtons()
	visualsButton.Text = visualEnabled and "VISUALS  •  ON" or "VISUALS  •  OFF"
	visualsButton.BackgroundColor3 = visualEnabled and CFG.BoxColor or CFG.Dark2
	skyButton.Text = "SKY  •  " .. skyPreset
end

visualsButton.Activated:Connect(function()
	visualEnabled = not visualEnabled
	pcall(applyVisualPreset)
	refreshVisualButtons()
end)

skyButton.Activated:Connect(function()
	-- Keep the preset cycle ready for adding more skyboxes later.
	if skyPreset == "SUNSET" then
		skyPreset = "CLEAR"
		Lighting.ClockTime = 13.2
		Lighting.Brightness = 2.4
		local a = Lighting:FindFirstChild("TrainingAtmosphere")
		if a then
			a.Density = 0.18
			a.Haze = 0.45
			a.Glare = 0.18
			a.Color = Color3.fromRGB(205,225,255)
			a.Decay = Color3.fromRGB(170,195,225)
		end
	elseif skyPreset == "CLEAR" then
		skyPreset = "NIGHT"
		Lighting.ClockTime = 22.0
		Lighting.Brightness = 1.3
		local a = Lighting:FindFirstChild("TrainingAtmosphere")
		if a then
			a.Density = 0.30
			a.Haze = 0.75
			a.Glare = 0.05
			a.Color = Color3.fromRGB(100,110,175)
			a.Decay = Color3.fromRGB(35,40,85)
		end
	else
		skyPreset = "SUNSET"
		pcall(applyVisualPreset)
		pcall(applySkyPreset)
	end
	refreshVisualButtons()
end)

local function updateFOV()
	CFG.AimFOV = math.clamp(CFG.AimFOV,45,180)
	fovValue.Text = tostring(CFG.AimFOV)
	fov.Size = UDim2.fromOffset(CFG.AimFOV*2,CFG.AimFOV*2)
	currentTarget = nil
end

fovMinus.Activated:Connect(function()
	CFG.AimFOV -= 5
	updateFOV()
end)

fovPlus.Activated:Connect(function()
	CFG.AimFOV += 5
	updateFOV()
end)

refreshVisualButtons()
updateFOV()

--==================================================
-- RESPONSIVE FOV / RESPAWN / CAMERA
--==================================================

RunService.RenderStepped:Connect(function()
	fov.Size =
		UDim2.fromOffset(
			CFG.AimFOV*2,
			CFG.AimFOV*2
		)
end)

LocalPlayer.CharacterAdded:Connect(function()
	currentTarget = nil
	lastAcquire = 0
	task.wait(0.5)

	if CFG.ESPEnabled then
		for _,player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player,player.Character)
			end
		end
	end
end)

-- CameraSubject can change when entering a match.
-- We intentionally do not cache CurrentCamera permanently.
--==================================================
-- INITIAL STATE
--==================================================

refreshAim()
refreshESP()
refreshTeam()
refreshVisualButtons()
updateFOV()
setMenuOpen(true)

print("[TrainingCombatHUD] V8 loaded successfully")
  
