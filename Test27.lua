--==================================================
-- SIMPLE ESP + HEAD AIM ASSIST
-- ROBLOX STUDIO / LOCAL SCRIPT
-- StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	ESP = true,
	Aim = true,

	FOV = 140,
	Smoothness = 0.12,

	TeamCheck = true,

	-- ПКМ
	AimKey = Enum.UserInputType.MouseButton2
}

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Aim_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- MENU
--==================================================

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.fromOffset(190, 145)
Menu.Position = UDim2.fromOffset(20, 200)
Menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Menu.BorderSizePixel = 0
Menu.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 8)
MenuCorner.Parent = Menu

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundTransparency = 1
Title.Text = "ESP + AIM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Menu

--==================================================
-- BUTTON FUNCTION
--==================================================

local function CreateButton(text, y)
	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -20, 0, 30)
	Button.Position = UDim2.fromOffset(10, y)

	Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Button.BorderSizePixel = 0

	Button.Text = text
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 13
	Button.Font = Enum.Font.Gotham

	Button.Parent = Menu

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = Button

	return Button
end

local ESPButton = CreateButton("ESP: ON", 38)
local AimButton = CreateButton("AIM: ON", 73)
local FOVButton = CreateButton("FOV: 140", 108)

--==================================================
-- ESP BUTTON
--==================================================

ESPButton.MouseButton1Click:Connect(function()

	Settings.ESP = not Settings.ESP

	if Settings.ESP then
		ESPButton.Text = "ESP: ON"
	else
		ESPButton.Text = "ESP: OFF"
	end

end)

--==================================================
-- AIM BUTTON
--==================================================

AimButton.MouseButton1Click:Connect(function()

	Settings.Aim = not Settings.Aim

	if Settings.Aim then
		AimButton.Text = "AIM: ON"
	else
		AimButton.Text = "AIM: OFF"
	end

end)

--==================================================
-- FOV BUTTON
--==================================================

FOVButton.MouseButton1Click:Connect(function()

	if Settings.FOV == 90 then

		Settings.FOV = 140

	elseif Settings.FOV == 140 then

		Settings.FOV = 200

	else

		Settings.FOV = 90

	end

	FOVButton.Text = "FOV: " .. Settings.FOV

end)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")

FOVCircle.Name = "FOVCircle"

FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)

FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0

FOVCircle.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")

FOVStroke.Thickness = 1.5
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Transparency = 0.25

FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")

FOVCorner.CornerRadius = UDim.new(1, 0)

FOVCorner.Parent = FOVCircle

--==================================================
-- ESP STORAGE
--==================================================

local Highlights = {}

--==================================================
-- REMOVE ESP
--==================================================

local function RemoveESP(Player)

	if Highlights[Player] then

		Highlights[Player]:Destroy()

		Highlights[Player] = nil

	end

end

--==================================================
-- CREATE ESP
--==================================================

local function CreateESP(Player)

	if Player == LocalPlayer then
		return
	end

	if Highlights[Player] then
		return
	end

	local function SetupCharacter(Character)

		RemoveESP(Player)

		local Highlight = Instance.new("Highlight")

		Highlight.Name = "ESP"

		Highlight.Adornee = Character

		Highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		Highlight.FillTransparency = 0.65

		Highlight.OutlineTransparency = 0

		Highlight.FillColor =
			Color3.fromRGB(255, 70, 70)

		Highlight.OutlineColor =
			Color3.fromRGB(255, 255, 255)

		Highlight.Parent = ScreenGui

		Highlights[Player] = Highlight

	end

	if Player.Character then
		SetupCharacter(Player.Character)
	end

	Player.CharacterAdded:Connect(function(Character)

		task.wait(0.2)

		if Player.Parent then
			SetupCharacter(Character)
		end

	end)

end

--==================================================
-- PLAYERS
--==================================================

for _, Player in ipairs(Players:GetPlayers()) do

	CreateESP(Player)

end

Players.PlayerAdded:Connect(function(Player)

	CreateESP(Player)

end)

Players.PlayerRemoving:Connect(function(Player)

	RemoveESP(Player)

end)

--==================================================
-- TEAM CHECK
--==================================================

local function IsEnemy(Player)

	if not Settings.TeamCheck then
		return true
	end

	if LocalPlayer.Team == nil then
		return true
	end

	if Player.Team == nil then
		return true
	end

	return LocalPlayer.Team ~= Player.Team

end

--==================================================
-- GET CLOSEST HEAD
--==================================================

local function GetClosestHead()

	Camera = workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local Viewport = Camera.ViewportSize

	local ScreenCenter = Vector2.new(
		Viewport.X / 2,
		Viewport.Y / 2
	)

	local ClosestHead = nil

	local ClosestDistance = Settings.FOV

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer then

			if IsEnemy(Player) then

				local Character = Player.Character

				if Character then

					local Humanoid =
						Character:FindFirstChildOfClass("Humanoid")

					local Head =
						Character:FindFirstChild("Head")

					if Humanoid
						and Head
						and Humanoid.Health > 0 then

						local ScreenPosition, Visible =
							Camera:WorldToViewportPoint(
								Head.Position
							)

						if Visible then

							local HeadScreen =
								Vector2.new(
									ScreenPosition.X,
									ScreenPosition.Y
								)

							local Distance =
								(HeadScreen - ScreenCenter).Magnitude

							if Distance <= ClosestDistance then

								ClosestDistance = Distance

								ClosestHead = Head

							end

						end

					end

				end

			end

		end

	end

	return ClosestHead

end

--==================================================
-- AIM INPUT
--==================================================

local Aiming = false

UserInputService.InputBegan:Connect(function(Input, Processed)

	if Processed then
		return
	end

	if Input.UserInputType == Settings.AimKey then

		Aiming = true

	end

end)

UserInputService.InputEnded:Connect(function(Input)

	if Input.UserInputType == Settings.AimKey then

		Aiming = false

	end

end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	--==============================================
	-- FOV
	--==============================================

	local Viewport = Camera.ViewportSize

	FOVCircle.Position = UDim2.fromOffset(
		Viewport.X / 2,
		Viewport.Y / 2
	)

	FOVCircle.Size = UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

	FOVCircle.Visible = Settings.Aim

	--==============================================
	-- ESP
	--==============================================

	for Player, Highlight in pairs(Highlights) do

		if Settings.ESP
			and Player.Character
			and Player.Character.Parent
			and IsEnemy(Player) then

			Highlight.Enabled = true

		else

			Highlight.Enabled = false

		end

	end

	--==============================================
	-- AIM
	--==============================================

	if Settings.Aim and Aiming then

		local Head = GetClosestHead()

		if Head then

			local CameraPosition =
				Camera.CFrame.Position

			local TargetCFrame =
				CFrame.lookAt(
					CameraPosition,
					Head.Position
				)

			Camera.CFrame =
				Camera.CFrame:Lerp(
					TargetCFrame,
					Settings.Smoothness
				)

		end

	end

end)
