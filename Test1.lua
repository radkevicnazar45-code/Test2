local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_ENABLED = true
local AIM_ENABLED = false

local AIM_FOV = 150
local AIM_DISTANCE = 500
local AIM_SMOOTHNESS = 0.15

local espObjects = {}

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TestAimESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function createButton(name, text, position)
	local button = Instance.new("TextButton")

	button.Name = name
	button.Text = text
	button.Size = UDim2.fromOffset(120, 50)
	button.Position = position

	button.BackgroundTransparency = 0.15
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	return button
end

local espButton = createButton(
	"ESPButton",
	"ESP: ON",
	UDim2.new(1, -135, 0, 100)
)

local aimButton = createButton(
	"AimButton",
	"AIM: OFF",
	UDim2.new(1, -135, 0, 160)
)

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
		highlight.Name = "TestESP"
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0
		highlight.Parent = character

		espObjects[player] = highlight
	end

	if player.Character then
		setup(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		setup(character)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	addESP(player)
end

Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(removeESP)

--// ESP button
espButton.Activated:Connect(function()
	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then
		espButton.Text = "ESP: ON"

		for _, player in ipairs(Players:GetPlayers()) do
			addESP(player)
		end
	else
		espButton.Text = "ESP: OFF"

		for player in pairs(espObjects) do
			removeESP(player)
		end
	end
end)

--// AIM
local function getClosestTarget()
	local closest = nil
	local closestDistance = AIM_FOV

	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then

			local humanoid =
				player.Character:FindFirstChildOfClass("Humanoid")

			local root =
				player.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and root and humanoid.Health > 0 then

				local distance3D =
					(root.Position - Camera.CFrame.Position).Magnitude

				if distance3D <= AIM_DISTANCE then

					local screenPosition, visible =
						Camera:WorldToViewportPoint(root.Position)

					if visible then

						local screenDistance =
							(
								Vector2.new(
									screenPosition.X,
									screenPosition.Y
								) - center
							).Magnitude

						if screenDistance < closestDistance then
							closestDistance = screenDistance
							closest = root
						end
					end
				end
			end
		end
	end

	return closest
end

RunService.RenderStepped:Connect(function()

	if not AIM_ENABLED then
		return
	end

	local target = getClosestTarget()

	if target then

		local cameraPosition = Camera.CFrame.Position

		local targetCFrame =
			CFrame.lookAt(
				cameraPosition,
				target.Position
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				targetCFrame,
				AIM_SMOOTHNESS
			)
	end
end)

--// AIM button
aimButton.Activated:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	if AIM_ENABLED then
		aimButton.Text = "AIM: ON"
	else
		aimButton.Text = "AIM: OFF"
	end
end)
