--// SIMPLE ESP + HEAD AIM ASSIST
--// Roblox Studio / LocalScript
--// StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	ESP = true,
	Aim = true,

	FOV = 140,
	Smoothness = 0.12,

	TeamCheck = true,
	AimKey = Enum.UserInputType.MouseButton2
}

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleESP"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

-- Main menu
local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(190, 145)
menu.Position = UDim2.fromOffset(20, 200)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
menu.BorderSizePixel = 0
menu.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = menu

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "ESP  +  AIM"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.Parent = menu

local function makeButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 30)
	button.Position = UDim2.fromOffset(10, y)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 13
	button.Font = Enum.Font.Gotham
	button.Parent = menu

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = button

	return button
end

local espButton = makeButton("ESP: ON", 38)
local aimButton = makeButton("AIM: ON", 73)
local fovButton = makeButton("FOV: 140", 108)

espButton.MouseButton1Click:Connect(function()
	Settings.ESP = not Settings.ESP
	espButton.Text = "ESP: " .. (Settings.ESP and "ON" or "OFF")
end)

aimButton.MouseButton1Click:Connect(function()
	Settings.Aim = not Settings.Aim
	aimButton.Text = "AIM: " .. (Settings.Aim and "ON" or "OFF")
end)

fovButton.MouseButton1Click:Connect(function()
	if Settings.FOV == 140 then
		Settings.FOV = 90
	elseif Settings.FOV == 90 then
		Settings.FOV = 200
	else
		Settings.FOV = 140
	end

	fovButton.Text = "FOV: " .. Settings.FOV
end)

--==================================================
-- FOV CIRCLE
--==================================================

local fov = Instance.new("Frame")
fov.Name = "FOV"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.25
stroke.Parent = fov

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

--==================================================
-- ESP
--==================================================

local highlights = {}

local function removeESP(player)
	if highlights[player] then
		highlights[player]:Destroy()
		highlights[player] = nil
	end
end

local function createESP(player)
	if player == LP then
		return
	end

	if highlights[player] then
		return
	end

	local function setup(character)
		removeESP(player)

		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP"
		highlight.Adornee = character
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0
		highlight.FillColor = Color3.fromRGB(255, 70, 70)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.Parent = gui

		highlights[player] = highlight
	end

	if player.Character then
		setup(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)

		if player.Parent then
			setup(character)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	createESP(player)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

--==================================================
-- AIM TARGET
--==================================================

local function isEnemy(player)
	if not Settings.TeamCheck then
		return true
	end

	if LP.Team == nil or player.Team == nil then
		return true
	end

	return LP.Team ~= player.Team
end

local function getHeadTarget()
	local mouse = UIS:GetMouseLocation()

	local closestHead = nil
	local closestDistance = Settings.FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP and isEnemy(player) then

			local character = player.Character

			if character then
				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				local head =
					character:FindFirstChild("Head")

				if humanoid
					and head
					and humanoid.Health > 0 then

					local screenPos, visible =
						Camera:WorldToViewportPoint(head.Position)

					if visible then
						local screenPoint =
							Vector2.new(screenPos.X, screenPos.Y)

						local distance =
							(screenPoint - mouse).Magnitude

						if distance <= closestDistance then
							closestDistance = distance
							closestHead = head
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

local aiming = false

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.UserInputType == Settings.AimKey then
		aiming = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Settings.AimKey then
		aiming = false
	end
end)

--==================================================
-- UPDATE
--==================================================

RunService.RenderStepped:Connect(function()

	-- FOV
	local mouse = UIS:GetMouseLocation()

	fov.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	fov.Size = UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

	-- ESP
	for player, highlight in pairs(highlights) do
		if Settings.ESP
			and player.Character
			and player.Character.Parent
			and isEnemy(player) then

			highlight.Enabled = true
		else
			highlight.Enabled = false
		end
	end

	-- AIM
	if Settings.Aim and aiming then
		local head = getHeadTarget()

		if head then
			local cameraPosition = Camera.CFrame.Position

			local targetCFrame =
				CFrame.lookAt(
					cameraPosition,
					head.Position
				)

			Camera.CFrame =
				Camera.CFrame:Lerp(
					targetCFrame,
          Settings.Smoothness
				)
		end
	end
end)
