-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-----/Variables/-----
local Player = Players.LocalPlayer

-----/Main/-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScannerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(240, 140)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.8
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

local MainShadow = Instance.new("UIShadow")

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Position = UDim2.fromOffset(0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Pulse Scanner"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 20
Title.Parent = Main

local Scan = Instance.new("TextButton")
Scan.Name = "Scan"
Scan.Size = UDim2.fromOffset(190, 55)
Scan.Position = UDim2.fromScale(0.5, 0.62)
Scan.AnchorPoint = Vector2.new(0.5, 0.5)
Scan.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Scan.Text = "Scan"
Scan.TextColor3 = Color3.fromRGB(255, 255, 255)
Scan.Font = Enum.Font.Code
Scan.TextSize = 22
Scan.BorderSizePixel = 0
Scan.AutoButtonColor = false
Scan.Parent = Main

local ScanCorner = Instance.new("UICorner")
ScanCorner.CornerRadius = UDim.new(0, 10)
ScanCorner.Parent = Scan

local ScanStroke = Instance.new("UIStroke")
ScanStroke.Color = Color3.fromRGB(255, 255, 255)
ScanStroke.Transparency = 0.8
ScanStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ScanStroke.Parent = Scan

-----/Animations/-----
local NormalSize = UDim2.fromOffset(190, 55)
local HoverSize = UDim2.fromOffset(195, 58)
local PressSize = UDim2.fromOffset(184, 52)

local TweenInfo = TweenInfo.new(
	0.025,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

Scan.MouseEnter:Connect(function()
	TweenService:Create(Scan, TweenInfo, {
		Size = HoverSize,
		BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	}):Play()
end)

Scan.MouseLeave:Connect(function()
	TweenService:Create(Scan, TweenInfo, {
		Size = NormalSize,
		BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	}):Play()
end)

Scan.MouseButton1Down:Connect(function()
	TweenService:Create(Scan, TweenInfo, {
		Size = PressSize
	}):Play()
end)

Scan.MouseButton1Up:Connect(function()
	TweenService:Create(Scan, TweenInfo, {
		Size = HoverSize
	}):Play()
end)
