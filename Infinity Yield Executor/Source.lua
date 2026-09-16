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

-----/Assets/-----
local BackgroundColor = Color3.fromRGB(46, 46, 47)
local DarkColor = Color3.fromRGB(36, 36, 37)
local HoverColor = Color3.fromRGB(52, 52, 53)
local SelectedColor = Color3.fromRGB(60, 60, 61)
local ScrollColor = Color3.fromRGB(78, 78, 79)
local TextColor = Color3.fromRGB(255, 255, 255)
local SecondaryColor = Color3.fromRGB(170, 170, 170)

-----/Main/-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Executor"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Active = true
Holder.BackgroundColor3 = BackgroundColor
Holder.BorderSizePixel = 0
Holder.Position = UDim2.new(1, -360, 1, -280)
Holder.Size = UDim2.new(0, 350, 0, 250)
Holder.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Active = true
Title.BackgroundColor3 = DarkColor
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 20)
Title.Font = Enum.Font.SourceSans
Title.Text = "Executor"
Title.TextColor3 = TextColor
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Holder

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 5)
TitlePadding.Parent = Title

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.BackgroundTransparency = 1
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -20, 0, 0)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Text = ""
CloseButton.ZIndex = 10
CloseButton.Parent = Title

local CloseImage = Instance.new("ImageLabel")
CloseImage.Name = "CloseImage"
CloseImage.BackgroundTransparency = 1
CloseImage.Position = UDim2.new(0, 5, 0, 5)
CloseImage.Size = UDim2.new(0, 10, 0, 10)
CloseImage.Image = "rbxassetid://5054663650"
CloseImage.ZIndex = 10
CloseImage.Parent = CloseButton

local SavedFrame = Instance.new("Frame")
SavedFrame.Name = "Saved"
SavedFrame.BackgroundColor3 = DarkColor
SavedFrame.BorderSizePixel = 0
SavedFrame.Position = UDim2.new(0, 4, 0, 24)
SavedFrame.Size = UDim2.new(0, 82, 0, 191)
SavedFrame.Parent = Holder

local SavedTitle = Instance.new("TextLabel")
SavedTitle.Name = "Title"
SavedTitle.BackgroundTransparency = 1
SavedTitle.BorderSizePixel = 0
SavedTitle.Position = UDim2.new(0, 4, 0, 1)
SavedTitle.Size = UDim2.new(1, -8, 0, 18)
SavedTitle.Font = Enum.Font.SourceSans
SavedTitle.Text = "Scripts"
SavedTitle.TextColor3 = TextColor
SavedTitle.TextSize = 16
SavedTitle.TextXAlignment = Enum.TextXAlignment.Left
SavedTitle.Parent = SavedFrame

local ScriptsList = Instance.new("ScrollingFrame")
ScriptsList.Name = "List"
ScriptsList.Active = true
ScriptsList.BackgroundTransparency = 1
ScriptsList.BorderSizePixel = 0
ScriptsList.Position = UDim2.new(0, 3, 0, 20)
ScriptsList.Size = UDim2.new(1, -6, 1, -23)
ScriptsList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptsList.ScrollBarThickness = 6
ScriptsList.ScrollBarImageColor3 = ScrollColor
ScriptsList.Parent = SavedFrame

local ScriptsLayout = Instance.new("UIListLayout")
ScriptsLayout.Padding = UDim.new(0, 1)
ScriptsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptsLayout.Parent = ScriptsList

local CodeFrame = Instance.new("Frame")
CodeFrame.Name = "Code"
CodeFrame.BackgroundColor3 = DarkColor
CodeFrame.BorderSizePixel = 0
CodeFrame.Position = UDim2.new(0, 90, 0, 24)
CodeFrame.Size = UDim2.new(1, -94, 0, 191)
CodeFrame.Parent = Holder

local CodeBox = Instance.new("TextBox")
CodeBox.Name = "CodeBox"
CodeBox.BackgroundTransparency = 1
CodeBox.BorderSizePixel = 0
CodeBox.ClearTextOnFocus = false
CodeBox.MultiLine = true
CodeBox.Position = UDim2.new(0, 5, 0, 4)
CodeBox.Size = UDim2.new(1, -10, 1, -8)
CodeBox.Font = Enum.Font.Code
CodeBox.PlaceholderColor3 = SecondaryColor
CodeBox.PlaceholderText = "-- Write your script here"
CodeBox.Text = ""
CodeBox.TextColor3 = TextColor
CodeBox.TextSize = 14
CodeBox.TextWrapped = false
CodeBox.TextXAlignment = Enum.TextXAlignment.Left
CodeBox.TextYAlignment = Enum.TextYAlignment.Top
CodeBox.Parent = CodeFrame

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Name = "Buttons"
ButtonsFrame.BackgroundColor3 = DarkColor
ButtonsFrame.BorderSizePixel = 0
ButtonsFrame.Position = UDim2.new(0, 4, 0, 219)
ButtonsFrame.Size = UDim2.new(1, -8, 0, 27)
ButtonsFrame.Parent = Holder

local ButtonsLayout = Instance.new("UIListLayout")
ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ButtonsLayout.Padding = UDim.new(0, 2)
ButtonsLayout.Parent = ButtonsFrame

local function CreateButton(Name : string)
	local Button = Instance.new("TextButton")
	Button.Name = Name
	Button.BackgroundColor3 = BackgroundColor
	Button.BorderSizePixel = 0
	Button.Size = UDim2.new(0.25, -1.5, 1, 0)
	Button.Font = Enum.Font.SourceSans
	Button.Text = Name
	Button.TextColor3 = TextColor
	Button.TextSize = 16
	Button.AutoButtonColor = false
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
ContextMenu.BackgroundColor3 = DarkColor
ContextMenu.BorderSizePixel = 0
ContextMenu.Size = UDim2.new(0, 100, 0, 44)
ContextMenu.ZIndex = 20
ContextMenu.Parent = ScreenGui

local RenameButton = Instance.new("TextButton")
RenameButton.Name = "Rename"
RenameButton.BackgroundColor3 = DarkColor
RenameButton.BorderSizePixel = 0
RenameButton.Size = UDim2.new(1, 0, 0, 22)
RenameButton.Font = Enum.Font.SourceSans
RenameButton.Text = "Rename"
RenameButton.TextColor3 = TextColor
RenameButton.TextSize = 15
RenameButton.AutoButtonColor = false
RenameButton.ZIndex = 21
RenameButton.Parent = ContextMenu

local DeleteButton = Instance.new("TextButton")
DeleteButton.Name = "Delete"
DeleteButton.BackgroundColor3 = DarkColor
DeleteButton.BorderSizePixel = 0
DeleteButton.Position = UDim2.new(0, 0, 0, 22)
DeleteButton.Size = UDim2.new(1, 0, 0, 22)
DeleteButton.Font = Enum.Font.SourceSans
DeleteButton.Text = "Delete"
DeleteButton.TextColor3 = TextColor
DeleteButton.TextSize = 15
DeleteButton.AutoButtonColor = false
DeleteButton.ZIndex = 21
DeleteButton.Parent = ContextMenu

-----/Rename Window/-----
local RenameFrame = Instance.new("Frame")
RenameFrame.Name = "RenameFrame"
RenameFrame.Visible = false
RenameFrame.BackgroundColor3 = DarkColor
RenameFrame.BorderSizePixel = 0
RenameFrame.Position = UDim2.new(0.5, -100, 0.5, -30)
RenameFrame.Size = UDim2.new(0, 200, 0, 60)
RenameFrame.ZIndex = 30
RenameFrame.Parent = ScreenGui

local RenameBox = Instance.new("TextBox")
RenameBox.Name = "Name"
RenameBox.BackgroundColor3 = BackgroundColor
RenameBox.BorderSizePixel = 0
RenameBox.Position = UDim2.new(0, 4, 0, 4)
RenameBox.Size = UDim2.new(1, -8, 0, 24)
RenameBox.Font = Enum.Font.SourceSans
RenameBox.PlaceholderText = "Script name"
RenameBox.Text = ""
RenameBox.TextColor3 = TextColor
RenameBox.TextSize = 15
RenameBox.ClearTextOnFocus = false
RenameBox.ZIndex = 31
RenameBox.Parent = RenameFrame

local RenameConfirm = Instance.new("TextButton")
RenameConfirm.Name = "Confirm"
RenameConfirm.BackgroundColor3 = BackgroundColor
RenameConfirm.BorderSizePixel = 0
RenameConfirm.Position = UDim2.new(0, 4, 0, 32)
RenameConfirm.Size = UDim2.new(1, -8, 0, 23)
RenameConfirm.Font = Enum.Font.SourceSans
RenameConfirm.Text = "Rename"
RenameConfirm.TextColor3 = TextColor
RenameConfirm.TextSize = 15
RenameConfirm.AutoButtonColor = false
RenameConfirm.ZIndex = 31
RenameConfirm.Parent = RenameFrame

-----/Functions/-----
local function UpdateCanvas()
	ScriptsList.CanvasSize = UDim2.new(0, 0, 0, ScriptsLayout.AbsoluteContentSize.Y + 3)
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

	local Name = Data.Name

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

-----/Init/-----
ScriptsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

UpdateCanvas()
RefreshScripts()
