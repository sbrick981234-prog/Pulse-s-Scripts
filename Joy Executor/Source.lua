-----/Services/-----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-----/Configuration/-----
local CONFIG = {
	WindowSize = Vector2.new(800, 600),
	
	Colors = {
		Primary = Color3.fromRGB(60, 120, 160),
		Secondary = Color3.fromRGB(45, 90, 125),
		Accent = Color3.fromRGB(100, 150, 200),
		
		Window = Color3.fromRGB(240, 242, 245),
		TitleBar = Color3.fromRGB(50, 90, 140),
		MenuBar = Color3.fromRGB(235, 237, 240),
		Toolbar = Color3.fromRGB(230, 233, 237),
		StatusBar = Color3.fromRGB(220, 225, 232),
		
		Editor = Color3.fromRGB(255, 255, 255),
		LineNumbers = Color3.fromRGB(245, 247, 250),
		EditorBorder = Color3.fromRGB(200, 210, 220),
		
		Text = Color3.fromRGB(30, 40, 50),
		TextLight = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(80, 100, 120),
		TextTertiary = Color3.fromRGB(120, 140, 160),
		
		Border = Color3.fromRGB(180, 195, 210),
		ButtonBorder = Color3.fromRGB(160, 180, 200),
		Hover = Color3.fromRGB(220, 230, 240),
		Active = Color3.fromRGB(100, 150, 200),
	},

	Sounds = {
		Hover = "",
		Click = "",
		Open = "",
		Close = "",
		Error = "",
	}
}

-----/Utility Functions/-----
local function CreateSound(Id, Volume)
	if Id == nil or Id == "" then
		return nil
	end

	local Sound = Instance.new("Sound")
	Sound.SoundId = Id
	Sound.Volume = Volume or 0.35
	Sound.Parent = PlayerGui

	return Sound
end

local function PlaySound(Id, Volume)
	local Sound = CreateSound(Id, Volume)
	if not Sound then return end

	Sound:Play()
	Sound.Ended:Once(function() Sound:Destroy() end)
	task.delay(5, function()
		if Sound.Parent then Sound:Destroy() end
	end)
end

local function CreateButton(Parent, Config)
	local Button = Instance.new("TextButton")
	Button.Name = Config.Name
	Button.Size = Config.Size or UDim2.fromOffset(60, 28)
	Button.Position = Config.Position or UDim2.new(0, 0, 0, 0)
	Button.BackgroundColor3 = Config.BackgroundColor3 or CONFIG.Colors.Toolbar
	Button.BorderSizePixel = Config.BorderSizePixel or 1
	Button.BorderColor3 = Config.BorderColor3 or CONFIG.Colors.ButtonBorder
	Button.Text = Config.Text or ""
	Button.TextColor3 = CONFIG.Colors.Text
	Button.TextSize = Config.TextSize or 11
	Button.Font = Enum.Font.GothamMedium
	Button.AutoButtonColor = Config.AutoButtonColor ~= false
	Button.Parent = Parent

	if Config.OnHover then
		Button.MouseEnter:Connect(function()
			Button.BackgroundColor3 = CONFIG.Colors.Hover
			PlaySound(CONFIG.Sounds.Hover, 0.12)
		end)
		Button.MouseLeave:Connect(function()
			Button.BackgroundColor3 = Config.BackgroundColor3 or CONFIG.Colors.Toolbar
		end)
	end

	if Config.OnClick then
		Button.MouseButton1Click:Connect(function()
			PlaySound(CONFIG.Sounds.Click, 0.25)
			Config.OnClick()
		end)
	end

	return Button
end

local function CreateCorner(Object, Radius)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Radius)
	Corner.Parent = Object
	return Corner
end

-----/Main GUI/-----
local Gui = Instance.new("ScreenGui")
Gui.Name = "JoyExecutor"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("CanvasGroup")
Main.Name = "Window"
Main.Size = UDim2.fromOffset(CONFIG.WindowSize.X, CONFIG.WindowSize.Y)
Main.Position = UDim2.new(0.5, -CONFIG.WindowSize.X / 2, 0.5, -CONFIG.WindowSize.Y / 2)
Main.BackgroundColor3 = CONFIG.Colors.Window
Main.BorderSizePixel = 1
Main.BorderColor3 = CONFIG.Colors.Border
Main.GroupTransparency = 0
Main.Parent = Gui

CreateCorner(Main, 8)

-----/TitleBar/-----
local TitleBar = Instance.new("CanvasGroup")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = CONFIG.Colors.TitleBar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.fromOffset(24, 24)
Icon.Position = UDim2.fromOffset(12, 8)
Icon.BackgroundTransparency = 1
Icon.Image = "4791153196"
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -150, 0, 40)
Title.Position = UDim2.fromOffset(45, 0)
Title.BackgroundTransparency = 1
Title.Text = "Joy Executor"
Title.TextColor3 = CONFIG.Colors.TextLight
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Parent = TitleBar

local WindowButtons = {
	Minimize = CreateButton(TitleBar, {
		Name = "Minimize",
		Text = "−",
		Position = UDim2.new(1, -120, 0, 5),
		Size = UDim2.fromOffset(45, 30),
		BackgroundColor3 = CONFIG.Colors.TitleBar,
		BorderSizePixel = 0,
		TextSize = 18,
		OnHover = true,
	}),
	Maximize = CreateButton(TitleBar, {
		Name = "Maximize",
		Text = "□",
		Position = UDim2.new(1, -75, 0, 5),
		Size = UDim2.fromOffset(45, 30),
		BackgroundColor3 = CONFIG.Colors.TitleBar,
		BorderSizePixel = 0,
		TextSize = 14,
		OnHover = true,
	}),
	Close = CreateButton(TitleBar, {
		Name = "Close",
		Text = "×",
		Position = UDim2.new(1, -30, 0, 5),
		Size = UDim2.fromOffset(45, 30),
		BackgroundColor3 = CONFIG.Colors.TitleBar,
		BorderSizePixel = 0,
		TextSize = 18,
		OnHover = true,
	}),
}

-----/MenuBar/-----
local MenuBar = Instance.new("CanvasGroup")
MenuBar.Name = "MenuBar"
MenuBar.Size = UDim2.new(1, 0, 0, 28)
MenuBar.Position = UDim2.fromOffset(0, 40)
MenuBar.BackgroundColor3 = CONFIG.Colors.MenuBar
MenuBar.BorderSizePixel = 0
MenuBar.Parent = Main

local MenuItems = {
	{Name = "File", Text = "File", X = 8},
	{Name = "Edit", Text = "Edit", X = 60},
	{Name = "View", Text = "View", X = 110},
	{Name = "Tools", Text = "Tools", X = 160},
	{Name = "Help", Text = "Help", X = 220},
}

for _, Item in ipairs(MenuItems) do
	CreateButton(MenuBar, {
		Name = Item.Name,
		Text = Item.Text,
		Position = UDim2.fromOffset(Item.X, 4),
		Size = UDim2.fromOffset(45, 20),
		BackgroundColor3 = CONFIG.Colors.MenuBar,
		BorderSizePixel = 0,
		TextSize = 11,
		OnHover = true,
		OnClick = function() end,
	})
end

-----/ToolBar/-----
local ToolBar = Instance.new("CanvasGroup")
ToolBar.Name = "ToolBar"
ToolBar.Size = UDim2.new(1, 0, 0, 40)
ToolBar.Position = UDim2.fromOffset(0, 68)
ToolBar.BackgroundColor3 = CONFIG.Colors.Toolbar
ToolBar.BorderSizePixel = 1
ToolBar.BorderColor3 = CONFIG.Colors.Border
ToolBar.Parent = Main

local ToolButtons = {
	New = nil,
	Open = nil,
	Save = nil,
	Run = nil,
	Clear = nil,
}

local ToolPositions = {
	{Name = "New", X = 8},
	{Name = "Open", X = 70},
	{Name = "Save", X = 132},
	{Name = "Run", X = 200},
	{Name = "Clear", X = 262},
}

for _, Pos in ipairs(ToolPositions) do
	ToolButtons[Pos.Name] = CreateButton(ToolBar, {
		Name = Pos.Name,
		Text = Pos.Name,
		Position = UDim2.fromOffset(Pos.X, 6),
		Size = UDim2.fromOffset(55, 28),
		BackgroundColor3 = CONFIG.Colors.Active,
		BorderSizePixel = 1,
		TextSize = 10,
		TextColor = CONFIG.Colors.TextLight,
		OnHover = true,
		OnClick = function() end,
	})
end

-----/Editor/-----
local EditorFrame = Instance.new("CanvasGroup")
EditorFrame.Name = "Editor"
EditorFrame.Size = UDim2.new(1, -16, 1, -130)
EditorFrame.Position = UDim2.fromOffset(8, 112)
EditorFrame.BackgroundColor3 = CONFIG.Colors.Editor
EditorFrame.BorderSizePixel = 1
EditorFrame.BorderColor3 = CONFIG.Colors.EditorBorder
EditorFrame.ClipsDescendants = true
EditorFrame.Parent = Main

CreateCorner(EditorFrame, 4)

local LineNumbers = Instance.new("TextLabel")
LineNumbers.Name = "LineNumbers"
LineNumbers.Size = UDim2.new(0, 40, 1, 0)
LineNumbers.Position = UDim2.fromOffset(0, 0)
LineNumbers.BackgroundColor3 = CONFIG.Colors.LineNumbers
LineNumbers.BorderSizePixel = 0
LineNumbers.Text = "1"
LineNumbers.TextColor3 = CONFIG.Colors.TextTertiary
LineNumbers.TextSize = 11
LineNumbers.Font = Enum.Font.Code
LineNumbers.TextXAlignment = Enum.TextXAlignment.Center
LineNumbers.TextYAlignment = Enum.TextYAlignment.Top
LineNumbers.Parent = EditorFrame

local Code = Instance.new("TextBox")
Code.Name = "Code"
Code.Size = UDim2.new(1, -48, 1, 0)
Code.Position = UDim2.fromOffset(40, 0)
Code.BackgroundTransparency = 1
Code.BorderSizePixel = 0
Code.ClearTextOnFocus = false
Code.MultiLine = true
Code.TextWrapped = false
Code.TextScaled = false
Code.Text = "-- Joy Executor\n-- Write your Lua code here\n\nprint(\"Hello, World!\")"
Code.TextColor3 = CONFIG.Colors.Text
Code.TextSize = 12
Code.Font = Enum.Font.Code
Code.TextXAlignment = Enum.TextXAlignment.Left
Code.TextYAlignment = Enum.TextYAlignment.Top
Code.Parent = EditorFrame

-----/StatusBar/-----
local StatusBar = Instance.new("CanvasGroup")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, 0, 0, 30)
StatusBar.Position = UDim2.new(0, 0, 1, -30)
StatusBar.BackgroundColor3 = CONFIG.Colors.StatusBar
StatusBar.BorderSizePixel = 1
StatusBar.BorderColor3 = CONFIG.Colors.Border
StatusBar.Parent = Main

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.fromOffset(300, 30)
Status.Position = UDim2.fromOffset(8, 0)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = CONFIG.Colors.TextSecondary
Status.TextSize = 10
Status.Font = Enum.Font.GothamMedium
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Center
Status.Parent = StatusBar

local Position = Instance.new("TextLabel")
Position.Name = "Position"
Position.Size = UDim2.fromOffset(150, 30)
Position.Position = UDim2.new(1, -158, 0, 0)
Position.BackgroundTransparency = 1
Position.Text = "Ln 1, Col 1"
Position.TextColor3 = CONFIG.Colors.TextSecondary
Position.TextSize = 10
Position.Font = Enum.Font.GothamMedium
Position.TextXAlignment = Enum.TextXAlignment.Right
Position.TextYAlignment = Enum.TextYAlignment.Center
Position.Parent = StatusBar

-----/Core Functions/-----
local function UpdateLines()
	local Text = Code.Text or ""
	Text = Text:gsub("\r\n", "\n")
	Text = Text:gsub("\r", "\n")

	local LineCount = 1
	for _ in Text:gmatch("\n") do
		LineCount += 1
	end

	local Lines = table.create(LineCount)
	for Index = 1, LineCount do
		Lines[Index] = tostring(Index)
	end

	LineNumbers.Text = table.concat(Lines, "\n")
end

local function UpdateCursorPosition()
	local CursorPosition = Code.CursorPosition
	if CursorPosition <= 0 then
		Position.Text = "Ln 1, Col 1"
		return
	end

	local TextBefore = Code.Text:sub(1, CursorPosition - 1)
	local Line = 1
	local LastNewLine = 0

	for Index = 1, #TextBefore do
		if TextBefore:sub(Index, Index) == "\n" then
			Line += 1
			LastNewLine = Index
		end
	end

	local Column = #TextBefore - LastNewLine + 1
	Position.Text = string.format("Ln %d, Col %d", Line, Column)
end

-----/Editor Events/-----
Code:GetPropertyChangedSignal("Text"):Connect(UpdateLines)
Code:GetPropertyChangedSignal("CursorPosition"):Connect(UpdateCursorPosition)
Code.Focused:Connect(UpdateCursorPosition)
Code.FocusLost:Connect(UpdateCursorPosition)

UpdateLines()
UpdateCursorPosition()

-----/Button Events/-----
ToolButtons.Clear.MouseButton1Click:Connect(function()
	Code.Text = ""
	Status.Text = "Editor cleared"
	UpdateLines()
	UpdateCursorPosition()
end)

ToolButtons.New.MouseButton1Click:Connect(function()
	Code.Text = ""
	Status.Text = "New document"
	UpdateLines()
	UpdateCursorPosition()
end)

ToolButtons.Open.MouseButton1Click:Connect(function()
	Status.Text = "Open is unavailable"
	PlaySound(CONFIG.Sounds.Error, 0.35)
end)

ToolButtons.Save.MouseButton1Click:Connect(function()
	Status.Text = "Saved"
end)

ToolButtons.Run.MouseButton1Click:Connect(function()
	local Success, Error = pcall(function()
		loadstring(Code.Text)()
	end)

	if Success then
		Status.Text = "Code executed successfully"
	else
		Status.Text = "Error: " .. (Error or "Unknown error")
		PlaySound(CONFIG.Sounds.Error, 0.35)
	end

	PlaySound(CONFIG.Sounds.Click, 0.25)
end)

-----/Window Controls/-----
local Minimized = false
local OldSize = Main.Size

WindowButtons.Minimize.MouseButton1Click:Connect(function()
	Minimized = not Minimized

	if Minimized then
		OldSize = Main.Size
		Main.Size = UDim2.fromOffset(CONFIG.WindowSize.X, 40)

		for _, Object in ipairs(Main:GetChildren()) do
			if Object ~= TitleBar then
				Object.Visible = false
			end
		end

		Status.Text = "Minimized"
	else
		Main.Size = OldSize

		for _, Object in ipairs(Main:GetChildren()) do
			Object.Visible = true
		end

		Status.Text = "Ready"
	end
end)

local Maximized = false
local OldPosition = Main.Position

WindowButtons.Maximize.MouseButton1Click:Connect(function()
	if Maximized then
		Main.Size = UDim2.fromOffset(CONFIG.WindowSize.X, CONFIG.WindowSize.Y)
		Main.Position = OldPosition
		Maximized = false
		Status.Text = "Window restored"
	else
		OldPosition = Main.Position
		Main.Position = UDim2.fromOffset(0, 0)
		Main.Size = UDim2.fromScale(1, 1)
		Maximized = true
		Status.Text = "Maximized"
	end
end)

WindowButtons.Close.MouseButton1Click:Connect(function()
	PlaySound(CONFIG.Sounds.Close, 0.35)
	task.wait(0.05)
	Gui:Destroy()
end)

-----/Window Drag/-----
local Dragging = false
local DragStart
local StartPosition

TitleBar.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position
	end
end)

TitleBar.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging or Input.UserInputType ~= Enum.UserInputType.MouseMovement or Maximized then
		return
	end

	local Delta = Input.Position - DragStart
	Main.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end)

-----/Initialization/-----

Main.GroupTransparency = 1
PlaySound(CONFIG.Sounds.Open, 0.3)

for Index = 1, 10 do
	Main.GroupTransparency = 1 - (Index / 10)
	task.wait(0.015)
end

Main.GroupTransparency = 0
