local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// НАСТРОЙКИ
local ESP_ENABLED = true
local AIM_ENABLED = false

local AIM_FOV = 150
local AIM_DISTANCE = 500
local AIM_SMOOTHNESS = 0.15

local espObjects = {}

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// КНОПКИ
local function createButton(name, text, xOffset)
	local button = Instance.new("TextButton")

	button.Name = name
	button.Text = text
	button.Size = UDim2.fromOffset(80, 34)
	button.Position = UDim2.new(1, xOffset, 0, 12)

	button.BackgroundTransparency = 0.15
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = true

	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local espButton = createButton(
	"ESPButton",
	"ESP ON",
	-175
)

local aimButton = createButton(
	"AimButton",
	"AIM OFF",
	-85
)

--// FOV КРУГ
local fovCircle = Instance.new("Frame")
fovCircle.Name = "AimFOV"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)

fovCircle.Position = UDim2.fromScale(0.5, 0.5)

fovCircle.Size = UDim2.fromOffset(
	AIM_FOV * 2,
	AIM_FOV * 2
)

fovCircle.BackgroundTransparency = 1
fovCircle.Visible = true

fovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 2
fovStroke.Transparency = 0.25
fovStroke.Parent = fovCircle

--// ESP
local function removeESP(player)
	if espObjects[player] then
		espObjects[player]:Destroy()
		espObjects[player] = nil
	end
end

local function addESP(player)
	if player == LocalPlayer then
		return
	end

	local function setup(character)
		removeESP(player)

		if not ESP_ENABLED then
			return
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "PlayerESP"

		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0

		highlight.Parent = character

		espObjects[player] = highlight
	end

	if player.Character then
		setup(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.3)

		if ESP_ENABLED then
			setup(character)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	addESP(player)
end

Players.PlayerAdded:Connect(addESP)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

--// ESP ON/OFF
espButton.Activated:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then

		espButton.Text = "ESP ON"

		for _, player in ipairs(Players:GetPlayers()) do
			addESP(player)
		end

	else

		espButton.Text = "ESP OFF"

		for player in pairs(espObjects) do
			removeESP(player)
		end
	end
end)

--// ПОИСК ЦЕЛИ
local function getClosestTarget()

	local closestTarget = nil
	local closestScreenDistance = AIM_FOV

	local viewportSize = Camera.ViewportSize

	local screenCenter = Vector2.new(
		viewportSize.X / 2,
		viewportSize.Y / 2
	)

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

					local distance =
						(root.Position - Camera.CFrame.Position).Magnitude

					if distance <= AIM_DISTANCE then

						local screenPosition, onScreen =
							Camera:WorldToViewportPoint(
								head.Position
							)

						if onScreen and screenPosition.Z > 0 then

							local screenPoint = Vector2.new(
								screenPosition.X,
								screenPosition.Y
							)

							local screenDistance =
								(screenPoint - screenCenter).Magnitude

							if screenDistance < closestScreenDistance then

								closestScreenDistance =
									screenDistance

								closestTarget = head
							end
						end
					end
				end
			end
		end
	end

	return closestTarget
end

--// AIM
RunService.RenderStepped:Connect(function()

	if not AIM_ENABLED then
		return
	end

	local target = getClosestTarget()

	if not target then
		return
	end

	local cameraPosition =
		Camera.CFrame.Position

	local direction =
		(target.Position - cameraPosition).Unit

	local targetCFrame =
		CFrame.lookAt(
			cameraPosition,
			cameraPosition + direction
		)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			targetCFrame,
			AIM_SMOOTHNESS
		)
end)

--// AIM ON/OFF
aimButton.Activated:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	if AIM_ENABLED then
		aimButton.Text = "AIM ON"
	else
		aimButton.Text = "AIM OFF"
	end
end)

--// ОБНОВЛЕНИЕ FOV
local function updateFOV()

	fovCircle.Size = UDim2.fromOffset(
		AIM_FOV * 2,
		AIM_FOV * 2
	)
end

updateFOV()
