--// TRAINING COMBAT HUD v3
--// Для СОБСТВЕННОЙ игры в Roblox Studio.
--// Вставлять как LocalScript: StarterPlayer > StarterPlayerScripts
--// R15/R6 | Mobile + PC
--// Features: Aim Assist, stable ESP, HP, distance, Highlight, FOV, polished GUI, sky/atmosphere visuals.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
	VisibleCheck = true,

	AimFOV = 105,
	AimDistance = 650,
	AimSmoothness = 0.18,

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

	-- Visual atmosphere. Set false if your game already controls Lighting.
	BeautifulSky = true,
}

local currentTarget = nil
local esp = {}
local playerConnections = {}
local guiConnections = {}

--==================================================
-- CLEAN OLD COPY
--==================================================

local old = PlayerGui:FindFirstChild("TrainingCombatHUD")
if old then old:Destroy() end

pcall(function()
	RunService:UnbindFromRenderStep("TrainingCombatHUD_Aim")
end)

--==================================================
-- BEAUTIFUL VISUALS
--==================================================

local function setupVisuals()
	if not CFG.BeautifulSky then return end

	-- Do not delete the game's existing Sky; just add a soft atmosphere/post-processing.
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
panel.Size = UDim2.fromOffset(225,142)
panel.BackgroundColor3 = CFG.Dark
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.ZIndex = 20
panel.Parent = gui
corner(panel,14)
stroke(panel, CFG.BoxColor, 1.4, 0.22)

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

local subtitle = label(panel, "MOBILE HUD", 8, Enum.Font.GothamMedium)
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

local aimButton = makeToggle("AimToggle","AIM  •  ON",48)
local espButton = makeToggle("ESPToggle","ESP  •  ON",92)
aimButton.Size = UDim2.new(0.5,-16,0,38)
espButton.Size = UDim2.new(0.5,-16,0,38)
espButton.Position = UDim2.new(0.5,4,0,48)

local teamButton = makeToggle("TeamToggle","TEAM  •  ON",92)
teamButton.Position = UDim2.new(0.5,4,0,92)

local status = label(panel,"TARGET: NONE",9,Enum.Font.GothamBold)
status.Position = UDim2.fromOffset(14,126)
status.Size = UDim2.new(1,-28,0,12)
status.TextColor3 = Color3.fromRGB(165,150,180)
status.TextXAlignment = Enum.TextXAlignment.Left

-- Make panel slightly taller because status overlaps on very small screens.
panel.Size = UDim2.fromOffset(225,150)
status.Position = UDim2.fromOffset(14,135)

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
		and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

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
	if player == LocalPlayer then return false end

	if CFG.TeamCheck
		and LocalPlayer.Team ~= nil
		and player.Team == LocalPlayer.Team then
		return false
	end

	local char = player.Character
	if not char then return false end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then return false end

	return true
end

local function getAimPoint(char)
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local root = char:FindFirstChild("HumanoidRootPart")

	if head and torso then
		return torso.Position:Lerp(head.Position, CFG.AimHeadBias)
	end
	return (head and head.Position) or (torso and torso.Position) or (root and root.Position)
end

local function isVisible(camera, point, character)
	if not CFG.VisibleCheck then return true end

	local origin = camera.CFrame.Position
	local direction = point - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character, character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	return result == nil
end

local function findTarget()
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X/2, viewport.Y/2)
	local best, bestScore = nil, CFG.AimFOV

	for _, player in ipairs(Players:GetPlayers()) do
		if validTarget(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local point = char and getAimPoint(char)

			if root and point then
				local distance3D = (root.Position-camera.CFrame.Position).Magnitude
				if distance3D <= CFG.AimDistance and isVisible(camera,point,char) then
					local screen, onScreen = camera:WorldToViewportPoint(point)
					if onScreen and screen.Z > 0 then
						local d = (Vector2.new(screen.X,screen.Y)-center).Magnitude
						if d < bestScore then
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

local function targetStillValid(player)
	if not validTarget(player) then return false end
	local camera = workspace.CurrentCamera
	if not camera then return false end

	local char = player.Character
	local point = getAimPoint(char)
	if not point then return false end

	local screen, onScreen = camera:WorldToViewportPoint(point)
	if not onScreen or screen.Z <= 0 then return false end

	local center = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
	if (Vector2.new(screen.X,screen.Y)-center).Magnitude > CFG.AimFOV then
		return false
	end

	return isVisible(camera,point,char)
end

RunService:BindToRenderStep(
	"TrainingCombatHUD_Aim",
	Enum.RenderPriority.Camera.Value+1,
	function()
		if not CFG.AimEnabled then
			currentTarget = nil
			status.Text = "TARGET: NONE"
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		if not currentTarget or not targetStillValid(currentTarget) then
			currentTarget = findTarget()
		end

		if currentTarget and targetStillValid(currentTarget) then
			local point = getAimPoint(currentTarget.Character)
			local targetCF = CFrame.lookAt(camera.CFrame.Position,point)
			camera.CFrame = camera.CFrame:Lerp(targetCF,CFG.AimSmoothness)

			local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
			local hp = hum and math.floor(hum.Health) or 0
			status.Text = "TARGET: "..currentTarget.DisplayName.."  ["..hp.." HP]"
			status.TextColor3 = CFG.Accent
		else
			currentTarget = nil
			status.Text = "TARGET: NONE"
			status.TextColor3 = Color3.fromRGB(165,150,180)
		end
	end
)

--==================================================
-- ESP
--==================================================

local function destroyESP(player)
	local data = esp[player]
	if not data then return end

	if data.connection then data.connection:Disconnect() end
	if data.highlight then data.highlight:Destroy() end
	if data.billboard then data.billboard:Destroy() end
	esp[player] = nil
end

local function createESP(player, character)
	if player == LocalPlayer or not CFG.ESPEnabled then return end

	destroyESP(player)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	-- Highlight is much more reliable than a tiny Billboard box and works with R15.
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

	-- Corner-frame box
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5,0.5)
	box.Position = UDim2.fromScale(0.5,0.58)
	box.Size = UDim2.fromScale(0.58,0.74)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Parent = billboard

	local boxStroke = stroke(box,CFG.BoxColor,1.6,0.05)

	-- Name
	local nameLabel = label(billboard,player.DisplayName,11,Enum.Font.GothamBold)
	nameLabel.AnchorPoint = Vector2.new(0.5,1)
	nameLabel.Position = UDim2.new(0.5,0,0.18,0)
	nameLabel.Size = UDim2.fromOffset(145,18)
	nameLabel.TextStrokeTransparency = 0.5

	-- HP background
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

	-- Distance
	local distanceLabel = label(billboard,"",8,Enum.Font.GothamMedium)
	distanceLabel.AnchorPoint = Vector2.new(0.5,0)
	distanceLabel.Position = UDim2.new(0.5,0,0.92,0)
	distanceLabel.Size = UDim2.fromOffset(145,14)
	distanceLabel.TextColor3 = Color3.fromRGB(190,175,205)

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not character.Parent or humanoid.Health <= 0 then
			destroyESP(player)
			return
		end

		local ratio = math.clamp(humanoid.Health/math.max(humanoid.MaxHealth,1),0,1)
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
			local dist = (root.Position-cam.CFrame.Position).Magnitude
			distanceLabel.Text = math.floor(dist).." studs"
		end

		-- Fade ESP for same-team players if TeamCheck is enabled.
		local sameTeam = LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
		local hidden = CFG.TeamCheck and sameTeam
		highlight.Enabled = CFG.ESPEnabled and not hidden
		billboard.Enabled = CFG.ESPEnabled and not hidden
	end)

	esp[player] = {
		highlight = highlight,
		billboard = billboard,
		connection = connection,
	}
end

local function setupPlayer(player)
	if player == LocalPlayer then return end

	if player.Character then
		task.defer(createESP,player,player.Character)
	end

	playerConnections[player] = player.CharacterAdded:Connect(function(char)
		task.wait(0.15)
		createESP(player,char)
	end)
end

for _,player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	if currentTarget == player then currentTarget = nil end
	destroyESP(player)

	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end)

--==================================================
-- BUTTONS
--==================================================

local function refreshAim()
	aimButton.Text = CFG.AimEnabled and "AIM  •  ON" or "AIM  •  OFF"
	aimButton.BackgroundColor3 = CFG.AimEnabled and CFG.BoxColor or CFG.Dark2
	fov.Visible = CFG.AimEnabled
end

local function refreshESP()
	espButton.Text = CFG.ESPEnabled and "ESP  •  ON" or "ESP  •  OFF"
	espButton.BackgroundColor3 = CFG.ESPEnabled and CFG.BoxColor or CFG.Dark2

	for player,data in pairs(esp) do
		if data.highlight then data.highlight.Enabled = CFG.ESPEnabled end
		if data.billboard then data.billboard.Enabled = CFG.ESPEnabled end
	end

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
	teamButton.Text = CFG.TeamCheck and "TEAM  •  ON" or "TEAM  •  OFF"
	teamButton.BackgroundColor3 = CFG.TeamCheck and CFG.BoxColor or CFG.Dark2
	currentTarget = nil
end

aimButton.Activated:Connect(function()
	CFG.AimEnabled = not CFG.AimEnabled
	currentTarget = nil
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
-- RESPONSIVE FOV / RESPAWN
--==================================================

RunService.RenderStepped:Connect(function()
	fov.Size = UDim2.fromOffset(CFG.AimFOV*2,CFG.AimFOV*2)
end)

LocalPlayer.CharacterAdded:Connect(function()
	currentTarget = nil
	task.wait(0.5)
	if CFG.ESPEnabled then
		for _,player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player,player.Character)
			end
		end
	end
end)

-- Initial state
refreshAim()
refreshESP()
refreshTeam()

print("[TrainingCombatHUD] v3 loaded successfully")
