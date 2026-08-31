-----/Services/-----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-----/Configuration/-----

local CONFIG = {
	WindowSize = Vector2.new(620, 390),

	Colors = {
		Window = Color3.fromRGB(236, 236, 236),
		TitleBar = Color3.fromRGB(225, 225, 225),
		Menu = Color3.fromRGB(238, 238, 238),
		Toolbar = Color3.fromRGB(230, 230, 230),

		Editor = Color3.fromRGB(255, 255, 255),
		LineNumbers = Color3.fromRGB(242, 242, 242),

		StatusBar = Color3.fromRGB(225, 225, 225),

		Text = Color3.fromRGB(30, 30, 30),
		SecondaryText = Color3.fromRGB(75, 75, 75),
		LineText = Color3.fromRGB(120, 120, 120),

		Border = Color3.fromRGB(150, 150, 150),
		ButtonBorder = Color3.fromRGB(185, 185, 185),
	},

	Sounds = {
		Hover = "",
		Click = "",
		Open = "",
		Close = "",
		Error = "",
	}
}

-----/Functions/-----

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

	if not Sound then
		return
	end

	Sound:Play()

	Sound.Ended:Once(function()
		Sound:Destroy()
	end)

	task.delay(5, function()
		if Sound.Parent then
			Sound:Destroy()
		end
	end)
end

local function CreateCorner(Object, Radius)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Radius)
	Corner.Parent = Object

	return Corner
end

local function CreateBorder(Object, Color)
	Object.BorderSizePixel = 1
	Object.BorderColor3 = Color

	return Object
end

-----/Main/-----

local Gui = Instance.new("ScreenGui")
Gui.Name = "LarpProgram"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("CanvasGroup")
Main.Name = "Window"
Main.Size = UDim2.fromOffset(
	CONFIG.WindowSize.X,
	CONFIG.WindowSize.Y
)

Main.Position = UDim2.new(
	0.5,
	-CONFIG.WindowSize.X / 2,
	0.5,
	-CONFIG.WindowSize.Y / 2
)

Main.BackgroundColor3 = CONFIG.Colors.Window
Main.BorderSizePixel = 1
Main.BorderColor3 = CONFIG.Colors.Border
Main.GroupTransparency = 0
Main.Parent = Gui

-----/TitleBar/-----

local TitleBar = Instance.new("CanvasGroup")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = CONFIG.Colors.TitleBar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

-- Logo

local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.fromOffset(18, 18)
Icon.Position = UDim2.fromOffset(7, 6)
Icon.BackgroundTransparency = 1
Icon.Image = "4791153196"
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = TitleBar

-- Title

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -160, 0, 30)
Title.Position = UDim2.fromOffset(31, 0)
Title.BackgroundTransparency = 1
Title.Text = "Joy Executor"
Title.TextColor3 = CONFIG.Colors.Text
Title.TextSize = 13
Title.Font = Enum.Font.Arial
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Parent = TitleBar

-----/WindowButtons/-----

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(45, 30)
Minimize.Position = UDim2.new(1, -135, 0, 0)
Minimize.BackgroundTransparency = 1
Minimize.BorderSizePixel = 0
Minimize.Text = "−"
Minimize.TextColor3 = CONFIG.Colors.Text
Minimize.TextSize = 17
Minimize.Font = Enum.Font.Arial
Minimize.Parent = TitleBar

local Maximize = Instance.new("TextButton")
Maximize.Name = "Maximize"
Maximize.Size = UDim2.fromOffset(45, 30)
Maximize.Position = UDim2.new(1, -90, 0, 0)
Maximize.BackgroundTransparency = 1
Maximize.BorderSizePixel = 0
Maximize.Text = "□"
Maximize.TextColor3 = CONFIG.Colors.Text
Maximize.TextSize = 13
Maximize.Font = Enum.Font.Arial
Maximize.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.fromOffset(45, 30)
Close.Position = UDim2.new(1, -45, 0, 0)
Close.BackgroundTransparency = 1
Close.BorderSizePixel = 0
Close.Text = "×"
Close.TextColor3 = CONFIG.Colors.Text
Close.TextSize = 17
Close.Font = Enum.Font.Arial
Close.Parent = TitleBar

-----/MenuBar/-----

local MenuBar = Instance.new("CanvasGroup")
MenuBar.Name = "MenuBar"
MenuBar.Size = UDim2.new(1, 0, 0, 25)
MenuBar.Position = UDim2.fromOffset(0, 30)
MenuBar.BackgroundColor3 = CONFIG.Colors.Menu
MenuBar.BorderSizePixel = 0
MenuBar.Parent = Main

local function CreateMenuButton(Name, Text, X, Width)
	local Button = Instance.new("TextButton")

	Button.Name = Name
	Button.Size = UDim2.fromOffset(Width, 25)
	Button.Position = UDim2.fromOffset(X, 0)

	Button.BackgroundTransparency = 1
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false

	Button.Text = Text
	Button.TextColor3 = CONFIG.Colors.Text
	Button.TextSize = 11
	Button.Font = Enum.Font.Arial

	Button.Parent = MenuBar

	Button.MouseEnter:Connect(function()
		PlaySound(CONFIG.Sounds.Hover, 0.12)
	end)

	Button.MouseButton1Click:Connect(function()
		PlaySound(CONFIG.Sounds.Click, 0.25)
	end)

	return Button
end

CreateMenuButton("File", "File", 3, 42)
CreateMenuButton("Edit", "Edit", 45, 42)
CreateMenuButton("View", "View", 87, 48)
CreateMenuButton("Tools", "Tools", 135, 52)
CreateMenuButton("Help", "Help", 187, 48)

-----/ToolBar/-----

local ToolBar = Instance.new("CanvasGroup")
ToolBar.Name = "ToolBar"
ToolBar.Size = UDim2.new(1, 0, 0, 34)
ToolBar.Position = UDim2.fromOffset(0, 55)
ToolBar.BackgroundColor3 = CONFIG.Colors.Toolbar
ToolBar.BorderSizePixel = 0
ToolBar.Parent = Main

local function CreateToolButton(Name, Text, X, Width)
	local Button = Instance.new("TextButton")

	Button.Name = Name
	Button.Size = UDim2.fromOffset(Width, 28)
	Button.Position = UDim2.fromOffset(X, 3)

	Button.BackgroundColor3 = CONFIG.Colors.Toolbar
	Button.BorderSizePixel = 1
	Button.BorderColor3 = CONFIG.Colors.ButtonBorder

	Button.Text = Text
	Button.TextColor3 = CONFIG.Colors.Text
	Button.TextSize = 10
	Button.Font = Enum.Font.Arial

	Button.AutoButtonColor = true
	Button.Parent = ToolBar

	Button.MouseEnter:Connect(function()
		PlaySound(CONFIG.Sounds.Hover, 0.12)
	end)

	Button.MouseButton1Click:Connect(function()
		PlaySound(CONFIG.Sounds.Click, 0.25)
	end)

	return Button
end

local New = CreateToolButton("New", "New", 5, 55)
local Open = CreateToolButton("Open", "Open", 63, 55)
local Save = CreateToolButton("Save", "Save", 121, 55)

local Separator = Instance.new("CanvasGroup")
Separator.Name = "Separator"
Separator.Size = UDim2.fromOffset(1, 24)
Separator.Position = UDim2.fromOffset(182, 5)
Separator.BackgroundColor3 = CONFIG.Colors.ButtonBorder
Separator.BorderSizePixel = 0
Separator.Parent = ToolBar

local Run = CreateToolButton("Run", "Run", 190, 55)
local Clear = CreateToolButton("Clear", "Clear", 248, 55)

-----/Editor/-----

local EditorFrame = Instance.new("CanvasGroup")
EditorFrame.Name = "Editor"
EditorFrame.Size = UDim2.new(1, -12, 1, -130)
EditorFrame.Position = UDim2.fromOffset(6, 94)
EditorFrame.BackgroundColor3 = CONFIG.Colors.Editor
EditorFrame.BorderSizePixel = 1
EditorFrame.BorderColor3 = CONFIG.Colors.Border
EditorFrame.ClipsDescendants = true
EditorFrame.Parent = Main

-----/LineNumbers/-----

local LineNumbers = Instance.new("TextLabel")
LineNumbers.Name = "LineNumbers"
LineNumbers.Size = UDim2.new(0, 35, 1, 0)
LineNumbers.Position = UDim2.fromOffset(0, 5)

LineNumbers.BackgroundColor3 = CONFIG.Colors.LineNumbers
LineNumbers.BorderSizePixel = 0

LineNumbers.Text = "1"
LineNumbers.TextColor3 = CONFIG.Colors.LineText
LineNumbers.TextSize = 11
LineNumbers.Font = Enum.Font.Code

LineNumbers.TextXAlignment = Enum.TextXAlignment.Center
LineNumbers.TextYAlignment = Enum.TextYAlignment.Top

LineNumbers.Parent = EditorFrame

-----/Code/-----

local Code = Instance.new("TextBox")
Code.Name = "Code"

Code.Size = UDim2.new(1, -43, 1, -10)
Code.Position = UDim2.fromOffset(40, 5)

Code.BackgroundTransparency = 1
Code.BorderSizePixel = 0

Code.ClearTextOnFocus = false
Code.MultiLine = true
Code.TextWrapped = false
Code.TextScaled = false

Code.Text = "-- Larp Script\n\nprint(\"Hello, world!\")"

Code.TextColor3 = CONFIG.Colors.Text
Code.TextSize = 12
Code.Font = Enum.Font.Code

Code.TextXAlignment = Enum.TextXAlignment.Left
Code.TextYAlignment = Enum.TextYAlignment.Top

Code.Parent = EditorFrame

-----/LinesOfCode/-----

local function UpdateLines()
	local Text = Code.Text or ""

	-- Нормализуем переносы строк
	Text = Text:gsub("\r\n", "\n")
	Text = Text:gsub("\r", "\n")

	-- Пустой редактор всё равно имеет первую строку
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

Code:GetPropertyChangedSignal("Text"):Connect(UpdateLines)

UpdateLines()

-----/StatusBar/-----

local StatusBar = Instance.new("CanvasGroup")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, 0, 0, 25)
StatusBar.Position = UDim2.new(0, 0, 1, -25)

StatusBar.BackgroundColor3 = CONFIG.Colors.StatusBar
StatusBar.BorderSizePixel = 1
StatusBar.BorderColor3 = CONFIG.Colors.ButtonBorder

StatusBar.Parent = Main

local Status = Instance.new("TextLabel")
Status.Name = "Status"

Status.Size = UDim2.fromOffset(250, 25)
Status.Position = UDim2.fromOffset(7, 0)

Status.BackgroundTransparency = 1

Status.Text = "Ready"
Status.TextColor3 = CONFIG.Colors.SecondaryText
Status.TextSize = 10
Status.Font = Enum.Font.Arial

Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Center

Status.Parent = StatusBar

local Position = Instance.new("TextLabel")
Position.Name = "Position"

Position.Size = UDim2.fromOffset(150, 25)
Position.Position = UDim2.new(1, -160, 0, 0)

Position.BackgroundTransparency = 1

Position.Text = "Ln 1, Col 1"
Position.TextColor3 = CONFIG.Colors.SecondaryText
Position.TextSize = 10
Position.Font = Enum.Font.Arial

Position.TextXAlignment = Enum.TextXAlignment.Right
Position.TextYAlignment = Enum.TextYAlignment.Center

Position.Parent = StatusBar

-----/CursorPosition/-----

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

	Position.Text = string.format(
		"Ln %d, Col %d",
		Line,
		Column
	)
end

Code:GetPropertyChangedSignal("CursorPosition"):Connect(
	UpdateCursorPosition
)

Code.Focused:Connect(UpdateCursorPosition)

Code.FocusLost:Connect(function()
	UpdateCursorPosition()
end)

-----/Functions/-----

Clear.MouseButton1Click:Connect(function()
	Code.Text = ""
	Status.Text = "Editor cleared"

	UpdateLines()
	UpdateCursorPosition()
end)

New.MouseButton1Click:Connect(function()
	Code.Text = ""
	Status.Text = "New document"

	UpdateLines()
	UpdateCursorPosition()
end)

Open.MouseButton1Click:Connect(function()
	Status.Text = "Open is unavailable"
	PlaySound(CONFIG.Sounds.Error, 0.35)
end)

Save.MouseButton1Click:Connect(function()
	Status.Text = "Saved"
end)

Run.MouseButton1Click:Connect(function()
	loadstring(Code.Text)()
	
	Status.Text = "Executed"
	
	PlaySound(CONFIG.Sounds.Click, 0.25)
end)

-----/WindowButtons/-----

Close.MouseEnter:Connect(function()
	PlaySound(CONFIG.Sounds.Hover, 0.12)
end)

Minimize.MouseEnter:Connect(function()
	PlaySound(CONFIG.Sounds.Hover, 0.12)
end)

Maximize.MouseEnter:Connect(function()
	PlaySound(CONFIG.Sounds.Hover, 0.12)
end)

Close.MouseButton1Click:Connect(function()
	PlaySound(CONFIG.Sounds.Close, 0.35)

	task.wait(0.05)

	Gui:Destroy()
end)

-----/Minimize/-----

local Minimized = false
local OldSize = Main.Size

Minimize.MouseButton1Click:Connect(function()
	PlaySound(CONFIG.Sounds.Click, 0.25)

	Minimized = not Minimized

	if Minimized then
		OldSize = Main.Size

		Main.Size = UDim2.fromOffset(
			CONFIG.WindowSize.X,
			30
		)

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

-----/Maximize/-----

local Maximized = false
local OldPosition = Main.Position

Maximize.MouseButton1Click:Connect(function()
	PlaySound(CONFIG.Sounds.Click, 0.25)

	if Maximized then
		Main.Size = UDim2.fromOffset(
			CONFIG.WindowSize.X,
			CONFIG.WindowSize.Y
		)

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

-----/OpenAnimation/-----

Main.GroupTransparency = 1

PlaySound(CONFIG.Sounds.Open, 0.3)

for Index = 1, 10 do
	Main.GroupTransparency = 1 - (Index / 10)
	task.wait(0.015)
end

Main.GroupTransparency = 0

-----/Drag/-----

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
	if not Dragging then
		return
	end

	if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	if Maximized then
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

-----/InitialUpdate/-----

UpdateLines()
UpdateCursorPosition()
