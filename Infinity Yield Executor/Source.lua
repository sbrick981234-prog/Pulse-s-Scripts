-----/Services/-----
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SavedScripts = {}
local SelectedScript = nil
local ContextScript = nil

local Dragging = false
local DragStart = nil
local StartPosition = nil

local HighlightUpdating = false

-----/Assets/-----
local BackgroundColor = Color3.fromRGB(47, 47, 48)
local DarkColor = Color3.fromRGB(37, 37, 38)
local HoverColor = Color3.fromRGB(53, 53, 54)
local SelectedColor = Color3.fromRGB(61, 61, 62)
local ScrollColor = Color3.fromRGB(79, 79, 80)

local TextColor = Color3.fromRGB(220, 220, 220)
local SecondaryColor = Color3.fromRGB(171, 171, 171)
local LineColor = Color3.fromRGB(111, 111, 112)

local KeywordColor = Color3.fromRGB(235, 121, 115)
local LuauKeywordColor = Color3.fromRGB(235, 121, 115)
local FunctionNameColor = Color3.fromRGB(250, 228, 170)
local FunctionColor = Color3.fromRGB(235, 121, 115)
local MethodColor = Color3.fromRGB(250, 228, 170)
local PropertyColor = Color3.fromRGB(112, 160, 255)
local NumberColor = Color3.fromRGB(242, 186, 42)
local StringColor = Color3.fromRGB(142, 233, 182)
local CommentColor = Color3.fromRGB(106, 111, 129)
local BoolColor = Color3.fromRGB(242, 186, 42)
local NilColor = Color3.fromRGB(242, 186, 42)
local SelfColor = Color3.fromRGB(235, 121, 115)
local GlobalColor = Color3.fromRGB(78, 201, 176)
local TypeColor = Color3.fromRGB(78, 201, 176)
local BuiltInFunctionColor = Color3.fromRGB(220, 220, 170)
local BracketColor = Color3.fromRGB(188, 190, 200)
local OperatorColor = Color3.fromRGB(188, 190, 200)

-----/Main/-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Executor"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.Parent = PlayerGui

local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Active = true
Holder.BorderSizePixel = 0
Holder.BackgroundColor3 = BackgroundColor
Holder.Size = UDim2.new(0, 350, 0, 250)
Holder.Position = UDim2.new(1, -360, 1, -280)
Holder.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Active = true
Title.BorderSizePixel = 0
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundColor3 = DarkColor
Title.Font = Enum.Font.SourceSans
Title.TextColor3 = TextColor
Title.Size = UDim2.new(1, 0, 0, 20)
Title.Text = "Executor"
Title.Parent = Holder

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 5)
TitlePadding.Parent = Title

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.BorderSizePixel = 0
CloseButton.ZIndex = 10
CloseButton.BackgroundTransparency = 1
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Text = ""
CloseButton.Position = UDim2.new(1, -20, 0, 0)
CloseButton.Parent = Title

local CloseImage = Instance.new("ImageLabel")
CloseImage.Name = "CloseImage"
CloseImage.ZIndex = 10
CloseImage.Image = "rbxassetid://5054663650"
CloseImage.Size = UDim2.new(0, 10, 0, 10)
CloseImage.BackgroundTransparency = 1
CloseImage.Position = UDim2.new(0, 5, 0, 5)
CloseImage.Parent = CloseButton

local SavedFrame = Instance.new("Frame")
SavedFrame.Name = "Saved"
SavedFrame.BorderSizePixel = 0
SavedFrame.BackgroundColor3 = DarkColor
SavedFrame.Size = UDim2.new(0, 82, 0, 191)
SavedFrame.Position = UDim2.new(0, 4, 0, 24)
SavedFrame.Parent = Holder

local SavedTitle = Instance.new("TextLabel")
SavedTitle.Name = "Title"
SavedTitle.BorderSizePixel = 0
SavedTitle.TextSize = 16
SavedTitle.TextXAlignment = Enum.TextXAlignment.Left
SavedTitle.Font = Enum.Font.SourceSans
SavedTitle.TextColor3 = TextColor
SavedTitle.BackgroundTransparency = 1
SavedTitle.Size = UDim2.new(1, -8, 0, 18)
SavedTitle.Text = "Scripts"
SavedTitle.Position = UDim2.new(0, 4, 0, 1)
SavedTitle.Parent = SavedFrame

local ScriptsList = Instance.new("ScrollingFrame")
ScriptsList.Name = "List"
ScriptsList.Active = true
ScriptsList.BorderSizePixel = 0
ScriptsList.CanvasSize = UDim2.new(0, 0, 0, 3)
ScriptsList.Size = UDim2.new(1, -6, 1, -23)
ScriptsList.ScrollBarImageColor3 = ScrollColor
ScriptsList.Position = UDim2.new(0, 3, 0, 20)
ScriptsList.ScrollBarThickness = 6
ScriptsList.BackgroundTransparency = 1
ScriptsList.Parent = SavedFrame

local ScriptsLayout = Instance.new("UIListLayout")
ScriptsLayout.Padding = UDim.new(0, 1)
ScriptsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptsLayout.Parent = ScriptsList

local CodeFrame = Instance.new("Frame")
CodeFrame.Name = "Code"
CodeFrame.BorderSizePixel = 0
CodeFrame.BackgroundColor3 = DarkColor
CodeFrame.ClipsDescendants = true
CodeFrame.Size = UDim2.new(1, -94, 0, 191)
CodeFrame.Position = UDim2.new(0, 90, 0, 24)
CodeFrame.Parent = Holder

-----/Editor/-----
local Lines = Instance.new("ScrollingFrame")
Lines.Name = "Lines"
Lines.Active = false
Lines.BorderSizePixel = 0
Lines.CanvasSize = UDim2.new(0, 0, 0, 191)
Lines.ScrollingEnabled = false
Lines.BackgroundColor3 = DarkColor
Lines.Size = UDim2.new(0, 20, 1, 0)
Lines.ScrollBarThickness = 0
Lines.ClipsDescendants = true
Lines.ZIndex = 2
Lines.Parent = CodeFrame

local LinesText = Instance.new("TextLabel")
LinesText.Name = "Text"
LinesText.BorderSizePixel = 0
LinesText.TextSize = 14
LinesText.TextXAlignment = Enum.TextXAlignment.Right
LinesText.TextYAlignment = Enum.TextYAlignment.Top
LinesText.Font = Enum.Font.Code
LinesText.TextColor3 = LineColor
LinesText.BackgroundTransparency = 1
LinesText.Size = UDim2.new(1, 0, 0, 191)
LinesText.Text = "1"
LinesText.Position = UDim2.new(0, 0, 0, 4)
LinesText.ZIndex = 3
LinesText.Parent = Lines

local LinesPadding = Instance.new("UIPadding")
LinesPadding.PaddingRight = UDim.new(0, 5)
LinesPadding.Parent = LinesText

local CodeScroll = Instance.new("ScrollingFrame")
CodeScroll.Name = "CodeScroll"
CodeScroll.Active = true
CodeScroll.BorderSizePixel = 0
CodeScroll.CanvasSize = UDim2.new(0, 1000, 0, 191)
CodeScroll.Size = UDim2.new(1, -20, 1, 0)
CodeScroll.ScrollBarImageColor3 = ScrollColor
CodeScroll.Position = UDim2.new(0, 20, 0, 0)
CodeScroll.ScrollBarThickness = 6
CodeScroll.BackgroundTransparency = 1
CodeScroll.ScrollingDirection = Enum.ScrollingDirection.XY
CodeScroll.ClipsDescendants = true
CodeScroll.ZIndex = 2
CodeScroll.Parent = CodeFrame

local HighlightBox = Instance.new("TextLabel")
HighlightBox.Name = "Text"
HighlightBox.BorderSizePixel = 0
HighlightBox.BackgroundTransparency = 1
HighlightBox.TextXAlignment = Enum.TextXAlignment.Left
HighlightBox.TextYAlignment = Enum.TextYAlignment.Top
HighlightBox.TextSize = 14
HighlightBox.Font = Enum.Font.Code
HighlightBox.RichText = true
HighlightBox.TextColor3 = TextColor
HighlightBox.TextWrapped = false
HighlightBox.Size = UDim2.new(1, -10, 0, 18)
HighlightBox.Position = UDim2.new(0, 5, 0, 4)
HighlightBox.ZIndex = 3
HighlightBox.Parent = CodeScroll

local CodeBox = Instance.new("TextBox")
CodeBox.Name = "CodeBox"
CodeBox.TextXAlignment = Enum.TextXAlignment.Left
CodeBox.TextYAlignment = Enum.TextYAlignment.Top
CodeBox.PlaceholderColor3 = SecondaryColor
CodeBox.BorderSizePixel = 0
CodeBox.TextSize = 14
CodeBox.TextColor3 = TextColor
CodeBox.TextTransparency = 1
CodeBox.Font = Enum.Font.Code
CodeBox.AutomaticSize = Enum.AutomaticSize.Y
CodeBox.MultiLine = true
CodeBox.ClearTextOnFocus = false
CodeBox.PlaceholderText = "-- Write your script here"
CodeBox.Size = UDim2.new(1, -10, 0, 18)
CodeBox.Position = UDim2.new(0, 5, 0, 4)
CodeBox.Text = ""
CodeBox.BackgroundTransparency = 1
CodeBox.ZIndex = 4
CodeBox.Parent = CodeScroll

-----/Buttons/-----
local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Name = "Buttons"
ButtonsFrame.BorderSizePixel = 0
ButtonsFrame.BackgroundColor3 = DarkColor
ButtonsFrame.Size = UDim2.new(1, -8, 0, 27)
ButtonsFrame.Position = UDim2.new(0, 4, 0, 219)
ButtonsFrame.Parent = Holder

local ButtonsLayout = Instance.new("UIListLayout")
ButtonsLayout.Padding = UDim.new(0, 2)
ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonsLayout.Parent = ButtonsFrame

local function CreateButton(Name : string)
	local Button = Instance.new("TextButton")
	Button.Name = Name
	Button.BorderSizePixel = 0
	Button.TextSize = 16
	Button.AutoButtonColor = false
	Button.TextColor3 = TextColor
	Button.BackgroundColor3 = BackgroundColor
	Button.Font = Enum.Font.SourceSans
	Button.Size = UDim2.new(0.25, -1, 1, 0)
	Button.Text = Name
	Button.Parent = ButtonsFrame

	Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = HoverColor
	end)

	Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = BackgroundColor
	end)

	return Button
end

local ClearButton = CreateButton("Clear")
local ExecuteButton = CreateButton("Execute")
local SaveButton = CreateButton("Save")
local LoadButton = CreateButton("Load")

-----/Context Menu/-----
local ContextMenu = Instance.new("Frame")
ContextMenu.Name = "ContextMenu"
ContextMenu.Visible = false
ContextMenu.ZIndex = 20
ContextMenu.BorderSizePixel = 0
ContextMenu.BackgroundColor3 = DarkColor
ContextMenu.Size = UDim2.new(0, 100, 0, 44)
ContextMenu.Parent = ScreenGui

local RenameButton = Instance.new("TextButton")
RenameButton.Name = "Rename"
RenameButton.BorderSizePixel = 0
RenameButton.TextSize = 15
RenameButton.AutoButtonColor = false
RenameButton.TextColor3 = TextColor
RenameButton.BackgroundColor3 = DarkColor
RenameButton.Font = Enum.Font.SourceSans
RenameButton.ZIndex = 21
RenameButton.Size = UDim2.new(1, 0, 0, 22)
RenameButton.Text = "Rename"
RenameButton.Parent = ContextMenu

local DeleteButton = Instance.new("TextButton")
DeleteButton.Name = "Delete"
DeleteButton.BorderSizePixel = 0
DeleteButton.TextSize = 15
DeleteButton.AutoButtonColor = false
DeleteButton.TextColor3 = TextColor
DeleteButton.BackgroundColor3 = DarkColor
DeleteButton.Font = Enum.Font.SourceSans
DeleteButton.ZIndex = 21
DeleteButton.Size = UDim2.new(1, 0, 0, 22)
DeleteButton.Text = "Delete"
DeleteButton.Position = UDim2.new(0, 0, 0, 22)
DeleteButton.Parent = ContextMenu

-----/Rename Window/-----
local RenameFrame = Instance.new("Frame")
RenameFrame.Name = "RenameFrame"
RenameFrame.Visible = false
RenameFrame.ZIndex = 30
RenameFrame.BorderSizePixel = 0
RenameFrame.BackgroundColor3 = DarkColor
RenameFrame.Size = UDim2.new(0, 200, 0, 60)
RenameFrame.Position = UDim2.new(0.5, -100, 0.5, -30)
RenameFrame.Parent = ScreenGui

local RenameBox = Instance.new("TextBox")
RenameBox.Name = "Name"
RenameBox.ZIndex = 31
RenameBox.BorderSizePixel = 0
RenameBox.TextSize = 15
RenameBox.TextColor3 = TextColor
RenameBox.BackgroundColor3 = BackgroundColor
RenameBox.Font = Enum.Font.SourceSans
RenameBox.ClearTextOnFocus = false
RenameBox.PlaceholderText = "Script name"
RenameBox.Size = UDim2.new(1, -8, 0, 24)
RenameBox.Position = UDim2.new(0, 4, 0, 4)
RenameBox.Text = ""
RenameBox.Parent = RenameFrame

local RenameConfirm = Instance.new("TextButton")
RenameConfirm.Name = "Confirm"
RenameConfirm.BorderSizePixel = 0
RenameConfirm.TextSize = 15
RenameConfirm.AutoButtonColor = false
RenameConfirm.TextColor3 = TextColor
RenameConfirm.BackgroundColor3 = BackgroundColor
RenameConfirm.Font = Enum.Font.SourceSans
RenameConfirm.ZIndex = 31
RenameConfirm.Size = UDim2.new(1, -8, 0, 23)
RenameConfirm.Text = "Rename"
RenameConfirm.Position = UDim2.new(0, 4, 0, 32)
RenameConfirm.Parent = RenameFrame

-----/Functions/-----
local function EscapeRichText(Text : string)
	return Text
		:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
		:gsub('"', "&quot;")
end

local function ToHex(Color : Color3)
	return string.format(
		"#%02X%02X%02X",
		math.floor(Color.R * 255),
		math.floor(Color.G * 255),
		math.floor(Color.B * 255)
	)
end

local KeywordList = {
	["local"] = true,
	["function"] = true,
	["return"] = true,
	["if"] = true,
	["then"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["for"] = true,
	["while"] = true,
	["repeat"] = true,
	["until"] = true,
	["do"] = true,
	["in"] = true,
	["break"] = true,
	["continue"] = true,
	["and"] = true,
	["or"] = true,
	["not"] = true,
	["game"] = true
}

local LuauKeywordList = {
	["type"] = true,
	["export"] = true
}

local BooleanList = {
	["true"] = true,
	["false"] = true
}

local NilList = {
	["nil"] = true
}

local SelfList = {
	["self"] = true
}

local GlobalList = {
	["workspace"] = true,
	["script"] = true,
	["Instance"] = true,
	["Color3"] = true,
	["UDim2"] = true,
	["UDim"] = true,
	["Vector2"] = true,
	["Vector3"] = true,
	["Vector2int16"] = true,
	["Vector3int16"] = true,
	["CFrame"] = true,
	["Enum"] = true,
	["task"] = true,
	["Players"] = true,
	["math"] = true,
	["string"] = true,
	["table"] = true,
	["coroutine"] = true,
	["os"] = true,
	["debug"] = true,
	["utf8"] = true,
	["buffer"] = true,
	["bit32"] = true,
	["DateTime"] = true,
	["RaycastParams"] = true,
	["OverlapParams"] = true,
	["TweenInfo"] = true,
	["BrickColor"] = true,
	["NumberRange"] = true,
	["NumberSequence"] = true,
	["ColorSequence"] = true,
	["Region3"] = true,
	["Rect"] = true,
	["Axes"] = true,
	["Faces"] = true
}

local TypeList = {
	["string"] = true,
	["number"] = true,
	["boolean"] = true,
	["table"] = true,
	["thread"] = true,
	["function"] = true,
	["userdata"] = true,
	["any"] = true,
	["unknown"] = true,
	["never"] = true
}

local FunctionList = {
	["print"] = true,
	["warn"] = true,
	["require"] = true,
	["loadstring"] = true,
	["typeof"] = true,
	["tostring"] = true,
	["tonumber"] = true,
	["pairs"] = true,
	["ipairs"] = true,
	["next"] = true,
	["select"] = true,
	["pcall"] = true,
	["xpcall"] = true,
	["assert"] = true,
	["error"] = true,
	["rawget"] = true,
	["rawset"] = true,
	["rawequal"] = true,
	["rawlen"] = true,
	["setmetatable"] = true,
	["getmetatable"] = true,
	["unpack"] = true,
	["collectgarbage"] = true
}

local function GetLineCount(Text : string)
	if Text == "" then
		return 1
	end

	local Count = 1

	for _ in Text:gmatch("\n") do
		Count += 1
	end

	return Count
end

local function HighlightSyntax(Source : string)
	local Output = {}
	local Position = 1
	local Length = #Source

	local KeywordHex = ToHex(KeywordColor)
	local LuauKeywordHex = ToHex(LuauKeywordColor)
	local StringHex = ToHex(StringColor)
	local NumberHex = ToHex(NumberColor)
	local CommentHex = ToHex(CommentColor)
	local GlobalHex = ToHex(GlobalColor)
	local FunctionHex = ToHex(FunctionColor)
	local FunctionNameHex = ToHex(FunctionNameColor)
	local MethodHex = ToHex(MethodColor)
	local PropertyHex = ToHex(PropertyColor)
	local BooleanHex = ToHex(BoolColor)
	local NilHex = ToHex(NilColor)
	local SelfHex = ToHex(SelfColor)
	local BuiltInFunctionHex = ToHex(BuiltInFunctionColor)
	local TypeHex = ToHex(TypeColor)
	local BracketHex = ToHex(BracketColor)
	local OperatorHex = ToHex(OperatorColor)

	local function Add(Text : string, Color : string?)
		Text = EscapeRichText(Text)

		if Color then
			table.insert(Output, '<font color="' .. Color .. '">' .. Text .. "</font>")
		else
			table.insert(Output, Text)
		end
	end

	local function IsIdentifierStart(Character : string)
		return Character ~= "" and Character:match("[%a_]") ~= nil
	end

	local function IsIdentifierCharacter(Character : string)
		return Character ~= "" and Character:match("[%w_]") ~= nil
	end

	local function GetPreviousNonSpace(Index : number)
		local Current = Index

		while Current > 1 do
			local Character = Source:sub(Current - 1, Current - 1)

			if not Character:match("%s") then
				return Character, Current - 1
			end

			Current -= 1
		end

		return "", 0
	end

	local function GetNextNonSpace(Index : number)
		local Current = Index

		while Current <= Length do
			local Character = Source:sub(Current, Current)

			if not Character:match("%s") then
				return Character, Current
			end

			Current += 1
		end

		return "", Length + 1
	end

	while Position <= Length do
		local Character = Source:sub(Position, Position)
		local NextCharacter = Source:sub(Position + 1, Position + 1)
		local ThirdCharacter = Source:sub(Position + 2, Position + 2)

		if Character == "-" and NextCharacter == "-" then
			if ThirdCharacter == "[" and Source:sub(Position + 3, Position + 3) == "[" then
				local EndPosition = Source:find("]]", Position + 4, true)

				if EndPosition then
					local CommentEnd = EndPosition + 1
					Add(Source:sub(Position, CommentEnd), CommentHex)
					Position = CommentEnd + 1
				else
					Add(Source:sub(Position), CommentHex)
					break
				end
			else
				local NewLine = Source:find("\n", Position, true)
				local EndPosition = NewLine and NewLine - 1 or Length

				Add(Source:sub(Position, EndPosition), CommentHex)
				Position = EndPosition + 1
			end

		elseif Character == "[" and NextCharacter == "[" then
			local EndPosition = Source:find("]]", Position + 2, true)

			if EndPosition then
				local StringEnd = EndPosition + 1
				Add(Source:sub(Position, StringEnd), StringHex)
				Position = StringEnd + 1
			else
				Add(Source:sub(Position), StringHex)
				break
			end

		elseif Character == '"' or Character == "'" then
			local Quote = Character
			local Current = Position + 1

			while Current <= Length do
				local CurrentCharacter = Source:sub(Current, Current)

				if CurrentCharacter == "\\" then
					Current += 2
				elseif CurrentCharacter == Quote then
					Current += 1
					break
				else
					Current += 1
				end
			end

			Add(Source:sub(Position, Current - 1), StringHex)
			Position = Current

		elseif Character:match("%d") or (Character == "." and NextCharacter:match("%d")) then
			local Current = Position
			local HasExponent = false

			while Current <= Length do
				local NumberCharacter = Source:sub(Current, Current)

				if NumberCharacter:match("[%d%.]") then
					Current += 1
				elseif (NumberCharacter == "e" or NumberCharacter == "E") and not HasExponent then
					HasExponent = true
					Current += 1

					local Sign = Source:sub(Current, Current)

					if Sign == "+" or Sign == "-" then
						Current += 1
					end
				elseif (NumberCharacter == "x" or NumberCharacter == "X") and Current == Position + 1 then
					Current += 1
				elseif NumberCharacter:match("[%a]") and Source:sub(Position, Position + 1):lower() == "0x" then
					Current += 1
				else
					break
				end
			end

			Add(Source:sub(Position, Current - 1), NumberHex)
			Position = Current

		elseif IsIdentifierStart(Character) then
			local Current = Position + 1

			while Current <= Length and IsIdentifierCharacter(Source:sub(Current, Current)) do
				Current += 1
			end

			local Identifier = Source:sub(Position, Current - 1)
			local Color = nil

			local PreviousCharacter, PreviousPosition = GetPreviousNonSpace(Position)
			local NextNonSpace, NextPosition = GetNextNonSpace(Current)

			if KeywordList[Identifier] then
				Color = KeywordHex

			elseif LuauKeywordList[Identifier] then
				Color = LuauKeywordHex

			elseif BooleanList[Identifier] then
				Color = BooleanHex

			elseif NilList[Identifier] then
				Color = NilHex

			elseif SelfList[Identifier] then
				Color = SelfHex

			elseif TypeList[Identifier] and PreviousCharacter == ":" then
				Color = TypeHex

			elseif GlobalList[Identifier] then
				Color = GlobalHex

			elseif FunctionList[Identifier] then
				Color = BuiltInFunctionHex

			elseif PreviousCharacter == ":" then
				Color = MethodHex

			elseif PreviousCharacter == "." then
				Color = PropertyHex

			elseif PreviousCharacter == ":" and NextNonSpace == "(" then
				Color = MethodHex

			elseif NextNonSpace == "(" then
				Color = FunctionHex
			end

			if Identifier == "function" then
				Add(Identifier, KeywordHex)
				Position = Current

				local FunctionStart = Current
				local FunctionCharacter, FunctionPosition = GetNextNonSpace(FunctionStart)

				if IsIdentifierStart(FunctionCharacter) then
					local NameEnd = FunctionPosition + 1

					while NameEnd <= Length and IsIdentifierCharacter(Source:sub(NameEnd, NameEnd)) do
						NameEnd += 1
					end

					local FunctionName = Source:sub(FunctionPosition, NameEnd - 1)

					if FunctionName ~= "" then
						Add(Source:sub(FunctionStart, FunctionPosition - 1))
						Add(FunctionName, FunctionNameHex)
						Position = NameEnd
					end
				end
			else
				Add(Identifier, Color)
				Position = Current
			end

		elseif Character == ":" and NextCharacter == ":" then
			Add("::", OperatorHex)
			Position += 2

		elseif Character == "." and NextCharacter == "." and ThirdCharacter == "." then
			Add("...", OperatorHex)
			Position += 3

		elseif Character == "." and NextCharacter == "." then
			Add("..", OperatorHex)
			Position += 2

		elseif Character == "=" and NextCharacter == "=" then
			Add("==", OperatorHex)
			Position += 2

		elseif Character == "~" and NextCharacter == "=" then
			Add("~=", OperatorHex)
			Position += 2

		elseif Character == "<" and NextCharacter == "=" then
			Add("<=", OperatorHex)
			Position += 2

		elseif Character == ">" and NextCharacter == "=" then
			Add(">=", OperatorHex)
			Position += 2

		elseif Character == "=" and NextCharacter == ">" then
			Add("=>", OperatorHex)
			Position += 2

		elseif Character == "+" and NextCharacter == "=" then
			Add("+=", OperatorHex)
			Position += 2

		elseif Character == "-" and NextCharacter == "=" then
			Add("-=", OperatorHex)
			Position += 2

		elseif Character == "*" and NextCharacter == "=" then
			Add("*=", OperatorHex)
			Position += 2

		elseif Character == "/" and NextCharacter == "=" then
			Add("/=", OperatorHex)
			Position += 2

		elseif Character == "%" and NextCharacter == "=" then
			Add("%=", OperatorHex)
			Position += 2

		elseif Character == "^" and NextCharacter == "=" then
			Add("^=", OperatorHex)
			Position += 2

		elseif Character:match("[=<>~%+%-%*/%^%%]") then
			Add(Character, OperatorHex)
			Position += 1

		elseif Character:match("[%(%)%[%]{}]") then
			Add(Character, BracketHex)
			Position += 1

		else
			Add(Character)
			Position += 1
		end
	end

	return table.concat(Output)
end

local function UpdateSyntaxHighlight()
	if HighlightUpdating then
		return
	end

	HighlightUpdating = true

	local Source = CodeBox.Text

	if Source == "" then
		HighlightBox.Text = ""
	else
		HighlightBox.Text = HighlightSyntax(Source)
	end

	HighlightBox.Size = UDim2.new(
		0,
		math.max(CodeBox.AbsoluteSize.X, CodeScroll.AbsoluteSize.X - 10),
		0,
		math.max(CodeBox.AbsoluteSize.Y, 18)
	)

	HighlightUpdating = false
end

local function UpdateLines()
	local LineCount = GetLineCount(CodeBox.Text)
	local LineData = table.create(LineCount)

	for Index = 1, LineCount do
		LineData[Index] = tostring(Index)
	end

	LinesText.Text = table.concat(LineData, "\n")

	local Height = math.max(CodeBox.AbsoluteSize.Y + 8, CodeScroll.AbsoluteSize.Y)

	Lines.CanvasSize = UDim2.new(0, 0, 0, Height)

	CodeScroll.CanvasSize = UDim2.new(
		0,
		math.max(CodeBox.AbsoluteSize.X + 10, CodeScroll.AbsoluteSize.X),
		0,
		Height
	)

	UpdateSyntaxHighlight()
end

local function UpdateScroll()
	Lines.CanvasPosition = Vector2.new(0, CodeScroll.CanvasPosition.Y)
end

local function UpdateCanvas()
	ScriptsList.CanvasSize = UDim2.new(
		0,
		0,
		0,
		ScriptsLayout.AbsoluteContentSize.Y + 3
	)
end

local function SelectScript(Index : number)
	local Data = SavedScripts[Index]

	if not Data then
		return
	end

	SelectedScript = Index
	CodeBox.Text = Data.Source

	for _, Object in ipairs(ScriptsList:GetChildren()) do
		if Object:IsA("TextButton") then
			Object.BackgroundColor3 = BackgroundColor
		end
	end

	local Button = ScriptsList:FindFirstChild("Script_" .. Index)

	if Button then
		Button.BackgroundColor3 = SelectedColor
	end

	task.defer(UpdateLines)
end

local function RefreshScripts()
	for _, Object in ipairs(ScriptsList:GetChildren()) do
		if Object:IsA("TextButton") then
			Object:Destroy()
		end
	end

	for Index, Data in ipairs(SavedScripts) do
		local Button = Instance.new("TextButton")
		Button.Name = "Script_" .. Index
		Button.BackgroundColor3 = Index == SelectedScript and SelectedColor or BackgroundColor
		Button.BorderSizePixel = 0
		Button.Size = UDim2.new(1, -2, 0, 24)
		Button.Font = Enum.Font.SourceSans
		Button.Text = Data.Name
		Button.TextColor3 = TextColor
		Button.TextSize = 15
		Button.TextXAlignment = Enum.TextXAlignment.Left
		Button.AutoButtonColor = false
		Button.LayoutOrder = Index
		Button.Parent = ScriptsList

		local Padding = Instance.new("UIPadding")
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.Parent = Button

		Button.MouseEnter:Connect(function()
			if SelectedScript ~= Index then
				Button.BackgroundColor3 = HoverColor
			end
		end)

		Button.MouseLeave:Connect(function()
			if SelectedScript ~= Index then
				Button.BackgroundColor3 = BackgroundColor
			end
		end)

		Button.MouseButton1Click:Connect(function()
			ContextMenu.Visible = false
			ContextScript = nil
			SelectScript(Index)
		end)

		Button.MouseButton2Click:Connect(function()
			ContextScript = Index
			SelectedScript = Index
			CodeBox.Text = Data.Source

			ContextMenu.Position = UDim2.new(
				0,
				Button.AbsolutePosition.X + Button.AbsoluteSize.X + 3,
				0,
				Button.AbsolutePosition.Y
			)

			ContextMenu.Visible = true
			RefreshScripts()

			task.defer(UpdateLines)
		end)
	end

	UpdateCanvas()
end

local function SaveScript()
	if CodeBox.Text == "" then
		return
	end

	local Index = #SavedScripts + 1

	SavedScripts[Index] = {
		Name = "Script " .. Index,
		Source = CodeBox.Text
	}

	SelectedScript = Index
	ContextScript = nil

	RefreshScripts()
end

local function LoadScript()
	if not SelectedScript then
		return
	end

	local Data = SavedScripts[SelectedScript]

	if not Data then
		return
	end

	CodeBox.Text = Data.Source
	task.defer(UpdateLines)
end

local function DeleteScript()
	if not ContextScript then
		return
	end

	local Index = ContextScript
	local Data = SavedScripts[Index]

	if not Data then
		ContextScript = nil
		ContextMenu.Visible = false
		return
	end

	table.remove(SavedScripts, Index)

	if SelectedScript == Index then
		SelectedScript = nil
		CodeBox.Text = ""
	elseif SelectedScript and SelectedScript > Index then
		SelectedScript -= 1
	end

	ContextScript = nil
	ContextMenu.Visible = false

	RefreshScripts()
	task.defer(UpdateLines)
end

local function OpenRename()
	local Index = ContextScript or SelectedScript

	if not Index then
		return
	end

	local Data = SavedScripts[Index]

	if not Data then
		return
	end

	SelectedScript = Index
	ContextScript = Index
	ContextMenu.Visible = false

	RenameBox.Text = Data.Name
	RenameFrame.Visible = true
	RenameBox:CaptureFocus()
	RenameBox.CursorPosition = #RenameBox.Text + 1
end

local function RenameScript()
	local Index = ContextScript or SelectedScript

	if not Index then
		RenameFrame.Visible = false
		return
	end

	local Data = SavedScripts[Index]

	if not Data then
		RenameFrame.Visible = false
		return
	end

	if RenameBox.Text == "" then
		return
	end

	Data.Name = RenameBox.Text

	SelectedScript = Index
	ContextScript = nil
	RenameFrame.Visible = false

	RefreshScripts()
end

-----/Buttons/-----
ClearButton.MouseButton1Click:Connect(function()
	CodeBox.Text = ""
	SelectedScript = nil
	ContextScript = nil
	ContextMenu.Visible = false

	RefreshScripts()
	task.defer(UpdateLines)
end)

ExecuteButton.MouseButton1Click:Connect(function()
	if CodeBox.Text == "" then
		return
	end

	loadstring(CodeBox.Text)()
end)

SaveButton.MouseButton1Click:Connect(function()
	SaveScript()
end)

LoadButton.MouseButton1Click:Connect(function()
	LoadScript()
end)

CloseButton.MouseEnter:Connect(function()
	CloseImage.ImageColor3 = Color3.fromRGB(220, 220, 220)
end)

CloseButton.MouseLeave:Connect(function()
	CloseImage.ImageColor3 = TextColor
end)

CloseButton.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

RenameButton.MouseEnter:Connect(function()
	RenameButton.BackgroundColor3 = HoverColor
end)

RenameButton.MouseLeave:Connect(function()
	RenameButton.BackgroundColor3 = DarkColor
end)

DeleteButton.MouseEnter:Connect(function()
	DeleteButton.BackgroundColor3 = HoverColor
end)

DeleteButton.MouseLeave:Connect(function()
	DeleteButton.BackgroundColor3 = DarkColor
end)

RenameButton.MouseButton1Click:Connect(function()
	OpenRename()
end)

DeleteButton.MouseButton1Click:Connect(function()
	DeleteScript()
end)

RenameConfirm.MouseButton1Click:Connect(function()
	RenameScript()
end)

RenameBox.FocusLost:Connect(function(EnterPressed)
	if EnterPressed then
		RenameScript()
	end
end)

-----/Input/-----
UserInputService.InputBegan:Connect(function(Input)
	if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not ContextMenu.Visible then
		return
	end

	local MousePosition = Input.Position
	local MenuPosition = ContextMenu.AbsolutePosition
	local MenuSize = ContextMenu.AbsoluteSize

	local InsideMenu =
		MousePosition.X >= MenuPosition.X
		and MousePosition.X <= MenuPosition.X + MenuSize.X
		and MousePosition.Y >= MenuPosition.Y
		and MousePosition.Y <= MenuPosition.Y + MenuSize.Y

	if not InsideMenu then
		ContextMenu.Visible = false
		ContextScript = nil
	end
end)

-----/Dragging/-----
Title.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Holder.Position
	end
end)

Title.InputEnded:Connect(function(Input)
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

	local Delta = Input.Position - DragStart

	Holder.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end)

-----/Lines/-----
CodeBox:GetPropertyChangedSignal("Text"):Connect(function()
	UpdateLines()
end)

CodeBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	UpdateLines()
end)

CodeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	UpdateScroll()
end)

CodeScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	UpdateLines()
end)

-----/Init/-----
ScriptsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

UpdateCanvas()
UpdateLines()
UpdateScroll()
RefreshScripts()
