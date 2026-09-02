-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Backpack = Player:WaitForChild("Backpack")
local Camera = workspace.CurrentCamera

-----/Values/-----
local AccentColor = Color3.fromRGB(150, 90, 255)
local HeadingConnection = nil

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
Main.Size = UDim2.fromOffset(260, 300)
Main.Position = UDim2.new(0.5, -130, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.88
MainStroke.Thickness = 1
MainStroke.Parent = Main

-----/Title/-----
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromOffset(180, 22)
Title.Position = UDim2.new(0.5, -90, 0, 16)
Title.BackgroundTransparency = 1
Title.Text = "COMPASS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-----/Close Button/-----
local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.fromOffset(26, 26)
Close.Position = UDim2.new(1, -38, 0, 10)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(150, 150, 150)
Close.TextSize = 20
Close.Font = Enum.Font.GothamMedium
Close.Parent = Main

Close.MouseEnter:Connect(function()
	TweenService:Create(Close, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)

Close.MouseLeave:Connect(function()
	TweenService:Create(Close, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(150, 150, 150) }):Play()
end)

-----/Dial Frame/-----
local DialContainer = Instance.new("Frame")
DialContainer.Name = "DialContainer"
DialContainer.Size = UDim2.fromOffset(180, 180)
DialContainer.Position = UDim2.new(0.5, -90, 0, 52)
DialContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
DialContainer.BorderSizePixel = 0
DialContainer.Parent = Main

local DialCorner = Instance.new("UICorner")
DialCorner.CornerRadius = UDim.new(1, 0)
DialCorner.Parent = DialContainer

local DialStroke = Instance.new("UIStroke")
DialStroke.Color = Color3.fromRGB(255, 255, 255)
DialStroke.Transparency = 0.85
DialStroke.Thickness = 1
DialStroke.Parent = DialContainer

local Dial = Instance.new("Frame")
Dial.Name = "Dial"
Dial.Size = UDim2.fromScale(1, 1)
Dial.BackgroundTransparency = 1
Dial.Parent = DialContainer

-----/Cardinal Labels/-----
local Radius = 74

local CardinalData = {
	{ Text = "N", Angle = 0, Color = AccentColor },
	{ Text = "E", Angle = 90, Color = Color3.fromRGB(190, 190, 190) },
	{ Text = "S", Angle = 180, Color = Color3.fromRGB(190, 190, 190) },
	{ Text = "W", Angle = 270, Color = Color3.fromRGB(190, 190, 190) },
}

local CardinalLabels = {}

for _, Data in ipairs(CardinalData) do
	local Label = Instance.new("TextLabel")
	Label.Name = Data.Text
	Label.Size = UDim2.fromOffset(24, 24)
	Label.BackgroundTransparency = 1
	Label.Text = Data.Text
	Label.TextColor3 = Data.Color
	Label.TextSize = 16
	Label.Font = Enum.Font.GothamBold
	Label.Parent = Dial

	CardinalLabels[Label] = Data.Angle
end

-----/Tick Marks/-----
for Index = 0, 11 do
	local Angle = Index * 30

	local Tick = Instance.new("Frame")
	Tick.Name = "Tick"
	Tick.AnchorPoint = Vector2.new(0.5, 0.5)
	Tick.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	Tick.BorderSizePixel = 0

	if Angle % 90 == 0 then
		Tick.Size = UDim2.fromOffset(2, 10)
	else
		Tick.Size = UDim2.fromOffset(2, 6)
	end

	local Radians = math.rad(Angle)
	local X = math.sin(Radians) * 82
	local Y = -math.cos(Radians) * 82

	Tick.Position = UDim2.new(0.5, X, 0.5, Y)
	Tick.Rotation = Angle
	Tick.Parent = Dial
end

-----/Center Pointer/-----
local Pointer = Instance.new("Frame")
Pointer.Name = "Pointer"
Pointer.AnchorPoint = Vector2.new(0.5, 1)
Pointer.Size = UDim2.fromOffset(3, 14)
Pointer.Position = UDim2.new(0.5, 0, 0.5, 0)
Pointer.BackgroundColor3 = AccentColor
Pointer.BorderSizePixel = 0
Pointer.Parent = DialContainer

local PointerCorner = Instance.new("UICorner")
PointerCorner.CornerRadius = UDim.new(1, 0)
PointerCorner.Parent = Pointer

local CenterDot = Instance.new("Frame")
CenterDot.Name = "CenterDot"
CenterDot.AnchorPoint = Vector2.new(0.5, 0.5)
CenterDot.Size = UDim2.fromOffset(6, 6)
CenterDot.Position = UDim2.new(0.5, 0, 0.5, 0)
CenterDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CenterDot.BorderSizePixel = 0
CenterDot.Parent = DialContainer

local CenterDotCorner = Instance.new("UICorner")
CenterDotCorner.CornerRadius = UDim.new(1, 0)
CenterDotCorner.Parent = CenterDot

-----/Readout/-----
local HeadingLabel = Instance.new("TextLabel")
HeadingLabel.Name = "HeadingLabel"
HeadingLabel.Size = UDim2.fromOffset(200, 30)
HeadingLabel.Position = UDim2.new(0.5, -100, 1, -46)
HeadingLabel.BackgroundTransparency = 1
HeadingLabel.Text = "000°"
HeadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HeadingLabel.TextSize = 20
HeadingLabel.Font = Enum.Font.GothamBold
HeadingLabel.Parent = Main

local DirectionLabel = Instance.new("TextLabel")
DirectionLabel.Name = "DirectionLabel"
DirectionLabel.Size = UDim2.fromOffset(200, 16)
DirectionLabel.Position = UDim2.new(0.5, -100, 1, -20)
DirectionLabel.BackgroundTransparency = 1
DirectionLabel.Text = "NORTH"
DirectionLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
DirectionLabel.TextSize = 11
DirectionLabel.Font = Enum.Font.Gotham
DirectionLabel.Parent = Main

-----/Heading Logic/-----
local DirectionNames = {
	"N", "NE", "E", "SE", "S", "SW", "W", "NW"
}

local function GetDirectionName(Heading)
	local Index = math.floor((Heading / 45) + 0.5) % 8 + 1
	return DirectionNames[Index]

end

local function UpdateHeading()
	local LookVector = Camera.CFrame.LookVector
	local Heading = math.deg(math.atan2(LookVector.X, -LookVector.Z))

	if Heading < 0 then
		Heading += 360
	end

	Dial.Rotation = -Heading

	for Label, Angle in pairs(CardinalLabels) do

		local Radians = math.rad(Angle)
		local X = math.sin(Radians) * Radius
		local Y = -math.cos(Radians) * Radius

		Label.Position = UDim2.new(0.5, X - 12, 0.5, Y - 12)
		Label.Rotation = Heading

	end

	HeadingLabel.Text = string.format("%03d°", math.floor(Heading + 0.5) % 360)
	DirectionLabel.Text = GetDirectionName(Heading)

end

-----/Open Animation/-----
local OpenSize = UDim2.fromOffset(260, 300)

local function Open()
	Main.Visible = true
	Main.Size = UDim2.fromOffset(0, 0)
	
	TweenService:Create(
		Main,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = OpenSize }
	):Play()
	
	if HeadingConnection then
		HeadingConnection:Disconnect()
	end
	
	UpdateHeading()
	HeadingConnection = RunService.RenderStepped:Connect(UpdateHeading)
end

-----/Close Animation/-----
local function CloseGui()
	if not Main.Visible then
		return
	end
	
	local Tween = TweenService:Create(
		Main,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(0, 0) }
	)
	
	Tween:Play()
	
	Tween.Completed:Once(function()
		Main.Visible = false
		Main.Size = OpenSize
	end)
	
	if HeadingConnection then
		HeadingConnection:Disconnect()
		HeadingConnection = nil
	end
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
