--// TRAINING AIM ASSIST + ESP
--// Roblox Studio — для собственной игры

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AIM_ENABLED = true
local ESP_ENABLED = true
local AIM_FOV = 85
local AIM_DISTANCE = 500
local AIM_SMOOTHNESS = 0.18
local HEAD_WEIGHT = 0.60
local BODY_WEIGHT = 0.40

local currentTarget = nil
local espObjects = {}

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingCombatUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local PANEL = Color3.fromRGB(24, 20, 32)
local ACTIVE = Color3.fromRGB(145, 75, 235)
local TEXT = Color3.fromRGB(255, 255, 255)

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.Size = UDim2.fromOffset(170, 42)
menu.Position = UDim2.new(1, -180, 0, 10)
menu.BackgroundColor3 = PANEL
menu.BackgroundTransparency = 0.08
menu.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = ACTIVE
menuStroke.Transparency = 0.35
menuStroke.Thickness = 1.5
menuStroke.Parent = menu

local function createButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(76, 28)
	button.Position = position
	button.BackgroundColor3 = ACTIVE
	button.BackgroundTransparency = 0.08
	button.Text = text
	button.TextColor3 = TEXT
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = menu

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local aimButton = createButton("AimButton", "AIM ✓", UDim2.fromOffset(5, 7))
local espButton = createButton("ESPButton", "ESP ✓", UDim2.fromOffset(89, 7))

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOV"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(AIM_FOV * 2, AIM_FOV * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = ACTIVE
fovStroke.Thickness = 2
fovStroke.Transparency = 0.15
fovStroke.Parent = fovCircle

local function getAimPoint(character)
	local head = character:FindFirstChild("Head")
	local body = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

	if head and body then
		return head.Position:Lerp(body.Position, BODY_WEIGHT)
	elseif head then
		return head.Position
	elseif body then
		return body.Position
	end

	return nil
end

local function isValidTarget(player)
	if player == LocalPlayer then return false end

	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return humanoid and humanoid.Health > 0 and root
end

local function findTarget()
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local bestPlayer = nil
	local bestDistance = AIM_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if isValidTarget(player) then
			local character = player.Character
			local root = character:FindFirstChild("HumanoidRootPart")
			local aimPoint = getAimPoint(character)

			if root and aimPoint then
				local worldDistance = (root.Position - camera.CFrame.Position).Magnitude

				if worldDistance <= AIM_DISTANCE then
					local screen, visible = camera:WorldToViewportPoint(aimPoint)

					if visible and screen.Z > 0 then
						local point = Vector2.new(screen.X, screen.Y)
						local distance = (point - center).Magnitude

						if distance < bestDistance then
							bestDistance = distance
							bestPlayer = player
						end
					end
				end
			end
		end
	end

	return bestPlayer
end

local function targetStillInsideFOV(player)
	if not player or not isValidTarget(player) then return false end

	local camera = workspace.CurrentCamera
	if not camera then return false end

	local aimPoint = getAimPoint(player.Character)
	if not aimPoint then return false end

	local screen, visible = camera:WorldToViewportPoint(aimPoint)
	if not visible or screen.Z <= 0 then return false end

	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local point = Vector2.new(screen.X, screen.Y)

	return (point - center).Magnitude <= AIM_FOV
end

RunService:BindToRenderStep(
	"TrainingAim",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if not AIM_ENABLED then
			currentTarget = nil
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		if not currentTarget then
			currentTarget = findTarget()
		end

		if currentTarget and not targetStillInsideFOV(currentTarget) then
			currentTarget = nil
			return
		end

		if not currentTarget then return end

		local aimPoint = getAimPoint(currentTarget.Character)
		if not aimPoint then
			currentTarget = nil
			return
		end

		local targetCFrame = CFrame.lookAt(camera.CFrame.Position, aimPoint)

		camera.CFrame = camera.CFrame:Lerp(
			targetCFrame,
			AIM_SMOOTHNESS
		)
	end
)

local function removeESP(player)
	local data = espObjects[player]
	if data then
		if data.gui then data.gui:Destroy() end
		espObjects[player] = nil
	end
end

local function createESP(player, character)
	if player == LocalPlayer or not ESP_ENABLED then return end

	removeESP(player)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(75, 100)
	billboard.AlwaysOnTop = true
	billboard.Parent = gui

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromScale(0.75, 0.85)
	box.BackgroundTransparency = 1
	box.Parent = billboard

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = ACTIVE
	boxStroke.Thickness = 2
	boxStroke.Parent = box

	local hpBackground = Instance.new("Frame")
	hpBackground.AnchorPoint = Vector2.new(0, 0.5)
	hpBackground.Position = UDim2.new(0, -8, 0.5, 0)
	hpBackground.Size = UDim2.new(0, 5, 0.85, 0)
	hpBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	hpBackground.BorderSizePixel = 0
	hpBackground.Parent = billboard

	local hpBar = Instance.new("Frame")
	hpBar.AnchorPoint = Vector2.new(0, 1)
	hpBar.Position = UDim2.fromScale(0, 1)
	hpBar.Size = UDim2.fromScale(1, 1)
	hpBar.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hpBackground

	espObjects[player] = {
		gui = billboard,
		humanoid = humanoid,
		hp = hpBar
	}
end

local function setupESPPlayer(player)
	if player == LocalPlayer then return end

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
	setupESPPlayer(player)
end

Players.PlayerAdded:Connect(setupESPPlayer)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
	for player, data in pairs(espObjects) do
		if data.humanoid and data.hp and data.humanoid.Parent then
			local health = math.clamp(
				data.humanoid.Health / math.max(data.humanoid.MaxHealth, 1),
				0,
				1
			)
			data.hp.Size = UDim2.fromScale(1, health)
		end
	end
end)

aimButton.Activated:Connect(function()
	AIM_ENABLED = not AIM_ENABLED

	if AIM_ENABLED then
		aimButton.Text = "AIM ✓"
		aimButton.BackgroundColor3 = ACTIVE
		fovCircle.Visible = true
	else
		aimButton.Text = "AIM"
		aimButton.BackgroundColor3 = PANEL
		fovCircle.Visible = false
		currentTarget = nil
	end
end)

espButton.Activated:Connect(function()
	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then
		espButton.Text = "ESP ✓"
		espButton.BackgroundColor3 = ACTIVE

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				createESP(player, player.Character)
			end
		end
	else
		espButton.Text = "ESP"
		espButton.BackgroundColor3 = PANEL

		for player in pairs(espObjects) do
			removeESP(player)
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	currentTarget = nil
	task.wait(1)
	fovCircle.Visible = AIM_ENABLED
end)
