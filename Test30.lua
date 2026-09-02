--===========================================================================
-- ROBLOX MOBILE - ESP + AIMBOT + GUI
-- Для телефонов и планшетов
--===========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--===========================================================================
-- НАСТРОЙКИ
--===========================================================================

local ESP_ENABLED = false
local AIMBOT_ENABLED = false
local ESP_MAX_DISTANCE = 300
local AIM_MAX_DISTANCE = 200
local AIM_SMOOTHNESS = 0.15
local AIM_PART = "Head"
local FOV_RADIUS = 120

--===========================================================================
-- ПЕРЕМЕННЫЕ
--===========================================================================

local espElements = {}
local holdingAim = false
local screenGui = nil
local aimButton = nil
local espStatusLabel = nil
local aimStatusLabel = nil

--===========================================================================
-- СОЗДАНИЕ GUI
--===========================================================================

local function createMobileGUI()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	
	-- Удаляем старый GUI если есть
	local oldGui = playerGui:FindFirstChild("MobileESPGui")
	if oldGui then oldGui:Destroy() end
	
	-- Основной ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileESPGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	--========================================================================
	-- ПАНЕЛЬ СТАТУСА (Верхний правый угол)
	--========================================================================
	
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusFrame"
	statusFrame.Size = UDim2.new(0, 150, 0, 80)
	statusFrame.Position = UDim2.new(1, -160, 0, 10)
	statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statusFrame.BackgroundTransparency = 0.3
	statusFrame.BorderSizePixel = 0
	statusFrame.Parent = screenGui
	
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 10)
	statusCorner.Parent = statusFrame
	
	-- Заголовок
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "🔧 MENU"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = statusFrame
	
	-- ESP статус
	espStatusLabel = Instance.new("TextLabel")
	espStatusLabel.Name = "ESPStatus"
	espStatusLabel.Size = UDim2.new(1, -10, 0, 20)
	espStatusLabel.Position = UDim2.new(0, 5, 0, 30)
	espStatusLabel.BackgroundTransparency = 1
	espStatusLabel.Text = "ESP: OFF"
	espStatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	espStatusLabel.TextSize = 14
	espStatusLabel.Font = Enum.Font.Gotham
	espStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	espStatusLabel.Parent = statusFrame
	
	-- Aim статус
	aimStatusLabel = Instance.new("TextLabel")
	aimStatusLabel.Name = "AimStatus"
	aimStatusLabel.Size = UDim2.new(1, -10, 0, 20)
	aimStatusLabel.Position = UDim2.new(0, 5, 0, 52)
	aimStatusLabel.BackgroundTransparency = 1
	aimStatusLabel.Text = "AIM: OFF"
	aimStatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	aimStatusLabel.TextSize = 14
	aimStatusLabel.Font = Enum.Font.Gotham
	aimStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	aimStatusLabel.Parent = statusFrame
	
	--========================================================================
	-- КНОПКА ESP (Левая сторона)
	--========================================================================
	
	local espButton = Instance.new("TextButton")
	espButton.Name = "ESPButton"
	espButton.Size = UDim2.new(0, 80, 0, 80)
	espButton.Position = UDim2.new(0, 20, 0.5, -100)
	espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	espButton.BackgroundTransparency = 0.2
	espButton.BorderSizePixel = 0
	espButton.Text = "👁️\nESP"
	espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	espButton.TextSize = 20
	espButton.Font = Enum.Font.GothamBold
	espButton.Parent = screenGui
	
	local espCorner = Instance.new("UICorner")
	espCorner.CornerRadius = UDim.new(1, 0) -- Круглая кнопка
	espCorner.Parent = espButton
	
	local espStroke = Instance.new("UIStroke")
	espStroke.Color = Color3.fromRGB(100, 100, 100)
	espStroke.Thickness = 3
	espStroke.Parent = espButton
	
	-- Анимация нажатия ESP
	espButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Анимация
			TweenService:Create(espButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 70, 0, 70),
				Position = UDim2.new(0, 25, 0.5, -95)
			}):Play()
			
			ToggleESP()
		end
	end)
	
	espButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(espButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 80, 0, 80),
				Position = UDim2.new(0, 20, 0.5, -100)
			}):Play()
		end
	end)
	
	--========================================================================
	-- КНОПКА AIMBOT (Левая сторона, ниже)
	--========================================================================
	
	local aimToggleButton = Instance.new("TextButton")
	aimToggleButton.Name = "AimToggleButton"
	aimToggleButton.Size = UDim2.new(0, 80, 0, 80)
	aimToggleButton.Position = UDim2.new(0, 20, 0.5, 20)
	aimToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	aimToggleButton.BackgroundTransparency = 0.2
	aimToggleButton.BorderSizePixel = 0
	aimToggleButton.Text = "🎯\nAIM"
	aimToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	aimToggleButton.TextSize = 20
	aimToggleButton.Font = Enum.Font.GothamBold
	aimToggleButton.Parent = screenGui
	
	local aimCorner = Instance.new("UICorner")
	aimCorner.CornerRadius = UDim.new(1, 0)
	aimCorner.Parent = aimToggleButton
	
	local aimStroke = Instance.new("UIStroke")
	aimStroke.Color = Color3.fromRGB(100, 100, 100)
	aimStroke.Thickness = 3
	aimStroke.Parent = aimToggleButton
	
	-- Анимация нажатия Aim Toggle
	aimToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(aimToggleButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 70, 0, 70),
				Position = UDim2.new(0, 25, 0.5, 25)
			}):Play()
			
			ToggleAimbot()
		end
	end)
	
	aimToggleButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(aimToggleButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 80, 0, 80),
				Position = UDim2.new(0, 20, 0.5, 20)
			}):Play()
		end
	end)
	
	--========================================================================
	-- КНОПКА СТРЕЛЬБЫ/AIM (Правая сторона - большая кнопка)
	--========================================================================
	
	aimButton = Instance.new("TextButton")
	aimButton.Name = "AimButton"
	aimButton.Size = UDim2.new(0, 100, 0, 100)
	aimButton.Position = UDim2.new(1, -120, 0.7, 0)
	aimButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	aimButton.BackgroundTransparency = 0.3
	aimButton.BorderSizePixel = 0
	aimButton.Text = "🔫\nFIRE"
	aimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	aimButton.TextSize = 24
	aimButton.Font = Enum.Font.GothamBold
	aimButton.Visible = false -- Показывается только когда Aimbot включен
	aimButton.Parent = screenGui
	
	local fireCorner = Instance.new("UICorner")
	fireCorner.CornerRadius = UDim.new(1, 0)
	fireCorner.Parent = aimButton
	
	local fireStroke = Instance.new("UIStroke")
	fireStroke.Color = Color3.fromRGB(255, 100, 100)
	fireStroke.Thickness = 4
	fireStroke.Parent = aimButton
	
	-- Нажатие - начать наведение
	aimButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingAim = true
			TweenService:Create(aimButton, TweenInfo.new(0.05), {
				Size = UDim2.new(0, 90, 0, 90),
				Position = UDim2.new(1, -115, 0.7, 5),
				BackgroundColor3 = Color3.fromRGB(50, 200, 50)
			}):Play()
			aimButton.Text = "🎯\nLOCK"
		end
	end)
	
	-- Отпускание - остановить наведение
	aimButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingAim = false
			TweenService:Create(aimButton, TweenInfo.new(0.05), {
				Size = UDim2.new(0, 100, 0, 100),
				Position = UDim2.new(1, -120, 0.7, 0),
				BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			}):Play()
			aimButton.Text = "🔫\nFIRE"
		end
	end)
	
	--========================================================================
	-- FOV КРУГ (Центр экрана)
	--========================================================================
	
	local fovFrame = Instance.new("Frame")
	fovFrame.Name = "FOVFrame"
	fovFrame.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
	fovFrame.Position = UDim2.new(0.5, -FOV_RADIUS, 0.5, -FOV_RADIUS)
	fovFrame.BackgroundTransparency = 1
	fovFrame.Visible = false
	fovFrame.Parent = screenGui
	
	local fovCircle = Instance.new("Frame")
	fovCircle.Name = "FOVCircle"
	fovCircle.Size = UDim2.new(1, 0, 1, 0)
	fovCircle.BackgroundTransparency = 1
	fovCircle.BorderSizePixel = 0
	fovCircle.Parent = fovFrame
	
	local fovStroke = Instance.new("UIStroke")
	fovStroke.Color = Color3.fromRGB(255, 255, 255)
	fovStroke.Thickness = 2
	fovStroke.Transparency = 0.5
	fovStroke.Parent = fovCircle
	
	local fovCorner = Instance.new("UICorner")
	fovCorner.CornerRadius = UDim.new(1, 0)
	fovCorner.Parent = fovCircle
	
	-- Точка в центре
	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, 6, 0, 6)
	centerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
	centerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	centerDot.BorderSizePixel = 0
	centerDot.Parent = fovCircle
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = centerDot
	
	-- Сохраняем ссылки
	screenGui.FOVFrame = fovFrame
end

--===========================================================================
-- ESP СИСТЕМА
--===========================================================================

local function createESP(player)
	if player == localPlayer then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or not head then return end
	
	if espElements[player] then
		removeESP(player)
	end
	
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local espGui = Instance.new("BillboardGui")
	espGui.Name = "ESP_" .. player.Name
	espGui.Adornee = head
	espGui.Size = UDim2.new(0, 150, 0, 50)
	espGui.StudsOffset = Vector3.new(0, 2.5, 0)
	espGui.AlwaysOnTop = true
	
	-- Фон
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.6
	bg.BorderSizePixel = 0
	bg.Parent = espGui
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 5)
	bgCorner.Parent = bg
	
	-- Имя
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -4, 0, 16)
	nameLabel.Position = UDim2.new(0, 2, 0, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = bg
	
	-- Здоровье
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, -8, 0, 6)
	healthBar.Position = UDim2.new(0, 4, 0, 20)
	healthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = bg
	
	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBar
	
	-- Дистанция
	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, -4, 0, 14)
	distLabel.Position = UDim2.new(0, 2, 0, 28)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextScaled = true
	distLabel.Font = Enum.Font.Gotham
	distLabel.Parent = bg
	
	espGui.Parent = playerGui
	
	-- Box
	local hrp = character:WaitForChild("HumanoidRootPart")
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESPBox"
	box.Size = Vector3.new(4, 6, 4)
	box.Adornee = hrp
	box.AlwaysOnTop = true
	box.ZIndex = 10
	box.Color3 = Color3.fromRGB(255, 0, 0)
	box.Transparency = 0.7
	box.Parent = camera
	
	espElements[player] = {
		Gui = espGui,
		Box = box,
		Character = character,
		Humanoid = humanoid
	}
end

local function removeESP(player)
	if espElements[player] then
		if espElements[player].Gui then
			espElements[player].Gui:Destroy()
		end
		if espElements[player].Box then
			espElements[player].Box:Destroy()
		end
		espElements[player] = nil
	end
end

local function updateESP()
	if not ESP_ENABLED then return end
	
	for player, data in pairs(espElements) do
		if player.Character and data.Character and data.Humanoid then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local head = player.Character:FindFirstChild("Head")
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			
			if hrp and head and humanoid and localHRP then
				-- Обновляем здоровье
				local healthFill = data.Gui.Background:FindFirstChild("HealthBar") and 
					data.Gui.Background.HealthBar:FindFirstChild("HealthFill")
				if healthFill then
					local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
					healthFill.Size = UDim2.new(hpPercent, 0, 1, 0)
					
					if hpPercent > 0.6 then
						healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
					elseif hpPercent > 0.3 then
						healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
					else
						healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
					end
				end
				
				-- Обновляем дистанцию
				local distLabel = data.Gui.Background:FindFirstChild("DistLabel")
				if distLabel then
					local distance = (localHRP.Position - hrp.Position).Magnitude
					distLabel.Text = math.floor(distance) .. "m"
					
					if distance > ESP_MAX_DISTANCE or humanoid.Health <= 0 then
						data.Gui.Enabled = false
						data.Box.Visible = false
					else
						data.Gui.Enabled = true
						data.Box.Visible = true
					end
				end
			end
		else
			removeESP(player)
		end
	end
end

--===========================================================================
-- AIMBOT СИСТЕМА
--===========================================================================

local function getClosestTarget()
	local closest = nil
	local closestDistance = FOV_RADIUS
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local targetPart = player.Character:FindFirstChild(AIM_PART)
			local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and targetPart and localHRP and humanoid.Health > 0 then
				local distance = (localHRP.Position - targetPart.Position).Magnitude
				if distance <= AIM_MAX_DISTANCE then
					local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
						local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
						local distFromCenter = (targetScreenPos - screenCenter).Magnitude
						
						if distFromCenter < closestDistance then
							closest = targetPart
							closestDistance = distFromCenter
						end
					end
				end
			end
		end
	end
	
	return closest
end

local function aimAt(target)
	if not target then return end
	
	local targetPos = target.Position
	local currentCF = camera.CFrame
	local targetDirection = (targetPos - currentCF.Position).Unit
	local targetCFrame = CFrame.new(currentCF.Position, currentCF.Position + targetDirection)
	camera.CFrame = currentCF:Lerp(targetCFrame, AIM_SMOOTHNESS)
end

--===========================================================================
-- УПРАВЛЕНИЕ
--===========================================================================

function ToggleESP()
	ESP_ENABLED = not ESP_ENABLED
	
	-- Обновляем UI
	if espStatusLabel then
		espStatusLabel.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
		espStatusLabel.TextColor3 = ESP_ENABLED and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
	end
	
	-- Обновляем ESP элементы
	for player, data in pairs(espElements) do
		if data.Gui then
			data.Gui.Enabled = ESP_ENABLED
		end
		if data.Box then
			data.Box.Visible = ESP_ENABLED
		end
	end
end

function ToggleAimbot()
	AIMBOT_ENABLED = not AIMBOT_ENABLED
	
	-- Обновляем UI
	if aimStatusLabel then
		aimStatusLabel.Text = "AIM: " .. (AIMBOT_ENABLED and "ON" or "OFF")
		aimStatusLabel.TextColor3 = AIMBOT_ENABLED and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
	end
	
	-- Показываем/скрываем кнопку стрельбы и FOV
	if aimButton then
		aimButton.Visible = AIMBOT_ENABLED
	end
	if screenGui and screenGui:FindFirstChild("FOVFrame") then
		screenGui.FOVFrame.Visible = AIMBOT_ENABLED
	end
end

--===========================================================================
-- ИНИЦИАЛИЗАЦИЯ
--===========================================================================

-- Создаём GUI
createMobileGUI()

-- Добавляем ESP для игроков
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		createESP(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		wait(1)
		createESP(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

-- Основной цикл
RunService.RenderStepped:Connect(function()
	updateESP()
	
	if AIMBOT_ENABLED and holdingAim then
		local target = getClosestTarget()
		if target then
			aimAt(target)
			-- Меняем цвет FOV круга при захвате цели
			if screenGui and screenGui:FindFirstChild("FOVFrame") then
				local circle = screenGui.FOVFrame:FindFirstChild("FOVCircle")
				if circle then
					circle.UIStroke.Color = Color3.fromRGB(0, 255, 0)
				end
			end
		else
			if screenGui and screenGui:FindFirstChild("FOVFrame") then
				local circle = screenGui.FOVFrame:FindFirstChild("FOVCircle")
				if circle then
					circle.UIStroke.Color = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
end)

--===========================================================================
-- ГОТОВО
--===========================================================================

print("=== Mobile ESP + Aimbot Loaded ===")
print("👁️ ESP Button - Toggle ESP")
print("🎯 AIM Button - Toggle Aimbot")
print("🔫 FIRE Button - Hold to aim (when aimbot ON)")
