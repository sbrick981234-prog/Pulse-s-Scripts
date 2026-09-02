-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Backpack = Player:WaitForChild("Backpack")

-----/Tool/-----
local Tool = Instance.new("Tool")
Tool.Name = "Compass"
Tool.RequiresHandle = false
Tool.CanBeDropped = false
Tool.TextureId = "rbxassetid://124693934610044"
Tool.ToolTip = "Compass"
Tool.Parent = Backpack

-----/GUI/-----
local Gui = Instance.new("ScreenGui")
Gui.Name = "CompassGui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

-----/Main Circle/-----
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(360, 360)
Main.Position = UDim2.new(0.5, -180, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(1, 0)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.82
MainStroke.Thickness = 1
MainStroke.Parent = Main

local Aspect = Instance.new("UIAspectRatioConstraint")
Aspect.AspectRatio = 1
Aspect.Parent = Main

-----/Title/-----
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromOffset(180, 30)
Title.Position = UDim2.new(0.5, -90, 0, 48)
Title.BackgroundTransparency = 1
Title.Text = "COMPASS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-----/Subtitle/-----
local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.fromOffset(220, 20)
Subtitle.Position = UDim2.new(0.5, -110, 0, 74)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Configuration"
Subtitle.TextColor3 = Color3.fromRGB(130, 130, 130)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = Main

-----/Container/-----
local Container = Instance.new("Frame")
Container.Name = "Settings"
Container.Size = UDim2.fromOffset(245, 190)
Container.Position = UDim2.new(0.5, -122, 0, 104)
Container.BackgroundTransparency = 1
Container.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Top
Layout.Parent = Container

-----/Toggle Creator/-----
local function CreateToggle(Name, Default, Callback)

	local Button = Instance.new("TextButton")
	Button.Name = Name
	Button.Size = UDim2.fromOffset(230, 34)
	Button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.Parent = Container

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 9)
	Corner.Parent = Button

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -55, 1, 0)
	Label.Position = UDim2.fromOffset(13, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Name
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextColor3 = Color3.fromRGB(235, 235, 235)
	Label.TextSize = 12
	Label.Font = Enum.Font.GothamMedium
	Label.Parent = Button

	local Indicator = Instance.new("Frame")
	Indicator.Size = UDim2.fromOffset(30, 16)
	Indicator.Position = UDim2.new(1, -42, 0.5, -8)
	Indicator.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Indicator.BorderSizePixel = 0
	Indicator.Parent = Button

	local IndicatorCorner = Instance.new("UICorner")
	IndicatorCorner.CornerRadius = UDim.new(1, 0)
	IndicatorCorner.Parent = Indicator

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(12, 12)
	Dot.Position = UDim2.fromOffset(2, 2)
	Dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	Dot.BorderSizePixel = 0
	Dot.Parent = Indicator

	local DotCorner = Instance.new("UICorner")
	DotCorner.CornerRadius = UDim.new(1, 0)
	DotCorner.Parent = Dot

	local State = Default

	local function Update()

		if State then

			TweenService:Create(
				Indicator,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad),
				{
					BackgroundColor3 = Color3.fromRGB(65, 65, 65)
				}
			):Play()

			TweenService:Create(
				Dot,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad),
				{
					Position = UDim2.fromOffset(16, 2),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				}
			):Play()

		else

			TweenService:Create(
				Indicator,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad),
				{
					BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				}
			):Play()

			TweenService:Create(
				Dot,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad),
				{
					Position = UDim2.fromOffset(2, 2),
					BackgroundColor3 = Color3.fromRGB(180, 180, 180)
				}
			):Play()

		end

		if Callback then
			Callback(State)
		end
	end

	Button.MouseEnter:Connect(function()

		TweenService:Create(
			Button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{
				BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			}
		):Play()

	end)

	Button.MouseLeave:Connect(function()

		TweenService:Create(
			Button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{
				BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			}
		):Play()

	end)

	Button.MouseButton1Click:Connect(function()

		State = not State
		Update()

	end)

	Update()

	return Button
end

-----/Settings/-----

CreateToggle("Enabled", true, function(Value)
	print("Enabled:", Value)
end)

CreateToggle("Auto Build", false, function(Value)
	print("Auto Build:", Value)
end)

CreateToggle("Effects", true, function(Value)
	print("Effects:", Value)
end)

CreateToggle("Notifications", true, function(Value)
	print("Notifications:", Value)
end)

CreateToggle("Compass", true, function(Value)
	print("Compass:", Value)
end)

-----/Close Button/-----

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(0.5, 125, 0, 52)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(150, 150, 150)
Close.TextSize = 22
Close.Font = Enum.Font.GothamMedium
Close.Parent = Main

Close.MouseEnter:Connect(function()

	TweenService:Create(
		Close,
		TweenInfo.new(0.15),
		{
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}
	):Play()

end)

Close.MouseLeave:Connect(function()

	TweenService:Create(
		Close,
		TweenInfo.new(0.15),
		{
			TextColor3 = Color3.fromRGB(150, 150, 150)
		}
	):Play()

end)

-----/Open Animation/-----

local OpenSize = UDim2.fromOffset(360, 360)

local function Open()

	Main.Visible = true
	Main.Size = UDim2.fromOffset(0, 0)

	TweenService:Create(
		Main,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size = OpenSize
		}
	):Play()

end

-----/Close Animation/-----

local function CloseGui()

	if not Main.Visible then
		return
	end

	local Tween = TweenService:Create(
		Main,
		TweenInfo.new(
			0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),
		{
			Size = UDim2.fromOffset(0, 0)
		}
	)

	Tween:Play()

	Tween.Completed:Once(function()

		Main.Visible = false
		Main.Size = OpenSize

	end)

end

Close.MouseButton1Click:Connect(CloseGui)

-----/Tool Events/-----

Tool.Equipped:Connect(function()
	Open()
end)

Tool.Unequipped:Connect(function()
	CloseGui()
end)

-----/Dragging/-----

local Dragging = false
local DragStart
local StartPosition

Main.InputBegan:Connect(function(Input)

	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position

		Input.Changed:Connect(function()

			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end

		end)

	end

end)

UserInputService.InputChanged:Connect(function(Input)

	if not Dragging then
		return
	end

	if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then

		local Delta = Input.Position - DragStart

		Main.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)

	end

end)
