--// TRAINING COMBAT HUD V10
--// NPC TRAINING EDITION
--// Put this LocalScript in StarterPlayer > StarterPlayerScripts.
--//
--// Features:
--// AIM for NPCs with sticky target + clean FOV release
--// ESP: box, name, HP, distance, Highlight
--// Ignore-team setting for player/NPC team attributes
--// R6/R15 target-part fallback
--// FOV controls
--// Camera zoom / third-person distance
--// Beautiful GUI with close/open + tabs
--// Visual presets: Sunset / Clear / Night / Cinematic
--// Atmosphere + Bloom + ColorCorrection + SunRays + DepthOfField
--// Optional Sky replacement through asset IDs
--//
--// IMPORTANT:
--// This version is for NPC/training targets in your own experience.
--// NPCs should have Humanoid + Head + HumanoidRootPart.
--// For best performance put them under workspace.TrainingTargets.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local Config = {
	Aim = {
		Enabled = true,
		FOV = 90,
		Distance = 600,
		Strength = 0.92,
		Prediction = 0.00,
		TargetPart = "Head",
		Sticky = true,
		ReleaseOutsideFOV = true,
		IgnoreDead = true,
		IgnoreTeam = true,
	},
	ESP = {
		Enabled = true,
		Box = true,
		Name = true,
		Health = true,
		Distance = true,
		Highlight = true,
		MaxDistance = 1000,
	},
	Camera = {
		ZoomOut = true,
		Distance = 3.5,
		FOV = 70,
	},
	Visuals = {
		Enabled = true,
		Preset = "SUNSET",
	},
	NPCFolder = "TrainingTargets",
}

local CurrentTarget = nil
local ESPObjects = {}
local VisualObjects = {}

local ACCENT = Color3.fromRGB(170, 85, 255)
local ACCENT2 = Color3.fromRGB(210, 150, 255)
local BG = Color3.fromRGB(20, 17, 27)
local PANEL = Color3.fromRGB(30, 25, 40)
local PANEL2 = Color3.fromRGB(44, 36, 58)
local WHITE = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(175, 160, 190)
local GREEN = Color3.fromRGB(70, 255, 125)
local RED = Color3.fromRGB(255, 70, 90)

--==================================================
-- HELPERS
--==================================================

local function new(className, parent)
	local x = Instance.new(className)
	x.Parent = parent
	return x
end

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function label(parent, text, size)
	local l = new("TextLabel", parent)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = WHITE
	l.TextSize = size
	l.Font = Enum.Font.GothamMedium
	return l
end

local function button(parent, text)
	local b = new("TextButton", parent)
	b.BackgroundColor3 = PANEL2
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = text
	b.TextColor3 = WHITE
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	corner(b, 9)
	stroke(b, ACCENT, 1.1, 0.45)

	b.MouseEnter:Connect(function()
		tween(b, TweenInfo.new(.12), {BackgroundColor3 = ACCENT})
	end)

	b.MouseLeave:Connect(function()
		if b:GetAttribute("Active") ~= true then
			tween(b, TweenInfo.new(.12), {BackgroundColor3 = PANEL2})
		end
	end)

	return b
end

local function setButton(b, active, onText, offText)
	b:SetAttribute("Active", active)
	b.Text = active and onText or offText
	tween(b, TweenInfo.new(.12), {
		BackgroundColor3 = active and ACCENT or PANEL2
	})
end

--==================================================
-- GUI ROOT
--==================================================

local gui = new("ScreenGui", PlayerGui)
gui.Name = "TrainingCombatHUD_V10"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local openButton = button(gui, "☰")
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -14, 0, 14)
openButton.Size = UDim2.fromOffset(48, 48)
openButton.TextSize = 20
openButton.Visible = false

local menu = new("Frame", gui)
menu.Name = "MainMenu"
menu.AnchorPoint = Vector2.new(1, 0)
menu.Position = UDim2.new(1, -14, 0, 14)
menu.Size = UDim2.fromOffset(360, 405)
menu.BackgroundColor3 = BG
menu.BorderSizePixel = 0
menu.BackgroundTransparency = .025
corner(menu, 18)
stroke(menu, ACCENT, 1.5, .15)

local top = new("Frame", menu)
top.BackgroundTransparency = 1
top.Position = UDim2.fromOffset(14, 8)
top.Size = UDim2.new(1, -28, 0, 45)

local title = label(top, "TRAINING  //  V10", 16)
title.Position = UDim2.fromOffset(2, 0)
title.Size = UDim2.new(1, -45, 0, 22)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold

local subtitle = label(top, "NPC COMBAT LAB  •  R6/R15", 8)
subtitle.Position = UDim2.fromOffset(2, 23)
subtitle.Size = UDim2.new(1, -45, 0, 15)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = MUTED

local closeButton = button(top, "×")
closeButton.Position = UDim2.new(1, -31, 0, 0)
closeButton.Size = UDim2.fromOffset(30, 28)
closeButton.TextSize = 19

local tabBar = new("Frame", menu)
tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.fromOffset(12, 57)
tabBar.Size = UDim2.new(1, -24, 0, 34)

local tabAim = button(tabBar, "AIM")
tabAim.Position = UDim2.fromOffset(0, 0)
tabAim.Size = UDim2.fromOffset(105, 32)

local tabESP = button(tabBar, "ESP")
tabESP.Position = UDim2.fromOffset(112, 0)
tabESP.Size = UDim2.fromOffset(105, 32)

local tabVisuals = button(tabBar, "VISUALS")
tabVisuals.Position = UDim2.fromOffset(224, 0)
tabVisuals.Size = UDim2.fromOffset(112, 32)

local pages = new("Frame", menu)
pages.BackgroundTransparency = 1
pages.Position = UDim2.fromOffset(12, 98)
pages.Size = UDim2.new(1, -24, 1, -108)

local aimPage = new("Frame", pages)
aimPage.BackgroundTransparency = 1
aimPage.Size = UDim2.fromScale(1, 1)

local espPage = new("Frame", pages)
espPage.BackgroundTransparency = 1
espPage.Size = UDim2.fromScale(1, 1)
espPage.Visible = false

local visualsPage = new("Frame", pages)
visualsPage.BackgroundTransparency = 1
visualsPage.Size = UDim2.fromScale(1, 1)
visualsPage.Visible = false

local function switchPage(page)
	aimPage.Visible = page == aimPage
	espPage.Visible = page == espPage
	visualsPage.Visible = page == visualsPage

	setButton(tabAim, page == aimPage, "AIM", "AIM")
	setButton(tabESP, page == espPage, "ESP", "ESP")
	setButton(tabVisuals, page == visualsPage, "VISUALS", "VISUALS")
end

tabAim.Activated:Connect(function() switchPage(aimPage) end)
tabESP.Activated:Connect(function() switchPage(espPage) end)
tabVisuals.Activated:Connect(function() switchPage(visualsPage) end)

--==================================================
-- AIM PAGE
--==================================================

local aimToggle = button(aimPage, "")
aimToggle.Position = UDim2.fromOffset(0, 4)
aimToggle.Size = UDim2.new(1, 0, 0, 38)

local function refreshAimButton()
	setButton(
		aimToggle,
		Config.Aim.Enabled,
		"AIM  •  ON",
		"AIM  •  OFF"
	)
end

refreshAimButton()

local aimInfo = label(aimPage, "Sticky target: ON  •  release when target leaves FOV", 8)
aimInfo.Position = UDim2.fromOffset(2, 47)
aimInfo.Size = UDim2.new(1, -4, 0, 18)
aimInfo.TextXAlignment = Enum.TextXAlignment.Left
aimInfo.TextColor3 = MUTED

local fovMinus = button(aimPage, "−")
fovMinus.Position = UDim2.fromOffset(0, 76)
fovMinus.Size = UDim2.fromOffset(40, 32)

local fovText = label(aimPage, "FOV  "..Config.Aim.FOV, 10)
fovText.Position = UDim2.fromOffset(48, 76)
fovText.Size = UDim2.fromOffset(120, 32)
fovText.TextXAlignment = Enum.TextXAlignment.Left

local fovPlus = button(aimPage, "+")
fovPlus.Position = UDim2.fromOffset(172, 76)
fovPlus.Size = UDim2.fromOffset(40, 32)

local teamToggle = button(aimPage, "")
teamToggle.Position = UDim2.fromOffset(0, 119)
teamToggle.Size = UDim2.new(1, 0, 0, 36)

local function refreshTeamButton()
	setButton(
		teamToggle,
		Config.Aim.IgnoreTeam,
		"IGNORE TEAM  •  ON",
		"IGNORE TEAM  •  OFF"
	)
end

refreshTeamButton()

local zoomToggle = button(aimPage, "")
zoomToggle.Position = UDim2.fromOffset(0, 162)
zoomToggle.Size = UDim2.new(1, 0, 0, 36)

local function refreshZoomButton()
	setButton(
		zoomToggle,
		Config.Camera.ZoomOut,
		"CAMERA ZOOM  •  ON",
		"CAMERA ZOOM  •  OFF"
	)
end

refreshZoomButton()

local status = label(aimPage, "TARGET: NONE", 9)
status.Position = UDim2.fromOffset(2, 208)
status.Size = UDim2.new(1, -4, 0, 22)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = MUTED

local aimHelp = label(aimPage, "NPC folder: Workspace/"..Config.NPCFolder, 8)
aimHelp.Position = UDim2.fromOffset(2, 238)
aimHelp.Size = UDim2.new(1, -4, 0, 20)
aimHelp.TextXAlignment = Enum.TextXAlignment.Left
aimHelp.TextColor3 = MUTED

--==================================================
-- ESP PAGE
--==================================================

local espToggle = button(espPage, "")
espToggle.Position = UDim2.fromOffset(0, 4)
espToggle.Size = UDim2.new(1, 0, 0, 38)

local function refreshEspButton()
	setButton(espToggle, Config.ESP.Enabled, "ESP  •  ON", "ESP  •  OFF")
end

refreshEspButton()

local boxToggle = button(espPage, "BOX  •  ON")
boxToggle.Position = UDim2.fromOffset(0, 50)
boxToggle.Size = UDim2.new(1, 0, 0, 34)

local hpToggle = button(espPage, "HP  •  ON")
hpToggle.Position = UDim2.fromOffset(0, 91)
hpToggle.Size = UDim2.new(1, 0, 0, 34)

local nameToggle = button(espPage, "NAME + DISTANCE  •  ON")
nameToggle.Position = UDim2.fromOffset(0, 132)
nameToggle.Size = UDim2.new(1, 0, 0, 34)

local highlightToggle = button(espPage, "HIGHLIGHT  •  ON")
highlightToggle.Position = UDim2.fromOffset(0, 173)
highlightToggle.Size = UDim2.new(1, 0, 0, 34)

local espHelp = label(espPage, "HP color changes with remaining health.", 8)
espHelp.Position = UDim2.fromOffset(2, 218)
espHelp.Size = UDim2.new(1, -4, 0, 18)
espHelp.TextXAlignment = Enum.TextXAlignment.Left
espHelp.TextColor3 = MUTED

--==================================================
-- VISUALS PAGE
--==================================================

local visualToggle = button(visualsPage, "")
visualToggle.Position = UDim2.fromOffset(0, 4)
visualToggle.Size = UDim2.new(1, 0, 0, 38)

local function refreshVisualButton()
	setButton(
		visualToggle,
		Config.Visuals.Enabled,
		"VISUALS  •  ON",
		"VISUALS  •  OFF"
	)
end

refreshVisualButton()

local presetButton = button(visualsPage, "PRESET  •  SUNSET")
presetButton.Position = UDim2.fromOffset(0, 50)
presetButton.Size = UDim2.new(1, 0, 0, 36)

local cinematicInfo = label(
	visualsPage,
	"Bloom • Atmosphere • ColorCorrection • SunRays • DOF",
	8
)
cinematicInfo.Position = UDim2.fromOffset(2, 95)
cinematicInfo.Size = UDim2.new(1, -4, 0, 20)
cinematicInfo.TextXAlignment = Enum.TextXAlignment.Left
cinematicInfo.TextColor3 = MUTED

local skyInfo = label(
	visualsPage,
	"Skybox asset IDs can be added to the preset table below.",
	8
)
skyInfo.Position = UDim2.fromOffset(2, 120)
skyInfo.Size = UDim2.new(1, -4, 0, 20)
skyInfo.TextXAlignment = Enum.TextXAlignment.Left
skyInfo.TextColor3 = MUTED

--==================================================
-- OPEN / CLOSE
--==================================================

local function setMenuVisible(visible)
	if visible then
		menu.Visible = true
		openButton.Visible = false
	else
		menu.Visible = false
		openButton.Visible = true
	end
end

closeButton.Activated:Connect(function()
	setMenuVisible(false)
end)

openButton.Activated:Connect(function()
	setMenuVisible(true)
end)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local menuStart

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		menuStart = menu.Position
	end
end)

top.InputEnded:Connect(function(input)
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

	menu.Position = UDim2.new(
		menuStart.X.Scale,
		menuStart.X.Offset + delta.X,
		menuStart.Y.Scale,
		menuStart.Y.Offset + delta.Y
	)
end)

--==================================================
-- FOV CIRCLE
--==================================================

local fovCircle = new("Frame", gui)
fovCircle.Name = "AIM_FOV"
fovCircle.AnchorPoint = Vector2.new(.5,.5)
fovCircle.Position = UDim2.fromScale(.5,.5)
fovCircle.Size = UDim2.fromOffset(Config.Aim.FOV*2, Config.Aim.FOV*2)
fovCircle.BackgroundTransparency = 1
fovCircle.ZIndex = 2
corner(fovCircle, 999)
stroke(fovCircle, ACCENT, 2, .1)

local function refreshFOV()
	fovCircle.Size = UDim2.fromOffset(
		Config.Aim.FOV * 2,
		Config.Aim.FOV * 2
	)
	fovText.Text = "FOV  "..Config.Aim.FOV
end

--==================================================
-- TARGET FILTERING
--==================================================

local function getTeamOfModel(model)
	if not model then return nil end

	local player = Players:GetPlayerFromCharacter(model)
	if player then return player.Team end

	local teamValue = model:FindFirstChild("Team")
	if teamValue and teamValue:IsA("StringValue") then
		return teamValue.Value
	end

	local attr = model:GetAttribute("Team")
	if attr ~= nil then
		return attr
  end

  return nil
end

local function sameTeam(model)
	if not Config.Aim.IgnoreTeam then
		return false
	end

	local localTeam = LocalPlayer.Team
	local targetTeam = getTeamOfModel(model)

	if localTeam and targetTeam then
		if typeof(targetTeam) == "Instance" then
			return targetTeam == localTeam
		end
		return targetTeam == localTeam.Name
	end

	return false
end

local function validNPC(model)
	if not model or not model:IsA("Model") then return false end
	if model == LocalPlayer.Character then return false end
	if Players:GetPlayerFromCharacter(model) then return false end

	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return false end
	if Config.Aim.IgnoreDead and hum.Health <= 0 then return false end
	if sameTeam(model) then return false end

	return true
end

local function getNPCs()
	local result = {}
	local folder = Workspace:FindFirstChild(Config.NPCFolder)

	if folder then
		for _, obj in ipairs(folder:GetChildren()) do
			if validNPC(obj) then
				table.insert(result, obj)
			end
		end
		return result
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and validNPC(obj) then
			table.insert(result, obj)
		end
	end

	return result
end

local function getAimPart(model)
	if not model then return nil end

	local preferred = model:FindFirstChild(Config.Aim.TargetPart)
	if preferred and preferred:IsA("BasePart") then
		return preferred
	end

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local upper = model:FindFirstChild("UpperTorso")
	if upper and upper:IsA("BasePart") then
		return upper
	end

	local torso = model:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
	end

	return model:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- AIM MATH
--==================================================

local function screenPosition(camera, part)
	if not camera or not part or not part.Parent then return nil end

	local p, visible = camera:WorldToViewportPoint(part.Position)
	if not visible or p.Z <= 0 then return nil end

	return Vector2.new(p.X, p.Y)
end

local function insideFOV(camera, part)
	local p = screenPosition(camera, part)
	if not p then return false end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	return (p - center).Magnitude <= Config.Aim.FOV
end

local function closestTarget()
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local bestPart = nil
	local bestDistance = Config.Aim.FOV

	for _, npc in ipairs(getNPCs()) do
		local hum = npc:FindFirstChildOfClass("Humanoid")
		local root = npc:FindFirstChild("HumanoidRootPart")
		local part = getAimPart(npc)

		if hum and root and part and hum.Health > 0 then
			local distance = (root.Position - camera.CFrame.Position).Magnitude

			if distance <= Config.Aim.Distance then
				local p = screenPosition(camera, part)

				if p then
					local d = (p - center).Magnitude

					if d < bestDistance then
						bestDistance = d
						bestPart = part
					end
				end
			end
		end
	end

	return bestPart
end

--==================================================
-- AIM LOOP
--==================================================
-- The actual camera method is intentionally kept simple:
-- Camera priority + 1 and CFrame:Lerp.
-- A locked target is released when it leaves FOV instead of
-- immediately switching to another target.

RunService:BindToRenderStep(
	"TrainingCombatV10_AIM",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if not Config.Aim.Enabled then
			CurrentTarget = nil
			status.Text = "TARGET: NONE"
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			CurrentTarget = nil
			return
		end

		if CurrentTarget then
			local model = CurrentTarget:FindFirstAncestorOfClass("Model")
			local hum = model and model:FindFirstChildOfClass("Humanoid")
			local root = model and model:FindFirstChild("HumanoidRootPart")

			if not model
				or not CurrentTarget.Parent
				or not hum
				or hum.Health <= 0
				or not root
				or (root.Position - camera.CFrame.Position).Magnitude > Config.Aim.Distance
				or (Config.Aim.ReleaseOutsideFOV and not insideFOV(camera, CurrentTarget))
				or sameTeam(model) then

				CurrentTarget = nil
				status.Text = "TARGET: NONE"
				return
			end

			local targetPosition = CurrentTarget.Position

			if Config.Aim.Prediction > 0 then
				targetPosition += root.AssemblyLinearVelocity * Config.Aim.Prediction
			end

			local desired = CFrame.lookAt(
				camera.CFrame.Position,
				targetPosition
			)

			camera.CFrame = camera.CFrame:Lerp(
				desired,
				Config.Aim.Strength
			)

			status.Text = "TARGET: "..model.Name
			return
		end

		local newTarget = closestTarget()

		if newTarget then
			CurrentTarget = newTarget
			local model = newTarget:FindFirstAncestorOfClass("Model")
			status.Text = "TARGET: "..(model and model.Name or "NPC")
		else
			status.Text = "TARGET: NONE"
		end
	end
)

--==================================================
-- ESP
--==================================================

local function destroyESP(model)
	local data = ESPObjects[model]
	if not data then return end

	if data.connection then
		data.connection:Disconnect()
	end

	if data.billboard then
		data.billboard:Destroy()
	end

	if data.highlight then
		data.highlight:Destroy()
	end

	ESPObjects[model] = nil
end

local function hpColor(ratio)
	if ratio > .6 then
		return GREEN
	elseif ratio > .3 then
		return Color3.fromRGB(255, 205, 70)
	else
		return RED
	end
end

local function createESP(model)
	if not Config.ESP.Enabled or not validNPC(model) then
		return
	end

	destroyESP(model)

	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end

	local bill = new("BillboardGui", gui)
	bill.Name = "V10_ESP"
	bill.Adornee = root
	bill.AlwaysOnTop = true
	bill.Size = UDim2.fromOffset(110, 105)
	bill.StudsOffset = Vector3.new(0, 2.8, 0)

	local box = new("Frame", bill)
	box.BackgroundTransparency = 1
	box.Position = UDim2.fromScale(.18,.12)
	box.Size = UDim2.fromScale(.64,.78)
	box.Visible = Config.ESP.Box
	stroke(box, ACCENT, 2, 0)

	local name = label(bill, model.Name, 9)
	name.Position = UDim2.new(0,0,0,-17)
	name.Size = UDim2.new(1,0,0,16)
	name.Visible = Config.ESP.Name
	name.Font = Enum.Font.GothamBold
	name.TextStrokeTransparency = .45

	local hpBack = new("Frame", bill)
	hpBack.BackgroundColor3 = PANEL2
	hpBack.BorderSizePixel = 0
	hpBack.Position = UDim2.new(0,.5,0,.12)
	hpBack.Size = UDim2.new(0,5,0,.78)
	hpBack.Visible = Config.ESP.Health
	corner(hpBack, 3)

	local hpFill = new("Frame", hpBack)
	hpFill.AnchorPoint = Vector2.new(0,1)
	hpFill.Position = UDim2.fromScale(0,1)
	hpFill.Size = UDim2.fromScale(1,1)
	hpFill.BorderSizePixel = 0
	hpFill.BackgroundColor3 = GREEN
	corner(hpFill,3)

	local distanceLabel = label(bill, "", 8)
	distanceLabel.Position = UDim2.new(0,0,1,-2)
	distanceLabel.Size = UDim2.new(1,0,0,15)
	distanceLabel.Visible = Config.ESP.Distance
	distanceLabel.TextColor3 = MUTED

	local highlight = new("Highlight", model)
	highlight.Name = "V10_ESP_Highlight"
	highlight.Enabled = Config.ESP.Highlight
	highlight.FillColor = ACCENT
	highlight.FillTransparency = .82
	highlight.OutlineColor = ACCENT2
	highlight.OutlineTransparency = .05
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	local data = {
		billboard = bill,
		box = box,
		name = name,
		hpBack = hpBack,
		hpFill = hpFill,
		distance = distanceLabel,
		highlight = highlight,
		connection = nil,
	}

	ESPObjects[model] = data

	data.connection = RunService.RenderStepped:Connect(function()
		if not model.Parent or not hum.Parent or not root.Parent then
			destroyESP(model)
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then return end

		local distance = (root.Position - camera.CFrame.Position).Magnitude
		local ratio = math.clamp(
			hum.Health / math.max(hum.MaxHealth,1),
			0,
			1
		)

		data.box.Visible = Config.ESP.Enabled and Config.ESP.Box
		data.name.Visible = Config.ESP.Enabled and Config.ESP.Name
		data.hpBack.Visible = Config.ESP.Enabled and Config.ESP.Health
		data.distance.Visible = Config.ESP.Enabled and Config.ESP.Distance
		data.highlight.Enabled = Config.ESP.Enabled and Config.ESP.Highlight

		data.hpFill.Size = UDim2.fromScale(1,ratio)
		data.hpFill.BackgroundColor3 = hpColor(ratio)
		data.distance.Text = string.format("%.0f studs", distance)

		if distance > Config.ESP.MaxDistance then
			data.billboard.Enabled = false
			data.highlight.Enabled = false
		else
			data.billboard.Enabled = true
			data.highlight.Enabled = Config.ESP.Highlight
		end
	end)
end

local function refreshESP()
	for model in pairs(ESPObjects) do
		destroyESP(model)
	end

	if not Config.ESP.Enabled then return end

	for _,npc in ipairs(getNPCs()) do
		createESP(npc)
	end
end

--==================================================
-- VISUALS
--==================================================

local function getEffect(className, name)
	local existing = Lighting:FindFirstChild(name)

	if existing and existing.ClassName == className then
		VisualObjects[name] = existing
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local ok, obj = pcall(function()
		return Instance.new(className)
	end)

	if not ok then return nil end

	obj.Name = name
	obj.Parent = Lighting
	VisualObjects[name] = obj
	return obj
end

local function applyVisuals()
	local atmosphere = getEffect("Atmosphere", "V10_Atmosphere")
	local bloom = getEffect("BloomEffect", "V10_Bloom")
	local color = getEffect("ColorCorrectionEffect", "V10_Color")
	local rays = getEffect("SunRaysEffect", "V10_SunRays")
	local dof = getEffect("DepthOfFieldEffect", "V10_Depth")

	for _,obj in pairs(VisualObjects) do
		if obj then
			obj.Enabled = Config.Visuals.Enabled
		end
	end

	if not Config.Visuals.Enabled then
		return
	end

	Lighting.GlobalShadows = true
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = .05
	Lighting.EnvironmentDiffuseScale = .55
	Lighting.EnvironmentSpecularScale = .7
	Lighting.Ambient = Color3.fromRGB(52,45,65)
	Lighting.OutdoorAmbient = Color3.fromRGB(125,112,145)

	if atmosphere then
		atmosphere.Density = .22
		atmosphere.Offset = .12
		atmosphere.Haze = 1
		atmosphere.Glare = .25
		atmosphere.Color = Color3.fromRGB(220,210,255)
		atmosphere.Decay = Color3.fromRGB(255,150,110)
	end

	if bloom then
		bloom.Intensity = .18
		bloom.Size = 24
		bloom.Threshold = 1.05
	end

	if color then
		color.Brightness = .02
		color.Contrast = .11
		color.Saturation = .08
		color.TintColor = Color3.fromRGB(248,240,255)
	end

	if rays then
		rays.Intensity = .06
		rays.Spread = .82
	end

	if dof then
		dof.NearIntensity = 0
		dof.FarIntensity = .025
		dof.FocusDistance = 70
		dof.InFocusRadius = 45
	end

	if Config.Visuals.Preset == "SUNSET" then
		Lighting.ClockTime = 17.1

	elseif Config.Visuals.Preset == "CLEAR" then
		Lighting.ClockTime = 13
		atmosphere.Density = .13
		atmosphere.Haze = .35
		atmosphere.Glare = .14
		atmosphere.Color = Color3.fromRGB(205,225,255)
		atmosphere.Decay = Color3.fromRGB(170,195,225)

	elseif Config.Visuals.Preset == "NIGHT" then
		Lighting.ClockTime = 22
		Lighting.Brightness = 1.25
		atmosphere.Density = .28
		atmosphere.Haze = .8
		atmosphere.Glare = .03
		atmosphere.Color = Color3.fromRGB(105,115,180)
		atmosphere.Decay = Color3.fromRGB(35,40,85)

	elseif Config.Visuals.Preset == "CINEMATIC" then
		Lighting.ClockTime = 18
		Lighting.Brightness = 1.6
		atmosphere.Density = .26
		atmosphere.Haze = 1.2
		atmosphere.Glare = .18
		atmosphere.Color = Color3.fromRGB(230,205,255)
		atmosphere.Decay = Color3.fromRGB(100,75,150)

		bloom.Intensity = .25
		color.Contrast = .17
		color.Saturation = .04
		dof.FarIntensity = .07
		dof.FocusDistance = 65
		dof.InFocusRadius = 35
	end
end

--==================================================
-- CAMERA
--==================================================

local function applyCamera()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	camera.FieldOfView = Config.Camera.FOV

	if Config.Camera.ZoomOut then
		LocalPlayer.CameraMaxZoomDistance = math.max(
			LocalPlayer.CameraMaxZoomDistance,
			Config.Camera.Distance
		)
		LocalPlayer.CameraMinZoomDistance = math.min(
			LocalPlayer.CameraMinZoomDistance,
			Config.Camera.Distance
		)
	end
end

--==================================================
-- BUTTON CONNECTIONS
--==================================================

aimToggle.Activated:Connect(function()
	Config.Aim.Enabled = not Config.Aim.Enabled
	CurrentTarget = nil
	refreshAimButton()
	fovCircle.Visible = Config.Aim.Enabled
	status.Text = "TARGET: NONE"
end)

teamToggle.Activated:Connect(function()
	Config.Aim.IgnoreTeam = not Config.Aim.IgnoreTeam
	CurrentTarget = nil
	refreshTeamButton()
end)

zoomToggle.Activated:Connect(function()
	Config.Camera.ZoomOut = not Config.Camera.ZoomOut
	refreshZoomButton()
	applyCamera()
end)

fovMinus.Activated:Connect(function()
	Config.Aim.FOV = math.clamp(Config.Aim.FOV - 5, 45, 180)
	refreshFOV()
	CurrentTarget = nil
end)

fovPlus.Activated:Connect(function()
	Config.Aim.FOV = math.clamp(Config.Aim.FOV + 5, 45, 180)
	refreshFOV()
	CurrentTarget = nil
end)

espToggle.Activated:Connect(function()
	Config.ESP.Enabled = not Config.ESP.Enabled
	refreshEspButton()
	refreshESP()
end)

boxToggle.Activated:Connect(function()
	Config.ESP.Box = not Config.ESP.Box
	setButton(boxToggle, Config.ESP.Box, "BOX  •  ON", "BOX  •  OFF")
end)

hpToggle.Activated:Connect(function()
	Config.ESP.Health = not Config.ESP.Health
	setButton(hpToggle, Config.ESP.Health, "HP  •  ON", "HP  •  OFF")
end)

nameToggle.Activated:Connect(function()
	local newState = not (Config.ESP.Name and Config.ESP.Distance)
	Config.ESP.Name = newState
	Config.ESP.Distance = newState
	setButton(nameToggle, newState, "NAME + DISTANCE  •  ON", "NAME + DISTANCE  •  OFF")
end)

highlightToggle.Activated:Connect(function()
	Config.ESP.Highlight = not Config.ESP.Highlight
	setButton(highlightToggle, Config.ESP.Highlight, "HIGHLIGHT  •  ON", "HIGHLIGHT  •  OFF")
end)

visualToggle.Activated:Connect(function()
	Config.Visuals.Enabled = not Config.Visuals.Enabled
	refreshVisualButton()
	applyVisuals()
end)

local presets = {"SUNSET","CLEAR","NIGHT","CINEMATIC"}

presetButton.Activated:Connect(function()
	local index = table.find(presets, Config.Visuals.Preset) or 1
	index += 1
	if index > #presets then index = 1 end

	Config.Visuals.Preset = presets[index]
	presetButton.Text = "PRESET  •  "..Config.Visuals.Preset
	applyVisuals()
end)

--==================================================
-- CAMERA RESET / MATCH RELOAD
--==================================================

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	CurrentTarget = nil
	task.defer(applyCamera)
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(.35)
	CurrentTarget = nil
	applyCamera()
	refreshESP()
end)

--==================================================
-- PERIODIC NPC REFRESH
--==================================================

task.spawn(function()
	while gui.Parent do
		if Config.ESP.Enabled then
			for _,npc in ipairs(getNPCs()) do
				if not ESPObjects[npc] then
					createESP(npc)
				end
			end
		end

		if CurrentTarget and not CurrentTarget.Parent then
			CurrentTarget = nil
			status.Text = "TARGET: NONE"
		end

		task.wait(.3)
	end
end)

--==================================================
-- START
--==================================================

switchPage(aimPage)
refreshFOV()
applyCamera()
applyVisuals()
refreshESP()
setMenuVisible(true)

print("[TrainingCombatHUD V10] Loaded successfully - NPC training mode")
