-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ExistingGui = PlayerGui:FindFirstChild("FlingDeluxeUI")
if ExistingGui then
	ExistingGui:Destroy()
end

local Connections = {}
local LoopProtect = nil
local IsFlinging = false
local WalkFlinging = false
local LoopTargeting = false
local LoopTargetingAll = false
local ClickFlingMode = "None"
local IsDragging = false
local DragStart = nil
local StartPosition = nil
local NotifyToken = 0

-----/Assets/-----
local SettingsIcon = "rbxassetid://1204397029"
local ReferenceIcon = "rbxassetid://3523243755"
local MinimizeIcon = "rbxassetid://2406617031"

-----/Values/-----
local Colors = {
	Dark = Color3.fromRGB(36, 36, 37),
	Background = Color3.fromRGB(46, 46, 47),
	Button = Color3.fromRGB(78, 78, 79),
	ButtonHover = Color3.fromRGB(96, 96, 97),
	White = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(180, 180, 180),
	Accent = Color3.fromRGB(200, 55, 55),
}

local DefaultForce = "90000000"

-----/Functions/-----
local function Tween(Object, Time, Properties)
	TweenService:Create(Object, TweenInfo.new(Time), Properties):Play()
end

local function GetHumanoid(Character)
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(Character)
	return Character and (Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso"))
end

local function GetHead(Character)
	return Character and (Character:FindFirstChild("Head") or Character:FindFirstChild("UpperTorso"))
end

local function GetPlayerByName(Search : string)
	Search = Search:lower():gsub("%s+", "")
	if Search == "" then
		return nil
	end
	for _, OtherPlayer in ipairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player then
			local Name = OtherPlayer.Name:lower():gsub("%s+", "")
			local DisplayName = OtherPlayer.DisplayName:lower():gsub("%s+", "")
			if Name:match("^" .. Search) or DisplayName:match("^" .. Search) then
				return OtherPlayer
			end
		end
	end
	return nil
end

local function ShowNotification(Text : string, Duration : number)
	Duration = Duration or 2
	NotifyToken = NotifyToken + 1
	local MyToken = NotifyToken

	local Notification = Instance.new("Frame")
	Notification.Name = "Notification"
	Notification.Size = UDim2.fromOffset(220, 30)
	Notification.Position = UDim2.new(1, -232, 1, -42)
	Notification.BackgroundColor3 = Colors.Background
	Notification.BorderSizePixel = 0
	Notification.BackgroundTransparency = 1
	Notification.Parent = PlayerGui

	local NotificationText = Instance.new("TextLabel")
	NotificationText.Name = "NotificationText"
	NotificationText.Size = UDim2.new(1, -12, 1, 0)
	NotificationText.Position = UDim2.fromOffset(6, 0)
	NotificationText.BackgroundTransparency = 1
	NotificationText.Text = Text
	NotificationText.TextColor3 = Colors.White
	NotificationText.Font = Enum.Font.Code
	NotificationText.TextSize = 14
	NotificationText.TextXAlignment = Enum.TextXAlignment.Left
	NotificationText.TextTransparency = 1
	NotificationText.Parent = Notification

	Tween(Notification, 0.1, {BackgroundTransparency = 0})
	Tween(NotificationText, 0.1, {TextTransparency = 0})

	task.delay(Duration, function()
		if MyToken ~= NotifyToken then
			Notification:Destroy()
			return
		end
		Tween(Notification, 0.1, {BackgroundTransparency = 1})
		Tween(NotificationText, 0.1, {TextTransparency = 1})
		task.wait(0.15)
		Notification:Destroy()
	end)
end

local function CreateSectionTitle(Parent : Instance, Text : string, Order : number)
	local Label = Instance.new("TextLabel")
	Label.Name = Text
	Label.Size = UDim2.new(1, -4, 0, 18)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.Code
	Label.Text = Text
	Label.TextColor3 = Colors.Gray
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.LayoutOrder = Order
	Label.Parent = Parent
	return Label
end

local function CreateToggleRow(Parent : Instance, Text : string, Order : number)
	local Row = Instance.new("Frame")
	Row.Name = Text:gsub("%s+", "")
	Row.Size = UDim2.new(1, -4, 0, 22)
	Row.BackgroundTransparency = 1
	Row.LayoutOrder = Order
	Row.Parent = Parent

	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Name = "ToggleButton"
	ToggleButton.Size = UDim2.new(1, -70, 1, 0)
	ToggleButton.Position = UDim2.fromOffset(0, 0)
	ToggleButton.BackgroundColor3 = Colors.Button
	ToggleButton.BorderSizePixel = 0
	ToggleButton.Font = Enum.Font.Code
	ToggleButton.Text = Text .. ": OFF"
	ToggleButton.TextColor3 = Colors.White
	ToggleButton.TextSize = 13
	ToggleButton.TextXAlignment = Enum.TextXAlignment.Left
	ToggleButton.Parent = Row

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 6)
	Padding.Parent = ToggleButton

	local ValueBox = Instance.new("TextBox")
	ValueBox.Name = "ValueBox"
	ValueBox.Size = UDim2.fromOffset(64, 22)
	ValueBox.Position = UDim2.new(1, -64, 0, 0)
	ValueBox.BackgroundColor3 = Colors.Dark
	ValueBox.BorderSizePixel = 0
	ValueBox.Font = Enum.Font.Code
	ValueBox.Text = DefaultForce
	ValueBox.TextColor3 = Colors.White
	ValueBox.TextSize = 12
	ValueBox.ClearTextOnFocus = false
	ValueBox.Parent = Row

	return Row, ToggleButton, ValueBox
end

local function ApplyFlingForces(MyRoot : BasePart, TargetRoot : BasePart, Force : number)
	local Character = MyRoot.Parent
	for _, Part in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CanCollide = false
		end
	end
	local StartTime = tick()
	while tick() - StartTime < 0.25 do
		RunService.Heartbeat:Wait()
		pcall(function()
			if MyRoot and TargetRoot then
				MyRoot.CFrame = TargetRoot.CFrame
				MyRoot.AssemblyLinearVelocity = Vector3.new(Force, Force * 10, Force)
				MyRoot.AssemblyAngularVelocity = Vector3.new(Force * 10, Force * 10, Force)
			end
		end)
	end
	pcall(function()
		MyRoot.AssemblyLinearVelocity = Vector3.zero
		MyRoot.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function InstantClickFling(MyRoot : BasePart, TargetRoot : BasePart, Force : number)
	pcall(function()
		MyRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 1)
		ApplyFlingForces(MyRoot, TargetRoot, Force)
	end)
end

local function TweenClickFling(MyRoot : BasePart, TargetRoot : BasePart, Force : number)
	pcall(function()
		local Distance = (TargetRoot.Position - MyRoot.Position).Magnitude
		if Distance < 1 then
			Distance = 1
		end
		local TweenInfo = TweenInfo.new(Distance / 120, Enum.EasingStyle.Linear)
		local MoveTween = TweenService:Create(MyRoot, TweenInfo, {CFrame = TargetRoot.CFrame})
		MoveTween:Play()
		MoveTween.Completed:Wait()
		ApplyFlingForces(MyRoot, TargetRoot, Force)
	end)
end

local function StartWalkFlingLoop()
	local Character = Player.Character
	local Humanoid = GetHumanoid(Character)
	if Humanoid then
		local DeathConnection
		DeathConnection = Humanoid.Died:Connect(function()
			WalkFlinging = false
			if DeathConnection then
				DeathConnection:Disconnect()
			end
		end)
	end

	task.spawn(function()
		local Move = 0.1
		while WalkFlinging do
			RunService.Heartbeat:Wait()
			pcall(function()
				local CurrentCharacter = Player.Character
				local Root = GetRoot(CurrentCharacter)
				local Multiplier = tonumber(CurrentCharacter and 0 or 0)
				Multiplier = 90000000
				if CurrentCharacter and Root then
					local Velocity = Root.Velocity
					Root.Velocity = Velocity * Multiplier + Vector3.new(0, Multiplier, 0)
					RunService.RenderStepped:Wait()
					if Root and Root.Parent then
						Root.Velocity = Velocity
					end
					RunService.Stepped:Wait()
					if Root and Root.Parent then
						Root.Velocity = Velocity + Vector3.new(0, Move, 0)
						Move = Move * -1
					end
				end
			end)
		end
	end)
end

local function StartAntiFling(ConnectionTable : table)
	if ConnectionTable[1] then
		ConnectionTable[1]:Disconnect()
		ConnectionTable[1] = nil
	end
	ConnectionTable[1] = RunService.Stepped:Connect(function()
		pcall(function()
			for _, OtherPlayer in pairs(Players:GetPlayers()) do
				if OtherPlayer ~= Player and OtherPlayer.Character then
					for _, Part in pairs(OtherPlayer.Character:GetDescendants()) do
						if Part:IsA("BasePart") then
							Part.CanCollide = false
						end
					end
				end
			end
		end)
	end)
end

local function StopAntiFling(ConnectionTable : table)
	if ConnectionTable[1] then
		ConnectionTable[1]:Disconnect()
		ConnectionTable[1] = nil
	end
end

-----/Main/-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlingDeluxeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ParentSuccess = pcall(function()
	if gethui then
		ScreenGui.Parent = gethui()
	else
		ScreenGui.Parent = PlayerGui
	end
end)

if not ParentSuccess or not ScreenGui.Parent then
	ScreenGui.Parent = PlayerGui
end

local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = UDim2.fromOffset(270, 340)
Holder.Position = UDim2.new(0, 20, 0.5, -170)
Holder.BackgroundColor3 = Colors.Background
Holder.BorderSizePixel = 0
Holder.Parent = ScreenGui

local Title = Instance.new("Frame")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 24)
Title.BackgroundColor3 = Colors.Dark
Title.BorderSizePixel = 0
Title.Parent = Holder

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Position = UDim2.fromOffset(8, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.SourceSans
TitleText.Text = "FLING DELUXE"
TitleText.TextColor3 = Colors.White
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Title

local function CreateTitleIcon(Icon : string, OffsetOrder : number)
	local Button = Instance.new("TextButton")
	Button.Name = "TitleIcon"
	Button.Size = UDim2.fromOffset(22, 22)
	Button.Position = UDim2.new(1, -26 * OffsetOrder, 0, 1)
	Button.BackgroundTransparency = 1
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.Parent = Title

	local Image = Instance.new("ImageLabel")
	Image.Name = "Icon"
	Image.Size = UDim2.fromOffset(16, 16)
	Image.Position = UDim2.fromOffset(3, 3)
	Image.BackgroundTransparency = 1
	Image.Image = Icon
	Image.ImageColor3 = Colors.Gray
	Image.Parent = Button

	Button.MouseEnter:Connect(function()
		Tween(Image, 0.1, {ImageColor3 = Colors.White})
	end)

	Button.MouseLeave:Connect(function()
		Tween(Image, 0.1, {ImageColor3 = Colors.Gray})
	end)

	return Button, Image
end

local ReferenceButton = CreateTitleIcon(ReferenceIcon, 3)
local MinimizeButton = CreateTitleIcon(MinimizeIcon, 2)

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(22, 22)
CloseButton.Position = UDim2.new(1, -26, 0, 1)
CloseButton.BackgroundTransparency = 1
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.Code
CloseButton.Text = "X"
CloseButton.TextColor3 = Colors.Gray
CloseButton.TextSize = 14
CloseButton.AutoButtonColor = false
CloseButton.Parent = Title

CloseButton.MouseEnter:Connect(function()
	Tween(CloseButton, 0.1, {TextColor3 = Colors.White})
end)

CloseButton.MouseLeave:Connect(function()
	Tween(CloseButton, 0.1, {TextColor3 = Colors.Gray})
end)

local Commands = Instance.new("ScrollingFrame")
Commands.Name = "Commands"
Commands.Size = UDim2.new(1, -16, 1, -32)
Commands.Position = UDim2.fromOffset(8, 28)
Commands.BackgroundTransparency = 1
Commands.BorderSizePixel = 0
Commands.ScrollBarThickness = 6
Commands.ScrollBarImageColor3 = Colors.Button
Commands.CanvasSize = UDim2.new(0, 0, 0, 0)
Commands.AutomaticCanvasSize = Enum.AutomaticSize.Y
Commands.Parent = Holder

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 2)
ListLayout.Parent = Commands

CreateSectionTitle(Commands, "CLICK FLING", 1)
local InstantRow, InstantButton, InstantBox = CreateToggleRow(Commands, "Instant Click Fling", 2)
local TweenRow, TweenButton, TweenBox = CreateToggleRow(Commands, "Tween Click Fling", 3)

CreateSectionTitle(Commands, "WALK FLING", 4)
local WalkRow, WalkButton, WalkBox = CreateToggleRow(Commands, "Walk Fling", 5)

CreateSectionTitle(Commands, "LOOP TARGET FLING", 6)

local TargetRow = Instance.new("Frame")
TargetRow.Name = "TargetRow"
TargetRow.Size = UDim2.new(1, -4, 0, 22)
TargetRow.BackgroundTransparency = 1
TargetRow.LayoutOrder = 7
TargetRow.Parent = Commands

local TargetBox = Instance.new("TextBox")
TargetBox.Name = "TargetBox"
TargetBox.Size = UDim2.new(1, 0, 1, 0)
TargetBox.BackgroundColor3 = Colors.Dark
TargetBox.BorderSizePixel = 0
TargetBox.Font = Enum.Font.Code
TargetBox.PlaceholderColor3 = Colors.Gray
TargetBox.PlaceholderText = "Target Username..."
TargetBox.Text = ""
TargetBox.TextColor3 = Colors.White
TargetBox.TextSize = 13
TargetBox.TextXAlignment = Enum.TextXAlignment.Left
TargetBox.ClearTextOnFocus = false
TargetBox.Parent = TargetRow

local TargetPadding = Instance.new("UIPadding")
TargetPadding.PaddingLeft = UDim.new(0, 6)
TargetPadding.Parent = TargetBox

local LoopRow, LoopButton, LoopBox = CreateToggleRow(Commands, "Loop Target", 8)
local LoopAllRow, LoopAllButton, LoopAllBox = CreateToggleRow(Commands, "Loop Target All", 9)

CreateSectionTitle(Commands, "ANTI-FLING", 10)

local AntiRow = Instance.new("Frame")
AntiRow.Name = "AntiRow"
AntiRow.Size = UDim2.new(1, -4, 0, 22)
AntiRow.BackgroundTransparency = 1
AntiRow.LayoutOrder = 11
AntiRow.Parent = Commands

local AntiButton = Instance.new("TextButton")
AntiButton.Name = "AntiButton"
AntiButton.Size = UDim2.new(1, 0, 1, 0)
AntiButton.BackgroundColor3 = Colors.Button
AntiButton.BorderSizePixel = 0
AntiButton.Font = Enum.Font.Code
AntiButton.Text = "Anti-Fling: OFF"
AntiButton.TextColor3 = Colors.White
AntiButton.TextSize = 13
AntiButton.TextXAlignment = Enum.TextXAlignment.Left
AntiButton.AutoButtonColor = false
AntiButton.Parent = AntiRow

local AntiPadding = Instance.new("UIPadding")
AntiPadding.PaddingLeft = UDim.new(0, 6)
AntiPadding.Parent = AntiButton

local function BindToggle(Button : TextButton, BaseText : string)
	local State = false
	local function Update()
		if State then
			Button.Text = BaseText .. ": ON"
			Button.BackgroundColor3 = Colors.Accent
		else
			Button.Text = BaseText .. ": OFF"
			Button.BackgroundColor3 = Colors.Button
		end
	end
	Button.MouseEnter:Connect(function()
		if not State then
			Tween(Button, 0.1, {BackgroundColor3 = Colors.ButtonHover})
		end
	end)
	Button.MouseLeave:Connect(function()
		if not State then
			Tween(Button, 0.1, {BackgroundColor3 = Colors.Button})
		end
	end)
	return function(Value : boolean)
		State = Value
		Update()
	end, function()
		return State
	end
end

local SetInstant, GetInstant = BindToggle(InstantButton, "Instant Click Fling")
local SetTween, GetTween = BindToggle(TweenButton, "Tween Click Fling")
local SetWalk, GetWalk = BindToggle(WalkButton, "Walk Fling")
local SetLoop, GetLoop = BindToggle(LoopButton, "Loop Target")
local SetLoopAll, GetLoopAll = BindToggle(LoopAllButton, "Loop Target All")
local SetAnti, GetAnti = BindToggle(AntiButton, "Anti-Fling")

local AntiConnections = {}

table.insert(Connections, InstantButton.MouseButton1Click:Connect(function()
	if ClickFlingMode == "Instant" then
		ClickFlingMode = "None"
		SetInstant(false)
	else
		ClickFlingMode = "Instant"
		SetInstant(true)
		SetTween(false)
	end
end))

table.insert(Connections, TweenButton.MouseButton1Click:Connect(function()
	if ClickFlingMode == "Tween" then
		ClickFlingMode = "None"
		SetTween(false)
	else
		ClickFlingMode = "Tween"
		SetTween(true)
		SetInstant(false)
	end
end))

table.insert(Connections, WalkButton.MouseButton1Click:Connect(function()
	if GetWalk() then
		WalkFlinging = false
		SetWalk(false)
	else
		WalkFlinging = true
		SetWalk(true)
		StartWalkFlingLoop()
	end
end))

table.insert(Connections, AntiButton.MouseButton1Click:Connect(function()
	if GetAnti() then
		StopAntiFling(AntiConnections)
		SetAnti(false)
	else
		StartAntiFling(AntiConnections)
		SetAnti(true)
	end
end))

local CurrentLoopThread = nil
local CurrentLoopAllThread = nil

local function RunLoopTarget(TargetName : string, Force : number)
	task.spawn(function()
		local TargetPlayer = GetPlayerByName(TargetName)
		if not TargetPlayer then
			return
		end
		local MyCharacter = Player.Character
		local MyRoot = GetRoot(MyCharacter)
		local TargetCharacter = TargetPlayer.Character
		local TargetRoot = GetRoot(TargetCharacter)
		if not MyRoot or not TargetRoot then
			return
		end
		while LoopTargeting and TargetPlayer.Parent and TargetPlayer.Character == TargetCharacter do
			if TargetRoot.Parent then
				pcall(function()
					MyRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 1)
					MyRoot.AssemblyLinearVelocity = Vector3.new(Force, Force * 10, Force)
					MyRoot.AssemblyAngularVelocity = Vector3.new(Force * 10, Force * 10, Force)
				end)
			end
			task.wait(0.05)
		end
	end)
end

local function RunLoopTargetAll(Force : number)
	task.spawn(function()
		while LoopTargetingAll do
			for _, OtherPlayer in ipairs(Players:GetPlayers()) do
				if not LoopTargetingAll then
					break
				end
				if OtherPlayer ~= Player and OtherPlayer.Character then
					local MyCharacter = Player.Character
					local MyRoot = GetRoot(MyCharacter)
					local TargetRoot = GetRoot(OtherPlayer.Character)
					if MyRoot and TargetRoot then
						pcall(function()
							MyRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 1)
							MyRoot.AssemblyLinearVelocity = Vector3.new(Force, Force * 10, Force)
							MyRoot.AssemblyAngularVelocity = Vector3.new(Force * 10, Force * 10, Force)
						end)
					end
					task.wait(0.05)
				end
			end
			task.wait(0.1)
		end
	end)
end

table.insert(Connections, LoopButton.MouseButton1Click:Connect(function()
	if GetLoop() then
		LoopTargeting = false
		SetLoop(false)
	else
		local TargetName = TargetBox.Text
		if TargetName == "" then
			ShowNotification("Loop Target | No target set", 2)
			return
		end
		LoopTargeting = true
		LoopTargetingAll = false
		SetLoopAll(false)
		SetLoop(true)
		RunLoopTarget(TargetName, tonumber(LoopBox.Text) or 90000000)
	end
end))

table.insert(Connections, LoopAllButton.MouseButton1Click:Connect(function()
	if GetLoopAll() then
		LoopTargetingAll = false
		SetLoopAll(false)
	else
		LoopTargetingAll = true
		LoopTargeting = false
		SetLoop(false)
		SetLoopAll(true)
		RunLoopTargetAll(tonumber(LoopAllBox.Text) or 90000000)
	end
end))

table.insert(Connections, CloseButton.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
	for _, Connection in ipairs(Connections) do
		Connection:Disconnect()
	end
	table.clear(Connections)
end))

table.insert(Connections, ReferenceButton.MouseButton1Click:Connect(function()
	ShowNotification("Fling Deluxe | by MaxproGlitcher", 3)
end))

table.insert(Connections, MinimizeButton.MouseButton1Click:Connect(function()
	local Minimized = Commands.Visible
	Commands.Visible = not Minimized
	if Minimized then
		Holder.Size = UDim2.fromOffset(270, 24)
	else
		Holder.Size = UDim2.fromOffset(270, 340)
	end
end))

table.insert(Connections, Title.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		IsDragging = true
		DragStart = Input.Position
		StartPosition = Holder.Position
	end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
	if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
		local Delta = Input.Position - DragStart
		Holder.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		IsDragging = false
	end
end))

table.insert(Connections, UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then
		return
	end
	if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if ClickFlingMode == "None" or IsFlinging then
		return
	end

	local MouseLocation = UserInputService:GetMouseLocation()
	local HolderPosition = Holder.AbsolutePosition
	local HolderSize = Holder.AbsoluteSize
	if MouseLocation.X >= HolderPosition.X and MouseLocation.X <= HolderPosition.X + HolderSize.X
		and MouseLocation.Y >= HolderPosition.Y and MouseLocation.Y <= HolderPosition.Y + HolderSize.Y then
		return
	end

	local Camera = workspace.CurrentCamera
	local Ray = Camera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Player.Character}
	local Result = workspace:Raycast(Ray.Origin, Ray.Direction * 1000, Params)
	if not Result then
		return
	end
	local TargetInstance = Result.Instance
	local TargetCharacter = TargetInstance:FindFirstAncestorWhichIsA("Model")
	if not TargetCharacter then
		return
	end
	local TargetPlayer = Players:GetPlayerFromCharacter(TargetCharacter)
	if not TargetPlayer or TargetPlayer == Player then
		return
	end

	local MyCharacter = Player.Character
	local MyRoot = GetRoot(MyCharacter)
	local MyHumanoid = GetHumanoid(MyCharacter)
	local TargetRoot = GetRoot(TargetPlayer.Character)
	if not MyRoot or not MyHumanoid or not TargetRoot then
		return
	end

	IsFlinging = true
	local OldCFrame = MyRoot.CFrame
	local Force = 90000000
	if ClickFlingMode == "Instant" then
		Force = tonumber(InstantBox.Text) or 90000000
		InstantClickFling(MyRoot, TargetRoot, Force)
	elseif ClickFlingMode == "Tween" then
		Force = tonumber(TweenBox.Text) or 90000000
		TweenClickFling(MyRoot, TargetRoot, Force)
	end

	MyRoot.CFrame = OldCFrame
	MyRoot.AssemblyLinearVelocity = Vector3.zero
	MyRoot.AssemblyAngularVelocity = Vector3.zero

	for _, Part in ipairs(MyCharacter:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CanCollide = true
		end
	end

	IsFlinging = false
end))

-----/Init/-----
print("Fling Deluxe | UI loaded")
