-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-----/Variables/-----
local Player = Players.LocalPlayer

local Commands = {
	{
		Name = "speed",
		Aliases = {"ws", "walkspeed"},
		Description = "Changes your walk speed",

		Execute = function(Args)
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

			if Humanoid then
				Humanoid.WalkSpeed = tonumber(Args[1]) or 16
			end
		end
	},

	{
		Name = "jump",
		Aliases = {"jp", "jumppower"},
		Description = "Changes your jump power",

		Execute = function(Args)
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

			if Humanoid then
				Humanoid.JumpPower = tonumber(Args[1]) or 50
			end
		end
	},

	{
		Name = "sit",
		Aliases = {},
		Description = "Makes your character sit",

		Execute = function()
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

			if Humanoid then
				Humanoid.Sit = true
			end
		end
	},

	{
		Name = "respawn",
		Aliases = {"re"},
		Description = "Respawns your character",

		Execute = function()
			local Character = Player.Character

			if Character then
				Character:BreakJoints()
			end
		end
	},

	{
		Name = "fly",
		Aliases = {},
		Description = "Fly",

		Execute = function()
			warn("[Admin] Fly command")
		end
	},

	{
		Name = "noclip",
		Aliases = {"nc"},
		Description = "Noclip",

		Execute = function()
			warn("[Admin] Noclip command")
		end
	},
}

-----/Functions/-----
local function FindCommand(Name)
	Name = string.lower(Name)

	for _, Command in ipairs(Commands) do
		if Command.Name == Name then
			return Command
		end

		for _, Alias in ipairs(Command.Aliases) do
			if Alias == Name then
				return Command
			end
		end
	end
end

local function ExecuteCommand(Text)
	local Arguments = string.split(Text, " ")

	local Name = Arguments[1]

	if string.sub(Name, 1, 1) == ";" then
		Name = string.sub(Name, 2)
	end

	table.remove(Arguments, 1)

	local Command = FindCommand(Name)

	if Command then
		Command.Execute(Arguments)
	end
end

-----/UI-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IYStyle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(420, 330)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.8
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

-----/Sounds/-----
local function CreateSound(Id, Volume, Parent)
	local Sound = Instance.new("Sound")
	Sound.SoundId = "rbxassetid://" .. Id
	Sound.Volume = Volume
	Sound.Parent = Parent
	return Sound
end

local HoverSound = CreateSound(88442833509532, 0.2, Main)
local ClickSound = CreateSound(88442833509532, 0.3, Main)
local ToggleSound = CreateSound(88442833509532, 0.25, Main)

-----/TitleBar/-----
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel = 0
TitleBar.Active = true
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Pulse Admin"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-----/Drag/-----
local Dragging = false
local DragStart
local StartPosition
local TargetPosition = Main.Position

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
	if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Delta = Input.Position - DragStart

		TargetPosition = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end)

RunService.RenderStepped:Connect(function()
	if Dragging then
		Main.Position = Main.Position:Lerp(TargetPosition, 0.25)
	end
end)

-----/CommandBar/-----
local CommandBar = Instance.new("TextBox")
CommandBar.Name = "CommandBar"
CommandBar.Size = UDim2.new(1, -30, 0, 42)
CommandBar.Position = UDim2.fromOffset(15, 50)
CommandBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
CommandBar.TextColor3 = Color3.fromRGB(255, 255, 255)
CommandBar.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
CommandBar.PlaceholderText = ";command arguments..."
CommandBar.Text = ""
CommandBar.Font = Enum.Font.Code
CommandBar.TextSize = 16
CommandBar.TextXAlignment = Enum.TextXAlignment.Left
CommandBar.ClearTextOnFocus = false
CommandBar.BorderSizePixel = 0
CommandBar.Parent = Main

local CommandCorner = Instance.new("UICorner")
CommandCorner.CornerRadius = UDim.new(0, 10)
CommandCorner.Parent = CommandBar

local CommandStroke = Instance.new("UIStroke")
CommandStroke.Color = Color3.fromRGB(255, 255, 255)
CommandStroke.Transparency = 0.8
CommandStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CommandStroke.Parent = CommandBar

local CommandPadding = Instance.new("UIPadding")
CommandPadding.PaddingLeft = UDim.new(0, 10)
CommandPadding.Parent = CommandBar

-----/Search/-----
local Search = Instance.new("TextBox")
Search.Name = "Search"
Search.Size = UDim2.new(1, -30, 0, 38)
Search.Position = UDim2.fromOffset(15, 102)
Search.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Search.TextColor3 = Color3.fromRGB(255, 255, 255)
Search.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
Search.PlaceholderText = "Search commands..."
Search.Text = ""
Search.Font = Enum.Font.Code
Search.TextSize = 15
Search.TextXAlignment = Enum.TextXAlignment.Left
Search.BorderSizePixel = 0
Search.Parent = Main

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = Search

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(255, 255, 255)
SearchStroke.Transparency = 0.8
SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SearchStroke.Parent = Search

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 10)
SearchPadding.Parent = Search

-----/CommandList/-----
local List = Instance.new("ScrollingFrame")
List.Name = "CommandList"
List.Size = UDim2.new(1, -30, 0, 165)
List.Position = UDim2.fromOffset(15, 150)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageTransparency = 0.5
List.ScrollingDirection = Enum.ScrollingDirection.Y
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.CanvasSize = UDim2.new()
List.Parent = Main

local ListStroke = Instance.new("UIStroke")
ListStroke.Color = Color3.fromRGB(255, 255, 255)
ListStroke.Transparency = 0.8
ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ListStroke.Parent = List

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingRight = UDim.new(0, 3)
ListPadding.PaddingLeft = UDim.new(0, 3)
ListPadding.PaddingTop = UDim.new(0, 1)
ListPadding.PaddingBottom = UDim.new(0, 1)
ListPadding.Parent = List

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
Layout.Parent = List

-----/CommandList/-----
local function CreateCommandButton(Command)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -10, 0, 45)
	Button.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.BorderSizePixel = 0
	Button.Parent = List

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(255, 255, 255)
	Stroke.Transparency = 0.8
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Button

	local Name = Instance.new("TextLabel")
	Name.Size = UDim2.new(0, 115, 1, 0)
	Name.Position = UDim2.fromOffset(10, 0)
	Name.BackgroundTransparency = 1
	Name.Text = ";" .. Command.Name
	Name.TextColor3 = Color3.fromRGB(255, 255, 255)
	Name.Font = Enum.Font.Code
	Name.TextSize = 16
	Name.TextXAlignment = Enum.TextXAlignment.Left
	Name.Parent = Button

	local Description = Instance.new("TextLabel")
	Description.Size = UDim2.new(1, -135, 1, 0)
	Description.Position = UDim2.fromOffset(125, 0)
	Description.BackgroundTransparency = 1
	Description.Text = Command.Description
	Description.TextColor3 = Color3.fromRGB(130, 130, 130)
	Description.Font = Enum.Font.Code
	Description.TextSize = 13
	Description.TextXAlignment = Enum.TextXAlignment.Left
	Description.TextTruncate = Enum.TextTruncate.AtEnd
	Description.Parent = Button

	Button.MouseEnter:Connect(function()
		HoverSound:Play()

		TweenService:Create(
			Button,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			}
		):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(
			Button,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			}
		):Play()
	end)

	Button.MouseButton1Click:Connect(function()
		ClickSound:Play()

		CommandBar.Text = ";" .. Command.Name
		CommandBar:CaptureFocus()
		CommandBar.CursorPosition = #CommandBar.Text + 1
	end)
end

-----/RefreshCommands/-----
local function RefreshCommands(Filter)
	Filter = string.lower(Filter or "")

	for _, Child in ipairs(List:GetChildren()) do
		if Child:IsA("TextButton") then
			Child:Destroy()
		end
	end

	for _, Command in ipairs(Commands) do
		local Match =
			Filter == ""
			or string.find(string.lower(Command.Name), Filter, 1, true)
			or string.find(string.lower(Command.Description), Filter, 1, true)

		if Match then
			CreateCommandButton(Command)
		end
	end
end

-----/Events/-----
Search:GetPropertyChangedSignal("Text"):Connect(function()
	RefreshCommands(Search.Text)
end)

CommandBar.FocusLost:Connect(function(EnterPressed)
	if EnterPressed then
		ExecuteCommand(CommandBar.Text)
		CommandBar.Text = ""
	end
end)

-----/Toggle/-----
local Open = true
local NormalSize = UDim2.fromOffset(420, 330)
local ClosedSize = UDim2.fromOffset(420, 0)

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.RightShift then
		Open = not Open

		ToggleSound:Play()

		TweenService:Create(
			Main,
			TweenInfo.new(
				0.25,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			),
			{
				Size = Open and NormalSize or ClosedSize
			}
		):Play()
	end
end)

-----/Init/-----
RefreshCommands()
