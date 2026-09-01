--========================================================
-- MOBILE ESP + HEAD AIM + FOV
-- Roblox Studio / LocalScript
-- StarterPlayer > StarterPlayerScripts
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================
-- SETTINGS
--========================================================

local Settings = {
	ESP = true,
	Aim = true,

	FOV = 120,

	-- Чем меньше, тем быстрее наведение
	AimSmoothness = 0.18,

	TeamCheck = true,

	-- Размер ESP
	FillTransparency = 0.72,
	OutlineTransparency = 0
}

--========================================================
-- MAIN GUI
--========================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "MobileESP"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

--========================================================
-- MENU
--========================================================

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.fromOffset(210, 190)
Menu.Position = UDim2.fromOffset(18, 170)
Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Menu.BorderSizePixel = 0
Menu.Parent = Gui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 12)
MenuCorner.Parent = Menu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Thickness = 1
MenuStroke.Transparency = 0.35
MenuStroke.Color = Color3.fromRGB(100, 100, 110)
MenuStroke.Parent = Menu

--========================================================
-- TITLE
--========================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 38)
Title.Position = UDim2.fromOffset(12, 2)
Title.BackgroundTransparency = 1
Title.Text = "ESP  •  AIM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Menu

--========================================================
-- HIDE BUTTON
--========================================================

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.fromOffset(34, 30)
HideButton.Position = UDim2.new(1, -40, 0, 5)
HideButton.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
HideButton.BorderSizePixel = 0
HideButton.Text = "—"
HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HideButton.TextSize = 18
HideButton.Font = Enum.Font.GothamBold
HideButton.Parent = Menu

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 7)
HideCorner.Parent = HideButton

--========================================================
-- BUTTON CREATOR
--========================================================

local function CreateButton(Text, Y)

	local Button = Instance.new("TextButton")

	Button.Size = UDim2.new(1, -20, 0, 34)
	Button.Position = UDim2.fromOffset(10, Y)

	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
	Button.BorderSizePixel = 0

	Button.Text = Text
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 13
	Button.Font = Enum.Font.GothamMedium

	Button.Parent = Menu

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Button

	return Button
end

local ESPButton = CreateButton("ESP    ON", 43)
local AimButton = CreateButton("AIM    ON", 82)
local FOVButton = CreateButton("FOV    120", 121)
local TeamButton = CreateButton("TEAM CHECK    ON", 160)

--========================================================
-- OPEN BUTTON
--========================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "Open"
OpenButton.Size = UDim2.fromOffset(50, 50)
OpenButton.Position = UDim2.fromOffset(18, 170)

OpenButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
OpenButton.BorderSizePixel = 0

OpenButton.Text = "☰"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 22
OpenButton.Font = Enum.Font.GothamBold

OpenButton.Visible = false
OpenButton.Parent = Gui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

--========================================================
-- HIDE / SHOW
--========================================================

HideButton.MouseButton1Click:Connect(function()

	Menu.Visible = false
	OpenButton.Visible = true

end)

OpenButton.MouseButton1Click:Connect(function()

	Menu.Visible = true
	OpenButton.Visible = false

end)

--========================================================
-- ESP BUTTON
--========================================================

ESPButton.MouseButton1Click:Connect(function()

	Settings.ESP = not Settings.ESP

	if Settings.ESP then
		ESPButton.Text = "ESP    ON"
	else
		ESPButton.Text = "ESP    OFF"
	end

end)

--========================================================
-- AIM BUTTON
--========================================================

AimButton.MouseButton1Click:Connect(function()

	Settings.Aim = not Settings.Aim

	if Settings.Aim then
		AimButton.Text = "AIM    ON"
	else
		AimButton.Text = "AIM    OFF"
	end

end)

--========================================================
-- FOV BUTTON
--========================================================

FOVButton.MouseButton1Click:Connect(function()

	if Settings.FOV == 80 then

		Settings.FOV = 120

	elseif Settings.FOV == 120 then

		Settings.FOV = 170

	elseif Settings.FOV == 170 then

		Settings.FOV = 220

	else

		Settings.FOV = 80

	end

	FOVButton.Text = "FOV    " .. Settings.FOV

end)

--========================================================
-- TEAM CHECK
--========================================================

TeamButton.MouseButton1Click:Connect(function()

	Settings.TeamCheck = not Settings.TeamCheck

	if Settings.TeamCheck then
		TeamButton.Text = "TEAM CHECK    ON"
	else
		TeamButton.Text = "TEAM CHECK    OFF"
	end

end)

--========================================================
-- DRAG MENU WITH TOUCH
--========================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseButton1 then

		Dragging = true

		DragStart = Input.Position
		StartPosition = Menu.Position

	end

end)

Title.InputEnded:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseButton1 then

		Dragging = false

	end

end)

UserInputService.InputChanged:Connect(function(Input)

	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.Touch
		and Input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local Delta = Input.Position - DragStart

	Menu.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)

	OpenButton.Position = Menu.Position

end)

--========================================================
-- FOV
--========================================================

local FOVGui = Instance.new("Frame")
FOVGui.Name = "FOV"
FOVGui.AnchorPoint = Vector2.new(0.5, 0.5)

FOVGui.BackgroundTransparency = 1
FOVGui.BorderSizePixel = 0

FOVGui.Parent = Gui

local Aspect = Instance.new("UIAspectRatioConstraint")
Aspect.AspectRatio = 1
Aspect.Parent = FOVGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.25
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Parent = FOVGui

--========================================================
-- CENTER DOT
--========================================================

local Dot = Instance.new("Frame")
Dot.Name = "CenterDot"

Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.Size = UDim2.fromOffset(4, 4)

Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Dot.BorderSizePixel = 0

Dot.Parent = Gui

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = Dot

--========================================================
-- ESP
--========================================================

local ESPObjects = {}

local function RemoveESP(Player)

	local Object = ESPObjects[Player]

	if Object then

		Object:Destroy()
		ESPObjects[Player] = nil

	end

end

local function CreateESP(Player)

	if Player == LocalPlayer then
		return
	end

	if ESPObjects[Player] then
		return
	end

	local function Setup(Character)

		RemoveESP(Player)

		local Highlight = Instance.new("Highlight")

		Highlight.Name = "PlayerESP"

		Highlight.Adornee = Character

		Highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		Highlight.FillTransparency =
			Settings.FillTransparency

		Highlight.OutlineTransparency =
			Settings.OutlineTransparency

		Highlight.FillColor =
			Color3.fromRGB(255, 70, 70)

		Highlight.OutlineColor =
			Color3.fromRGB(255, 255, 255)

		Highlight.Parent = Gui

		ESPObjects[Player] = Highlight

	end

	if Player.Character then
		Setup(Player.Character)
	end

	Player.CharacterAdded:Connect(function(Character)

		task.wait(0.2)

		if Player.Parent then
			Setup(Character)
		end

	end)

end

for _, Player in ipairs(Players:GetPlayers()) do
	CreateESP(Player)
end

Players.PlayerAdded:Connect(CreateESP)

Players.PlayerRemoving:Connect(RemoveESP)

--========================================================
-- ENEMY CHECK
--========================================================

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

--========================================================
-- FIND HEAD
--========================================================

local function GetClosestHead()

	Camera = workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local Viewport = Camera.ViewportSize

	local Center = Vector2.new(
		Viewport.X / 2,
		Viewport.Y / 2
	)

	local BestHead = nil
	local BestDistance = Settings.FOV

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player ~= LocalPlayer
			and IsEnemy(Player) then

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

						local Point = Vector2.new(
							ScreenPosition.X,
							ScreenPosition.Y
						)

						local Distance =
							(Point - Center).Magnitude

						if Distance <= BestDistance then

							BestDistance = Distance
							BestHead = Head

						end

					end

				end

			end

		end

	end

	return BestHead

end

--========================================================
-- MOBILE AIM BUTTON
--========================================================

local AimTouch = Instance.new("TextButton")

AimTouch.Name = "AimTouch"

AimTouch.Size = UDim2.fromOffset(72, 72)

AimTouch.Position =
	UDim2.new(1, -95, 1, -150)

AimTouch.BackgroundColor3 =
	Color3.fromRGB(35, 35, 40)

AimTouch.BackgroundTransparency = 0.15

AimTouch.BorderSizePixel = 0

AimTouch.Text = "AIM"

AimTouch.TextColor3 =
	Color3.fromRGB(255, 255, 255)

AimTouch.TextSize = 16

AimTouch.Font =
	Enum.Font.GothamBold

AimTouch.Parent = Gui

local AimTouchCorner = Instance.new("UICorner")

AimTouchCorner.CornerRadius =
	UDim.new(1, 0)

AimTouchCorner.Parent = AimTouch

local AimTouchStroke = Instance.new("UIStroke")

AimTouchStroke.Thickness = 2
AimTouchStroke.Transparency = 0.3

AimTouchStroke.Parent = AimTouch

--========================================================
-- AIM STATE
--========================================================

local Aiming = false

AimTouch.MouseButton1Down:Connect(function()

	if Settings.Aim then
		Aiming = true
	end

end)

AimTouch.MouseButton1Up:Connect(function()

	Aiming = false

end)

-- Touch support
AimTouch.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch then

		if Settings.Aim then
			Aiming = true
		end

	end

end)

AimTouch.InputEnded:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.Touch then

		Aiming = false

	end

end)

--========================================================
-- MAIN LOOP
--========================================================

RunService.RenderStepped:Connect(function()

	Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	--==============================================
	-- FOV POSITION
	--==============================================

	local Viewport = Camera.ViewportSize

	local CenterX = Viewport.X / 2
	local CenterY = Viewport.Y / 2

	FOVGui.Position = UDim2.fromOffset(
		CenterX,
		CenterY
	)

	FOVGui.Size = UDim2.fromOffset(
		Settings.FOV * 2,
		Settings.FOV * 2
	)

	Dot.Position = UDim2.fromOffset(
		CenterX,
		CenterY
	)

	FOVGui.Visible = Settings.Aim

	--==============================================
	-- ESP
	--==============================================

	for Player, Highlight in pairs(ESPObjects) do

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
					Settings.AimSmoothness
				)

		end

	end

end)
