-----/Services/-----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CurrentInput = ""
local LastExpression = ""
local LastWasEquals = false

local ExpressionLabel
local ResultBox
local Holder
local TitleBar

local IsDragging = false
local DragStart
local DragOrigin

-----/Values/-----
local Colors = {
	Dark = Color3.fromRGB(36, 36, 37),
	Background = Color3.fromRGB(46, 46, 47),
	Button = Color3.fromRGB(78, 78, 79),
	ButtonHover = Color3.fromRGB(92, 92, 93),
	ButtonAccent = Color3.fromRGB(64, 64, 65),
	White = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(180, 180, 180),
}

local ButtonLayout = {
	{ "C", "DEL", "%", "÷" },
	{ "7", "8", "9", "×" },
	{ "4", "5", "6", "-" },
	{ "1", "2", "3", "+" },
	{ "0", ".", "±", "=" },
}

local OperatorSet = {
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["/"] = true,
}

local InputMap = {
	["÷"] = "/",
	["×"] = "*",
}

-----/Functions/-----
local function ToDisplay(Text : string) : string
	local Result = Text
	Result = Result:gsub("%*", "×")
	Result = Result:gsub("/", "÷")
	return Result
end

local function ToInput(Label : string) : string
	return InputMap[Label] or Label
end

local function IsOperator(Char : string) : boolean
	return OperatorSet[Char] == true
end

local function FormatNumber(Value : number) : string
	if Value ~= Value or Value == math.huge or Value == -math.huge then
		return "Error"
	end
	if Value == math.floor(Value) and math.abs(Value) < 1e15 then
		return string.format("%d", Value)
	end
	local Text = string.format("%.10f", Value)
	Text = Text:gsub("0+$", "")
	Text = Text:gsub("%.$", "")
	return Text
end

local function Evaluate(Source : string) : number?
	local Position = 1
	local Length = #Source
	local ParseExpression
	local ParseTerm
	local ParseFactor

	local function SkipSpaces()
		while Position <= Length and Source:sub(Position, Position) == " " do
			Position = Position + 1
		end
	end

	ParseFactor = function() : number?
		SkipSpaces()
		if Position > Length then
			return nil
		end
		local Char = Source:sub(Position, Position)
		if Char == "-" then
			Position = Position + 1
			local Value = ParseFactor()
			if Value == nil then
				return nil
			end
			return -Value
		end
		local Start = Position
		while Position <= Length do
			local Current = Source:sub(Position, Position)
			if Current:match("[%d%.]") then
				Position = Position + 1
			else
				break
			end
		end
		if Start == Position then
			return nil
		end
		return tonumber(Source:sub(Start, Position - 1))
	end

	ParseTerm = function() : number?
		local Value = ParseFactor()
		if Value == nil then
			return nil
		end
		while true do
			SkipSpaces()
			local Char = Source:sub(Position, Position)
			if Char == "*" then
				Position = Position + 1
				local Right = ParseFactor()
				if Right == nil then
					return nil
				end
				Value = Value * Right
			elseif Char == "/" then
				Position = Position + 1
				local Right = ParseFactor()
				if Right == nil then
					return nil
				end
				Value = Value / Right
			else
				break
			end
		end
		return Value
	end

	ParseExpression = function() : number?
		local Value = ParseTerm()
		if Value == nil then
			return nil
		end
		while true do
			SkipSpaces()
			local Char = Source:sub(Position, Position)
			if Char == "+" then
				Position = Position + 1
				local Right = ParseTerm()
				if Right == nil then
					return nil
				end
				Value = Value + Right
			elseif Char == "-" then
				Position = Position + 1
				local Right = ParseTerm()
				if Right == nil then
					return nil
				end
				Value = Value - Right
			else
				break
			end
		end
		return Value
	end

	local Success, Result = pcall(ParseExpression)
	if not Success or Result == nil then
		return nil
	end
	return Result
end

local function UpdateDisplay()
	if CurrentInput == "" then
		ExpressionLabel.Text = ""
		ResultBox.Text = "0"
		return
	end

	ResultBox.Text = ToDisplay(CurrentInput)

	if LastWasEquals then
		ExpressionLabel.Text = ToDisplay(LastExpression) .. " ="
		return
	end

	ExpressionLabel.Text = ""

	local HasOperator = false
	for Index = 1, #CurrentInput do
		local Char = CurrentInput:sub(Index, Index)
		if Char == "+" or Char == "*" or Char == "/" or (Char == "-" and Index > 1) then
			HasOperator = true
			break
		end
	end

	if not HasOperator then
		return
	end

	local Value = Evaluate(CurrentInput)
	if Value ~= nil then
		ExpressionLabel.Text = "= " .. FormatNumber(Value)
	end
end

local function ToggleSign()
	if CurrentInput == "" then
		CurrentInput = "-"
		return
	end

	local LastOperatorIndex = 0
	for Index = #CurrentInput, 1, -1 do
		if IsOperator(CurrentInput:sub(Index, Index)) then
			LastOperatorIndex = Index
			break
		end
	end

	local NumberStart = LastOperatorIndex + 1
	if LastOperatorIndex == 1 and CurrentInput:sub(1, 1) == "-" then
		NumberStart = 1
		LastOperatorIndex = 0
	end

	if NumberStart > #CurrentInput then
		return
	end

	if CurrentInput:sub(NumberStart, NumberStart) == "-" then
		CurrentInput = CurrentInput:sub(1, NumberStart - 1) .. CurrentInput:sub(NumberStart + 1)
	else
		CurrentInput = CurrentInput:sub(1, NumberStart - 1) .. "-" .. CurrentInput:sub(NumberStart)
	end
end

local function HandleInput(Label : string)
	if Label == "C" then
		CurrentInput = ""
		LastExpression = ""
		LastWasEquals = false
		UpdateDisplay()
		return
	end

	if Label == "DEL" then
		LastWasEquals = false
		LastExpression = ""
		if #CurrentInput > 0 then
			CurrentInput = CurrentInput:sub(1, #CurrentInput - 1)
		end
		UpdateDisplay()
		return
	end

	if Label == "=" then
		if CurrentInput == "" or LastWasEquals then
			return
		end
		local Value = Evaluate(CurrentInput)
		if Value == nil then
			return
		end
		LastExpression = CurrentInput
		CurrentInput = FormatNumber(Value)
		if CurrentInput == "Error" then
			CurrentInput = ""
			LastExpression = ""
			LastWasEquals = false
		else
			LastWasEquals = true
		end
		UpdateDisplay()
		return
	end

	local Internal = ToInput(Label)

	if LastWasEquals then
		if not IsOperator(Internal) then
			CurrentInput = ""
		end
		LastExpression = ""
		LastWasEquals = false
	end

	if Label == "±" then
		ToggleSign()
		UpdateDisplay()
		return
	end

	if Label == "%" then
		if CurrentInput ~= "" then
			CurrentInput = CurrentInput .. "/100"
		end
		UpdateDisplay()
		return
	end

	if IsOperator(Internal) then
		if CurrentInput == "" then
			if Internal == "-" then
				CurrentInput = "-"
			end
		else
			local LastChar = CurrentInput:sub(-1)
			if IsOperator(LastChar) then
				CurrentInput = CurrentInput:sub(1, -2) .. Internal
			else
				CurrentInput = CurrentInput .. Internal
			end
		end
	elseif Internal == "." then
		local LastOperatorIndex = 0
		for Index = #CurrentInput, 1, -1 do
			if IsOperator(CurrentInput:sub(Index, Index)) then
				LastOperatorIndex = Index
				break
			end
		end
		local LastNumber = CurrentInput:sub(LastOperatorIndex + 1)
		if not LastNumber:find("%.") then
			if LastNumber == "" then
				CurrentInput = CurrentInput .. "0."
			else
				CurrentInput = CurrentInput .. "."
			end
		end
	else
		CurrentInput = CurrentInput .. Internal
	end

	UpdateDisplay()
end

local function CreateTitleBar(Parent : Instance) : Frame
	local Bar = Instance.new("Frame")
	Bar.Name = "TitleBar"
	Bar.Size = UDim2.new(1, 0, 0, 26)
	Bar.Position = UDim2.fromOffset(0, 0)
	Bar.BackgroundColor3 = Colors.Dark
	Bar.BorderSizePixel = 0
	Bar.Parent = Parent

	local TitleText = Instance.new("TextLabel")
	TitleText.Name = "TitleText"
	TitleText.Size = UDim2.new(1, -16, 1, 0)
	TitleText.Position = UDim2.fromOffset(8, 0)
	TitleText.BackgroundTransparency = 1
	TitleText.BorderSizePixel = 0
	TitleText.Font = Enum.Font.SourceSansSemibold
	TitleText.Text = "Calculator"
	TitleText.TextColor3 = Colors.White
	TitleText.TextSize = 16
	TitleText.TextXAlignment = Enum.TextXAlignment.Left
	TitleText.TextYAlignment = Enum.TextYAlignment.Center
	TitleText.Parent = Bar

	return Bar
end

local function CreateDisplay(Parent : Instance) : (TextLabel, TextBox)
	local Display = Instance.new("Frame")
	Display.Name = "Display"
	Display.Size = UDim2.new(1, -12, 0, 48)
	Display.Position = UDim2.fromOffset(6, 32)
	Display.BackgroundColor3 = Colors.Dark
	Display.BorderSizePixel = 0
	Display.ClipsDescendants = true
	Display.Parent = Parent

	local Expression = Instance.new("TextLabel")
	Expression.Name = "ExpressionLabel"
	Expression.Size = UDim2.new(1, -16, 0, 16)
	Expression.Position = UDim2.fromOffset(8, 4)
	Expression.BackgroundTransparency = 1
	Expression.BorderSizePixel = 0
	Expression.Font = Enum.Font.Code
	Expression.Text = ""
	Expression.TextColor3 = Colors.Gray
	Expression.TextSize = 13
	Expression.TextXAlignment = Enum.TextXAlignment.Right
	Expression.TextYAlignment = Enum.TextYAlignment.Center
	Expression.Parent = Display

	local Result = Instance.new("TextBox")
	Result.Name = "ResultBox"
	Result.Size = UDim2.new(1, -16, 0, 24)
	Result.Position = UDim2.fromOffset(8, 20)
	Result.BackgroundTransparency = 1
	Result.BorderSizePixel = 0
	Result.Font = Enum.Font.Code
	Result.Text = "0"
	Result.TextColor3 = Colors.White
	Result.TextSize = 20
	Result.TextXAlignment = Enum.TextXAlignment.Right
	Result.TextYAlignment = Enum.TextYAlignment.Center
	Result.TextEditable = false
	Result.ClearTextOnFocus = false
	Result.Selectable = true
	Result.Parent = Display

	return Expression, Result
end

local function CreateButton(Label : string, Order : number, Parent : Instance) : TextButton
	local IsAccent = Label == "C" or Label == "DEL" or Label == "%" or Label == "±"
	local BaseColor = IsAccent and Colors.ButtonAccent or Colors.Button

	local Button = Instance.new("TextButton")
	Button.Name = "Button" .. Order
	Button.Size = UDim2.fromOffset(54, 40)
	Button.BackgroundColor3 = BaseColor
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Font = Enum.Font.SourceSansSemibold
	Button.Text = Label
	Button.TextColor3 = Colors.White
	Button.TextSize = 16
	Button.LayoutOrder = Order
	Button.Parent = Parent

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), {
			BackgroundColor3 = Colors.ButtonHover,
		}):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), {
			BackgroundColor3 = BaseColor,
		}):Play()
	end)

	Button.MouseButton1Click:Connect(function()
		HandleInput(Label)
	end)

	return Button
end

local function CreateGrid(Parent : Instance) : Frame
	local Grid = Instance.new("Frame")
	Grid.Name = "Grid"
	Grid.Size = UDim2.fromOffset(228, 216)
	Grid.Position = UDim2.fromOffset(6, 86)
	Grid.BackgroundTransparency = 1
	Grid.BorderSizePixel = 0
	Grid.Parent = Parent

	local GridLayout = Instance.new("UIGridLayout")
	GridLayout.CellSize = UDim2.fromOffset(54, 40)
	GridLayout.CellPadding = UDim2.fromOffset(4, 4)
	GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	GridLayout.Parent = Grid

	return Grid
end

local function SetupDrag()
	TitleBar.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		IsDragging = true
		DragStart = Input.Position
		DragOrigin = Holder.Position

		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				IsDragging = false
			end
		end)
	end)
end

local function SetupKeyboard()
	local KeyMap = {
		[Enum.KeyCode.Zero] = "0",
		[Enum.KeyCode.One] = "1",
		[Enum.KeyCode.Two] = "2",
		[Enum.KeyCode.Three] = "3",
		[Enum.KeyCode.Four] = "4",
		[Enum.KeyCode.Five] = "5",
		[Enum.KeyCode.Six] = "6",
		[Enum.KeyCode.Seven] = "7",
		[Enum.KeyCode.Eight] = "8",
		[Enum.KeyCode.Nine] = "9",
		[Enum.KeyCode.KeypadZero] = "0",
		[Enum.KeyCode.KeypadOne] = "1",
		[Enum.KeyCode.KeypadTwo] = "2",
		[Enum.KeyCode.KeypadThree] = "3",
		[Enum.KeyCode.KeypadFour] = "4",
		[Enum.KeyCode.KeypadFive] = "5",
		[Enum.KeyCode.KeypadSix] = "6",
		[Enum.KeyCode.KeypadSeven] = "7",
		[Enum.KeyCode.KeypadEight] = "8",
		[Enum.KeyCode.KeypadNine] = "9",
		[Enum.KeyCode.Period] = ".",
		[Enum.KeyCode.KeypadPeriod] = ".",
		[Enum.KeyCode.Slash] = "÷",
		[Enum.KeyCode.KeypadDivide] = "÷",
		[Enum.KeyCode.KeypadMultiply] = "×",
		[Enum.KeyCode.Minus] = "-",
		[Enum.KeyCode.KeypadMinus] = "-",
		[Enum.KeyCode.KeypadPlus] = "+",
		[Enum.KeyCode.Equals] = "=",
		[Enum.KeyCode.Return] = "=",
		[Enum.KeyCode.KeypadEnter] = "=",
		[Enum.KeyCode.Backspace] = "DEL",
		[Enum.KeyCode.Delete] = "C",
	}

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if ResultBox:IsFocused() then
			return
		end
		local Label = KeyMap[Input.KeyCode]
		if Label then
			HandleInput(Label)
		end
	end)
end

-----/Main/-----
local Existing = PlayerGui:FindFirstChild("CalculatorGui")
if Existing then
	Existing:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CalculatorGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = UDim2.fromOffset(240, 310)
Holder.Position = UDim2.new(0, 20, 0, 80)
Holder.BackgroundColor3 = Colors.Background
Holder.BorderSizePixel = 0
Holder.Active = true
Holder.Parent = ScreenGui

TitleBar = CreateTitleBar(Holder)
ExpressionLabel, ResultBox = CreateDisplay(Holder)

local Grid = CreateGrid(Holder)
local Order = 0
for _, Row in ipairs(ButtonLayout) do
	for _, Label in ipairs(Row) do
		Order = Order + 1
		CreateButton(Label, Order, Grid)
	end
end

SetupDrag()
SetupKeyboard()

UserInputService.InputChanged:Connect(function(Input)
	if not IsDragging then
		return
	end
	if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local Delta = Input.Position - DragStart
	Holder.Position = UDim2.new(
		DragOrigin.X.Scale,
		DragOrigin.X.Offset + Delta.X,
		DragOrigin.Y.Scale,
		DragOrigin.Y.Offset + Delta.Y
	)
end)

ResultBox.Focused:Connect(function()
	ResultBox.CursorPosition = #ResultBox.Text + 1
end)

-----/Init/-----
UpdateDisplay()
