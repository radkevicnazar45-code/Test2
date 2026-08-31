--// ROBLOX STUDIO: MOBILE AIM ASSIST + BOX ESP + HP BAR
--// Предназначено для собственной игры / тренировочного режима.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local AIM_ENABLED = true
local ESP_ENABLED = true

local AIM_FOV = 70
local AIM_DISTANCE = 500
local AIM_SMOOTHNESS = 0.16

-- 60% Head / 40% Body
local BODY_BLEND = 0.40

local PURPLE = Color3.fromRGB(174, 92, 255)
local DARK = Color3.fromRGB(24, 20, 32)
local WHITE = Color3.fromRGB(255, 255, 255)
local HP_GREEN = Color3.fromRGB(75, 235, 120)
local HP_YELLOW = Color3.fromRGB(255, 205, 70)
local HP_RED = Color3.fromRGB(255, 75, 90)

local currentTarget = nil
local espObjects = {}

--==================================================
-- CLEAN UP OLD COPY
--==================================================

local oldGui = PlayerGui:FindFirstChild("TrainingAimESP")
if oldGui then
	oldGui:Destroy()
end

pcall(function()
	RunService:UnbindFromRenderStep("TrainingAimESP_Aim")
end)

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingAimESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

-- Compact menu
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(1, 0)
menu.Position = UDim2.new(1, -12, 0, 12)
menu.Size = UDim2.fromOffset(148, 38)
menu.BackgroundColor3 = DARK
menu.BackgroundTransparency = 0.06
menu.BorderSizePixel = 0
menu.ZIndex = 20
menu.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 11)
menuCorner.Parent = menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = PURPLE
menuStroke.Thickness = 1.5
menuStroke.Transparency = 0.15
menuStroke.Parent = menu

local function makeButton(name, text, x)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(x, 5)
	button.Size = UDim2.fromOffset(66, 28)
	button.BackgroundColor3 = PURPLE
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = WHITE
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.ZIndex = 21
	button.Parent = menu

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local aimButton = makeButton("AimButton", "AIM  ON", 5)
local espButton = makeButton("ESPButton", "ESP  ON", 77)

--==================================================
-- FOV CIRCLE
--==================================================

local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.Size = UDim2.fromOffset(AIM_FOV * 2, AIM_FOV * 2)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.ZIndex = 5
fov.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = PURPLE
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.25
fovStroke.Parent = fov

--==================================================
-- AIM POINT: 60% HEAD / 40% BODY
--==================================================

local function getAimPoint(character)
	local head = character:FindFirstChild("Head")
	local body = character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")

	if head and body then
		return head.Position:Lerp(body.Position, BODY_BLEND)
	end

	return (head and head.Position) or (body and body.Position)
end

--==================================================
-- TARGET FILTER
--==================================================

local function validTarget(player)
	if player == LocalPlayer then
		return false
	end

	-- В собственной игре союзники не являются целями.
	if LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return humanoid ~= nil and humanoid.Health > 0 and root ~= nil
end

--==================================================
-- FIND TARGET
--==================================================

local function findTarget()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local center = Vector2.new(
		camera.ViewportSize.X * 0.5,
		camera.ViewportSize.Y * 0.5
	)

	local bestPlayer = nil
	local bestScreenDistance = AIM_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if validTarget(player) then
			local character = player.Character
			local root = character:FindFirstChild("HumanoidRootPart")
			local point = getAimPoint(character)

			if root and point then
				local worldDistance =
					(root.Position - camera.CFrame.Position).Magnitude

				if worldDistance <= AIM_DISTANCE then
					local screen, visible =
						camera:WorldToViewportPoint(point)

					if visible and screen.Z > 0 then
						local screenPoint =
							Vector2.new(screen.X, screen.Y)

						local distance =
							(screenPoint - center).Magnitude

						if distance < bestScreenDistance then
							bestScreenDistance = distance
							bestPlayer = player
						end
					end
				end
			end
		end
	end

	return bestPlayer
end

local function targetInsideFOV(player)
	if not validTarget(player) then
		return false
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end

	local point = getAimPoint(player.Character)
	if not point then
		return false
	end

	local screen, visible =
		camera:WorldToViewportPoint(point)

	if not visible or screen.Z <= 0 then
		return false
	end

	local center = Vector2.new(
		camera.ViewportSize.X * 0.5,
		camera.ViewportSize.Y * 0.5
	)

	local screenPoint =
		Vector2.new(screen.X, screen.Y)

	return (screenPoint - center).Magnitude <= AIM_FOV
end

--==================================================
-- AIM
--==================================================

RunService:BindToRenderStep(
	"TrainingAimESP_Aim",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if not AIM_ENABLED then
			currentTarget = nil
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		-- Берём новую цель только если текущей нет.
		if not currentTarget then
			currentTarget = findTarget()
		end

		-- При выходе из FOV просто отпускаем цель.
		-- Камера назад не дёргается.
		if currentTarget
			and not targetInsideFOV(currentTarget) then
			currentTarget = nil
			return
		end

		if not currentTarget then
			return
		end

		local point = getAimPoint(currentTarget.Character)

		if not point then
			currentTarget = nil
			return
		end

		local targetCFrame =
			CFrame.lookAt(camera.CFrame.Position, point)

		camera.CFrame =
			camera.CFrame:Lerp(
				targetCFrame,
				AIM_SMOOTHNESS
			)
	end
)

--==================================================
-- BOX ESP + HP BAR
--==================================================

local function removeESP(player)
	local data = espObjects[player]

	if data then
		if data.connection then
			data.connection:Disconnect()
		end

		if data.gui then
			data.gui:Destroy()
		end

		espObjects[player] = nil
	end
end

local function createESP(player, character)
	if player == LocalPlayer or not ESP_ENABLED then
		return
	end

	removeESP(player)

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	-- Экранный GUI привязан к HumanoidRootPart.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(70, 95)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = AIM_DISTANCE
	billboard.Parent = gui

	-- BOX
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(0.72, 0.86)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Parent = billboard

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = PURPLE
	boxStroke.Thickness = 1.5
	boxStroke.Transparency = 0.05
	boxStroke.Parent = box

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 2)
	boxCorner.Parent = box

	-- HP BACKGROUND
	local hpBackground = Instance.new("Frame")
	hpBackground.Name = "HPBackground"
	hpBackground.AnchorPoint = Vector2.new(0, 0.5)
	hpBackground.Position = UDim2.new(0, -7, 0.5, 0)
	hpBackground.Size = UDim2.new(0, 4, 0.86, 0)
	hpBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	hpBackground.BorderSizePixel = 0
	hpBackground.Parent = billboard

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(1, 0)
	hpCorner.Parent = hpBackground

	-- HP FILL
	local hpBar = Instance.new("Frame")
	hpBar.Name = "HP"
	hpBar.AnchorPoint = Vector2.new(0, 1)
	hpBar.Position = UDim2.fromScale(0, 1)
	hpBar.Size = UDim2.fromScale(1, 1)
	hpBar.BackgroundColor3 = HP_GREEN
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hpBackground

	local hpBarCorner = Instance.new("UICorner")
	hpBarCorner.CornerRadius = UDim.new(1, 0)
	hpBarCorner.Parent = hpBar

	-- NAME
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 0, -3)
	nameLabel.Size = UDim2.fromOffset(90, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = WHITE
	nameLabel.TextStrokeTransparency = 0.45
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not character.Parent
			or not humanoid.Parent
			or humanoid.Health <= 0 then

			if connection then
				connection:Disconnect()
			end

			removeESP(player)
			return
		end

		local ratio =
			math.clamp(
				humanoid.Health /
				math.max(humanoid.MaxHealth, 1),
				0,
				1
			)

		hpBar.Size = UDim2.fromScale(1, ratio)

		if ratio > 0.5 then
			hpBar.BackgroundColor3 = HP_GREEN
		elseif ratio > 0.25 then
			hpBar.BackgroundColor3 = HP_YELLOW
		else
			hpBar.BackgroundColor3 = HP_RED
		end
	end)

	espObjects[player] = {
		gui = billboard,
		connection = connection
	}
end

local function setupESPPlayer(player)
	if player == LocalPlayer then
		return
	end

	if player.Character then
		task.defer(function()
			createESP(player, player.Character)
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		createESP(player, character)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupESPPlayer(player)
end

Players.PlayerAdded:Connect(setupESPPlayer)

Players.PlayerRemoving:Connect(function(player)
	if currentTarget == player then
		currentTarget = nil
	end
	removeESP(player)
end)

--==================================================
-- BUTTONS
--==================================================

aimButton.Activated:Connect(function()
	AIM_ENABLED = not AIM_ENABLED
	currentTarget = nil

	if AIM_ENABLED then
		aimButton.Text = "AIM  ON"
		aimButton.BackgroundColor3 = PURPLE
		fov.Visible = true
	else
		aimButton.Text = "AIM  OFF"
		aimButton.BackgroundColor3 = DARK
		fov.Visible = false
	end
end)

espButton.Activated:Connect(function()
	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then
		espButton.Text = "ESP  ON"
		espButton.BackgroundColor3 = PURPLE

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player, player.Character)
			end
		end
	else
		espButton.Text = "ESP  OFF"
		espButton.BackgroundColor3 = DARK

		for player in pairs(espObjects) do
			removeESP(player)
		end
	end
end)

--==================================================
-- RESPAWN / TELEPORT-SAFE REFRESH
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
	currentTarget = nil

	task.wait(0.75)

	fov.Visible = AIM_ENABLED

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer
			and player.Character
			and ESP_ENABLED then

			createESP(player, player.Character)
		end
	end
end)

-- Поддерживаем FOV при изменении разрешения/ориентации.
RunService.RenderStepped:Connect(function()
	fov.Size = UDim2.fromOffset(
		AIM_FOV * 2,
		AIM_FOV * 2
	)
end)
