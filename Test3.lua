--// MOBILE AIM + ESP
--// Для собственной Roblox-игры / тестовой карты

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- НАСТРОЙКИ
--==================================================

local ESP_ENABLED = true
local AIM_ENABLED = false

-- Маленький FOV по умолчанию
local AIM_FOV = 85

-- Максимальная дистанция
local AIM_DISTANCE = 500

-- 1 = мгновенно, меньше = мягче
-- Поставил высокое значение, чтобы не было "плавания"
local AIM_STRENGTH = 0.85

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Красивый основной стиль
local BUTTON_COLOR = Color3.fromRGB(35, 35, 48)
local BUTTON_ACTIVE = Color3.fromRGB(90, 65, 180)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local function createButton(name, text, position)
	local button = Instance.new("TextButton")

	button.Name = name
	button.Text = text

	button.Size = UDim2.fromOffset(75, 32)
	button.Position = position

	button.BackgroundColor3 = BUTTON_COLOR
	button.BackgroundTransparency = 0.08

	button.TextColor3 = TEXT_COLOR
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold

	button.AutoButtonColor = true

	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = button

	return button
end

-- Маленькие кнопки сверху
local espButton = createButton(
	"ESPButton",
	"ESP ✓",
	UDim2.new(1, -170, 0, 12)
)

local aimButton = createButton(
	"AimButton",
	"AIM",
	UDim2.new(1, -88, 0, 12)
)

--==================================================
-- FOV
--==================================================

local fovCircle = Instance.new("Frame")

fovCircle.Name = "AimFOV"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)

fovCircle.Size = UDim2.fromOffset(
	AIM_FOV * 2,
	AIM_FOV * 2
)

fovCircle.BackgroundTransparency = 1
fovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 2
fovStroke.Transparency = 0.15
fovStroke.Parent = fovCircle

-- Красивый фиолетовый оттенок
local FOV_COLOR = Color3.fromRGB(170, 100, 255)
fovStroke.Color = FOV_COLOR

-- FOV виден только когда Aim включён
fovCircle.Visible = false

--==================================================
-- ESP
--==================================================

local espObjects = {}

local function removeESP(player)
	if espObjects[player] then
		espObjects[player]:Destroy()
		espObjects[player] = nil
	end
end

local function createESP(player, character)

	if player == LocalPlayer then
		return
	end

	removeESP(player)

	if not ESP_ENABLED then
		return
	end

	local highlight = Instance.new("Highlight")

	highlight.Name = "PlayerESP"

	highlight.FillColor = Color3.fromRGB(150, 80, 255)
	highlight.OutlineColor = Color3.fromRGB(220, 180, 255)

	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0

	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	highlight.Parent = character

	espObjects[player] = highlight
end

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	if player.Character then
		createESP(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)

		task.wait(0.25)

		createESP(player, character)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

--==================================================
-- ESP BUTTON
--==================================================

espButton.Activated:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then

		espButton.Text = "ESP ✓"
		espButton.BackgroundColor3 = BUTTON_ACTIVE

		for _, player in ipairs(Players:GetPlayers()) do

			if player ~= LocalPlayer and player.Character then
				createESP(player, player.Character)
			end

		end

	else

		espButton.Text = "ESP"
		espButton.BackgroundColor3 = BUTTON_COLOR

		for player in pairs(espObjects) do
			removeESP(player)
		end
	end
end)

--==================================================
-- ПОИСК ГОЛОВЫ
--==================================================

local function getClosestHead()

	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize

	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local closestHead = nil
	local closestDistance = AIM_FOV

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local character = player.Character

			if character then

				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				local head =
					character:FindFirstChild("Head")

				local root =
					character:FindFirstChild("HumanoidRootPart")

				if humanoid
					and humanoid.Health > 0
					and head
					and root then

					local worldDistance =
						(root.Position - camera.CFrame.Position).Magnitude

					if worldDistance <= AIM_DISTANCE then

						local screenPosition, visible =
							camera:WorldToViewportPoint(
								head.Position
							)

						if visible and screenPosition.Z > 0 then

							local screenPoint = Vector2.new(
								screenPosition.X,
								screenPosition.Y
							)

							local distanceFromCenter =
								(screenPoint - center).Magnitude

							if distanceFromCenter < closestDistance then

								closestDistance =
									distanceFromCenter

								closestHead = head
							end
						end
					end
				end
			end
		end
	end

	return closestHead
end

--==================================================
-- AIM
--==================================================

RunService:BindToRenderStep(
	"MobileAim",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not AIM_ENABLED then
			return
		end

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local targetHead = getClosestHead()

		if not targetHead then
			return
		end

		-- Точная точка прямо на голову
		local cameraPosition = camera.CFrame.Position

		local targetCFrame = CFrame.lookAt(
			cameraPosition,
			targetHead.Position
		)

		-- Почти без "плавания"
		camera.CFrame = camera.CFrame:Lerp(
			targetCFrame,
			AIM_STRENGTH
		)
	end
)

--==================================================
-- AIM BUTTON
--==================================================

aimButton.Activated:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	if AIM_ENABLED then

		aimButton.Text = "AIM ✓"
		aimButton.BackgroundColor3 = BUTTON_ACTIVE

		fovCircle.Visible = true

	else

		aimButton.Text = "AIM"
		aimButton.BackgroundColor3 = BUTTON_COLOR

		fovCircle.Visible = false
	end
end)

--==================================================
-- ОБНОВЛЕНИЕ FOV
--==================================================

local function updateFOV()

	fovCircle.Size = UDim2.fromOffset(
		AIM_FOV * 2,
		AIM_FOV * 2
	)
end

updateFOV()

--==================================================
-- ЗАЩИТА ОТ СМЕНЫ КАМЕРЫ
--==================================================

LocalPlayer.CharacterAdded:Connect(function()

	task.wait(1)

	-- Roblox может создать новую камеру после
	-- загрузки персонажа/матча.
	Camera = workspace.CurrentCamera
end)
