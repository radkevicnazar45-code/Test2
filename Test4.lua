--// MOBILE AIM + BOX ESP + HP BAR
--// Для собственной Roblox-игры

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- НАСТРОЙКИ
--==================================================

local AIM_ENABLED = true
local ESP_ENABLED = true

local AIM_FOV = 85
local AIM_DISTANCE = 500

-- Чем ближе к 1, тем жёстче удержание головы
local AIM_STRENGTH = 0.98

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MobileCombatUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local PURPLE = Color3.fromRGB(170, 85, 255)
local DARK = Color3.fromRGB(30, 25, 40)
local WHITE = Color3.fromRGB(255, 255, 255)

local function makeButton(name, text, x)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromOffset(70, 30)
	b.Position = UDim2.new(1, x, 0, 10)

	b.BackgroundColor3 = PURPLE
	b.BackgroundTransparency = 0.08

	b.Text = text
	b.TextColor3 = WHITE
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold

	b.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = b

	return b
end

local espButton = makeButton("ESPButton", "ESP ✓", -155)
local aimButton = makeButton("AIM ✓", "AIM ✓", -80)

--==================================================
-- FOV
--==================================================

local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.Size = UDim2.fromOffset(AIM_FOV * 2, AIM_FOV * 2)
fov.BackgroundTransparency = 1
fov.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = PURPLE
fovStroke.Thickness = 2
fovStroke.Transparency = 0.15
fovStroke.Parent = fov

--==================================================
-- ESP
--==================================================

local espData = {}

local function removeESP(player)
	local data = espData[player]

	if data then
		if data.gui then
			data.gui:Destroy()
		end

		espData[player] = nil
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

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	-- Основной контейнер
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(70, 100)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = gui

	-- Box
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(0.75, 0.85)
	box.BackgroundTransparency = 1
	box.Parent = billboard

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = PURPLE
	boxStroke.Thickness = 2
	boxStroke.Parent = box

	-- HP background
	local hpBack = Instance.new("Frame")
	hpBack.Name = "HPBackground"
	hpBack.AnchorPoint = Vector2.new(0, 0.5)
	hpBack.Position = UDim2.new(0, -7, 0.5, 0)
	hpBack.Size = UDim2.new(0, 4, 0.85, 0)
	hpBack.BackgroundColor3 = DARK
	hpBack.BorderSizePixel = 0
	hpBack.Parent = billboard

	-- HP
	local hp = Instance.new("Frame")
	hp.Name = "HP"
	hp.AnchorPoint = Vector2.new(0, 1)
	hp.Position = UDim2.fromScale(0, 1)
	hp.Size = UDim2.fromScale(1, 1)
	hp.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
	hp.BorderSizePixel = 0
	hp.Parent = hpBack

	local data = {
		gui = billboard,
		humanoid = humanoid,
		hp = hp
	}

	espData[player] = data

	local connection

	connection = RunService.RenderStepped:Connect(function()
		if not billboard.Parent
			or not character.Parent
			or not humanoid.Parent then

			connection:Disconnect()
			return
		end

		local maxHealth = math.max(humanoid.MaxHealth, 1)
		local health = math.clamp(humanoid.Health / maxHealth, 0, 1)

		hp.Size = UDim2.fromScale(1, health)

		-- Красивое изменение размера бокса
		local height = math.clamp(
			70 / math.max(
				(root.Position - workspace.CurrentCamera.CFrame.Position).Magnitude / 20,
				0.7
			),
			45,
			100
		)

		billboard.Size = UDim2.fromOffset(
			height * 0.7,
			height
		)
	end)
end

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	if player.Character then
		task.wait(0.1)
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

Players.PlayerRemoving:Connect(removeESP)

--==================================================
-- ПОИСК ЦЕЛИ
--==================================================

local function getClosestHead()
	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local bestHead = nil
	local bestDistance = AIM_FOV

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

						local screen, visible =
							camera:WorldToViewportPoint(
								head.Position
							)

						if visible and screen.Z > 0 then

							local point = Vector2.new(
								screen.X,
								screen.Y
							)

							local distance =
								(point - center).Magnitude

							if distance < bestDistance then
								bestDistance = distance
								bestHead = head
							end
						end
					end
				end
			end
		end
	end

	return bestHead
end

--==================================================
-- AIM
--==================================================

RunService:BindToRenderStep(
	"StrongHeadAim",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not AIM_ENABLED then
			return
		end

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local head = getClosestHead()

		if not head or not head.Parent then
			return
		end

		-- Точно смотрим в центр головы
		local cameraPosition = camera.CFrame.Position

		local target = CFrame.lookAt(
			cameraPosition,
			head.Position
		)

		camera.CFrame = camera.CFrame:Lerp(
			target,
			AIM_STRENGTH
		)
	end
)

--==================================================
-- КНОПКА ESP
--==================================================

espButton.Activated:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then

		espButton.Text = "ESP ✓"
		espButton.BackgroundColor3 = PURPLE

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player, player.Character)
			end
		end

	else

		espButton.Text = "ESP"
		espButton.BackgroundColor3 = DARK

		for player in pairs(espData) do
			removeESP(player)
		end
	end
end)

--==================================================
-- КНОПКА AIM
--==================================================

aimButton.Activated:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	if AIM_ENABLED then
		aimButton.Text = "AIM ✓"
		aimButton.BackgroundColor3 = PURPLE
		fov.Visible = true
	else
		aimButton.Text = "AIM"
		aimButton.BackgroundColor3 = DARK
		fov.Visible = false
	end
end)

--==================================================
-- ОБНОВЛЕНИЕ ПОСЛЕ РЕСПАВНА
--==================================================

LocalPlayer.CharacterAdded:Connect(function()

	task.wait(1)

	-- Возвращаем FOV после загрузки нового персонажа
	fov.Visible = AIM_ENABLED

	-- Обновляем камеру Roblox
	workspace.CurrentCamera = workspace.CurrentCamera
end)
