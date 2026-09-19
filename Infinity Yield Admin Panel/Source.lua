-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Character = nil
local Humanoid = nil
local RootPart = nil

local NoclipConnection = nil
local FlyConnection = nil
local FlyVelocity = nil

local Holder = nil
local Content = nil
local MinimizeButton = nil
local NoclipButton = nil
local NoclipStateLabel = nil
local FlyButton = nil
local FlyStateLabel = nil

-----/Assets/-----
local MinimizeIcon = "rbxassetid://2406617031"

-----/Values/-----
local Colors = {
	Dark = Color3.fromRGB(36, 36, 37),
	Background = Color3.fromRGB(46, 46, 47),
	Button = Color3.fromRGB(78, 78, 79),
	ButtonHover = Color3.fromRGB(92, 92, 93),
	ButtonActive = Color3.fromRGB(72, 110, 72),
	ActiveText = Color3.fromRGB(180, 255, 180),
	White = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(180, 180, 180),
}

local State = {
	Noclip = false,
	Fly = false,
	FlySpeed = 60,
	WalkSpeed = 16,
	JumpPower = 50,
	JumpHeight = 7.2,
	UseJumpPower = true,
}

local WindowSize = UDim2.fromOffset(240, 206)
local MinimizedSize = UDim2.fromOffset(240, 26)

-----/Functions/-----
local function SetNoclipState(Value : boolean)
	State.Noclip = Value

	if Value then
		NoclipConnection = RunService.Stepped:Connect(function()
			if not Character then
				return
			end

			for _, Part in ipairs(Character:GetDescendants()) do
				if Part:IsA("BasePart") and Part.CanCollide then
					Part.CanCollide = false
				end
			end
		end)
	else
		if NoclipConnection then
			NoclipConnection:Disconnect()
			NoclipConnection = nil
		end
	end

	NoclipButton.BackgroundColor3 = Value and Colors.ButtonActive or Colors.Button
	NoclipStateLabel.Text = Value and "ON" or "OFF"
	NoclipStateLabel.TextColor3 = Value and Colors.ActiveText or Colors.Gray
end

local function SetFlyState(Value : boolean)
	State.Fly = Value

	if Value then
		if not RootPart or not RootPart.Parent then
			State.Fly = false
			return
		end

		FlyVelocity = Instance.new("BodyVelocity")
		FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		FlyVelocity.Velocity = Vector3.zero
		FlyVelocity.Parent = RootPart

		FlyConnection = RunService.RenderStepped:Connect(function()
			if not FlyVelocity or not FlyVelocity.Parent then
				return
			end

			local Camera = workspace.CurrentCamera

			if not Camera then
				return
			end

			local Direction = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				Direction = Direction + Camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				Direction = Direction - Camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				Direction = Direction - Camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				Direction = Direction + Camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				Direction = Direction + Vector3.yAxis
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				Direction = Direction - Vector3.yAxis
			end

			if Direction.Magnitude > 0 then
				Direction = Direction.Unit
			end

			FlyVelocity.Velocity = Direction * State.FlySpeed
		end)
	else
		if FlyConnection then
			FlyConnection:Disconnect()
			FlyConnection = nil
		end

		if FlyVelocity then
			FlyVelocity:Destroy()
			FlyVelocity = nil
		end
	end

	FlyButton.BackgroundColor3 = Value and Colors.ButtonActive or Colors.Button
	FlyStateLabel.Text = Value and "ON" or "OFF"
	FlyStateLabel.TextColor3 = Value and Colors.ActiveText or Colors.Gray
end

local function FlingOthers()
	for _, OtherPlayer in ipairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player and OtherPlayer.Character then
			local OtherRoot = OtherPlayer.Character:FindFirstChild("HumanoidRootPart")

			if OtherRoot then
				local Angular = Instance.new("BodyAngularVelocity")
				Angular.AngularVelocity = Vector3.new(
					math.random(-1500, 1500),
					math.random(-1500, 1500),
					math.random(-1500, 1500)
				)
				Angular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				Angular.P = math.huge
				Angular.Parent = OtherRoot

				task.delay(0.15, function()
					if Angular and Angular.Parent then
						Angular:Destroy()
					end
				end)
			end
		end
	end
end

local function ApplyWalkSpeed(Value : string)
	local Speed = tonumber(Value)

	if not Speed or Speed <= 0 then
		return
	end

	State.WalkSpeed = Speed

	if Humanoid then
		Humanoid.WalkSpeed = Speed
	end
end

local function ApplyJump(Value : string)
	local Jump = tonumber(Value)

	if not Jump or Jump <= 0 then
		return
	end

	if State.UseJumpPower then
		State.JumpPower = Jump

		if Humanoid then
			Humanoid.UseJumpPower = true
			Humanoid.JumpPower = Jump
		end
	else
		State.JumpHeight = Jump

		if Humanoid then
			Humanoid.UseJumpPower = false
			Humanoid.JumpHeight = Jump
		end
	end
end

local function SetupCharacter(NewCharacter : Model)
	Character = NewCharacter
	Humanoid = NewCharacter:WaitForChild("Humanoid")
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")

	Humanoid.WalkSpeed = State.WalkSpeed
	Humanoid.UseJumpPower = State.UseJumpPower

	if State.UseJumpPower then
		Humanoid.JumpPower = State.JumpPower
	else
		Humanoid.JumpHeight = State.JumpHeight
	end

	if State.Fly then
		SetFlyState(false)
	end
end

local function HookDrag(Frame : GuiObject, DragArea : GuiObject)
	local Dragging = false
	local DragStart = nil
	local StartPos = nil
	local DragInput = nil

	DragArea.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPos = Frame.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	DragArea.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			DragInput = Input
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - DragStart

			Frame.Position = UDim2.new(
				StartPos.X.Scale,
				StartPos.X.Offset + Delta.X,
				StartPos.Y.Scale,
				StartPos.Y.Offset + Delta.Y
			)
		end
	end)
end

local function HookHover(Button : GuiObject, GetActive : (() -> boolean)?)
	Button.MouseEnter:Connect(function()
		if GetActive and GetActive() then
			return
		end

		TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Colors.ButtonHover}):Play()
	end)

	Button.MouseLeave:Connect(function()
		if GetActive and GetActive() then
			return
		end

		TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Button}):Play()
	end)
end

-----/Main/-----
local Existing = PlayerGui:FindFirstChild("AdminPanel")

if Existing then
	Existing:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdminPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = WindowSize
Holder.Position = UDim2.fromOffset(20, 20)
Holder.BackgroundColor3 = Colors.Background
Holder.BorderSizePixel = 0
Holder.Active = true
Holder.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 26)
TitleBar.BackgroundColor3 = Colors.Dark
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Holder

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.fromOffset(8, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.Code
TitleLabel.Text = "Admin Panel"
TitleLabel.TextColor3 = Colors.White
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

MinimizeButton = Instance.new("ImageButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.fromOffset(16, 16)
MinimizeButton.Position = UDim2.new(1, -22, 0, 5)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Image = MinimizeIcon
MinimizeButton.ImageColor3 = Colors.White
MinimizeButton.ImageTransparency = 0.4
MinimizeButton.Parent = TitleBar

Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -26)
Content.Position = UDim2.fromOffset(0, 26)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Holder

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 8)
ContentPadding.PaddingBottom = UDim.new(0, 8)
ContentPadding.PaddingLeft = UDim.new(0, 8)
ContentPadding.PaddingRight = UDim.new(0, 8)
ContentPadding.Parent = Content

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

local MovementLabel = Instance.new("TextLabel")
MovementLabel.Name = "MovementLabel"
MovementLabel.Size = UDim2.new(1, 0, 0, 14)
MovementLabel.BackgroundTransparency = 1
MovementLabel.Font = Enum.Font.Code
MovementLabel.Text = "MOVEMENT"
MovementLabel.TextColor3 = Colors.Gray
MovementLabel.TextSize = 11
MovementLabel.TextXAlignment = Enum.TextXAlignment.Left
MovementLabel.LayoutOrder = 1
MovementLabel.Parent = Content

local WalkRow = Instance.new("Frame")
WalkRow.Name = "WalkRow"
WalkRow.Size = UDim2.new(1, 0, 0, 22)
WalkRow.BackgroundTransparency = 1
WalkRow.LayoutOrder = 2
WalkRow.Parent = Content

local WalkLabel = Instance.new("TextLabel")
WalkLabel.Name = "Label"
WalkLabel.Size = UDim2.new(0, 70, 1, 0)
WalkLabel.BackgroundTransparency = 1
WalkLabel.Font = Enum.Font.Code
WalkLabel.Text = "WalkSpeed"
WalkLabel.TextColor3 = Colors.White
WalkLabel.TextSize = 14
WalkLabel.TextXAlignment = Enum.TextXAlignment.Left
WalkLabel.Parent = WalkRow

local WalkInput = Instance.new("TextBox")
WalkInput.Name = "Input"
WalkInput.Size = UDim2.new(1, -70, 1, 0)
WalkInput.Position = UDim2.fromOffset(70, 0)
WalkInput.BackgroundColor3 = Colors.Button
WalkInput.BorderSizePixel = 0
WalkInput.Font = Enum.Font.Code
WalkInput.Text = "16"
WalkInput.TextColor3 = Colors.White
WalkInput.TextSize = 14
WalkInput.TextXAlignment = Enum.TextXAlignment.Left
WalkInput.ClearTextOnFocus = false
WalkInput.Parent = WalkRow

local WalkInputPadding = Instance.new("UIPadding")
WalkInputPadding.PaddingLeft = UDim.new(0, 6)
WalkInputPadding.PaddingRight = UDim.new(0, 6)
WalkInputPadding.Parent = WalkInput

local JumpRow = Instance.new("Frame")
JumpRow.Name = "JumpRow"
JumpRow.Size = UDim2.new(1, 0, 0, 22)
JumpRow.BackgroundTransparency = 1
JumpRow.LayoutOrder = 3
JumpRow.Parent = Content

local JumpLabel = Instance.new("TextLabel")
JumpLabel.Name = "Label"
JumpLabel.Size = UDim2.new(0, 70, 1, 0)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Font = Enum.Font.Code
JumpLabel.Text = "Jump"
JumpLabel.TextColor3 = Colors.White
JumpLabel.TextSize = 14
JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
JumpLabel.Parent = JumpRow

local JumpInput = Instance.new("TextBox")
JumpInput.Name = "Input"
JumpInput.Size = UDim2.new(1, -130, 1, 0)
JumpInput.Position = UDim2.fromOffset(70, 0)
JumpInput.BackgroundColor3 = Colors.Button
JumpInput.BorderSizePixel = 0
JumpInput.Font = Enum.Font.Code
JumpInput.Text = "50"
JumpInput.TextColor3 = Colors.White
JumpInput.TextSize = 14
JumpInput.TextXAlignment = Enum.TextXAlignment.Left
JumpInput.ClearTextOnFocus = false
JumpInput.Parent = JumpRow

local JumpInputPadding = Instance.new("UIPadding")
JumpInputPadding.PaddingLeft = UDim.new(0, 6)
JumpInputPadding.PaddingRight = UDim.new(0, 6)
JumpInputPadding.Parent = JumpInput

local JumpModeButton = Instance.new("TextButton")
JumpModeButton.Name = "ModeButton"
JumpModeButton.Size = UDim2.new(0, 54, 1, 0)
JumpModeButton.Position = UDim2.new(1, -54, 0, 0)
JumpModeButton.BackgroundColor3 = Colors.Button
JumpModeButton.BorderSizePixel = 0
JumpModeButton.Font = Enum.Font.Code
JumpModeButton.Text = "PWR"
JumpModeButton.TextColor3 = Colors.White
JumpModeButton.TextSize = 13
JumpModeButton.AutoButtonColor = false
JumpModeButton.Parent = JumpRow

local UtilityLabel = Instance.new("TextLabel")
UtilityLabel.Name = "UtilityLabel"
UtilityLabel.Size = UDim2.new(1, 0, 0, 14)
UtilityLabel.BackgroundTransparency = 1
UtilityLabel.Font = Enum.Font.Code
UtilityLabel.Text = "UTILITY"
UtilityLabel.TextColor3 = Colors.Gray
UtilityLabel.TextSize = 11
UtilityLabel.TextXAlignment = Enum.TextXAlignment.Left
UtilityLabel.LayoutOrder = 4
UtilityLabel.Parent = Content

NoclipButton = Instance.new("TextButton")
NoclipButton.Name = "NoclipButton"
NoclipButton.Size = UDim2.new(1, 0, 0, 22)
NoclipButton.BackgroundColor3 = Colors.Button
NoclipButton.BorderSizePixel = 0
NoclipButton.Font = Enum.Font.Code
NoclipButton.Text = "Noclip"
NoclipButton.TextColor3 = Colors.White
NoclipButton.TextSize = 14
NoclipButton.TextXAlignment = Enum.TextXAlignment.Left
NoclipButton.AutoButtonColor = false
NoclipButton.LayoutOrder = 5
NoclipButton.Parent = Content

local NoclipPadding = Instance.new("UIPadding")
NoclipPadding.PaddingLeft = UDim.new(0, 8)
NoclipPadding.PaddingRight = UDim.new(0, 8)
NoclipPadding.Parent = NoclipButton

NoclipStateLabel = Instance.new("TextLabel")
NoclipStateLabel.Name = "StateLabel"
NoclipStateLabel.Size = UDim2.new(0, 40, 1, 0)
NoclipStateLabel.Position = UDim2.new(1, -40, 0, 0)
NoclipStateLabel.BackgroundTransparency = 1
NoclipStateLabel.Font = Enum.Font.Code
NoclipStateLabel.Text = "OFF"
NoclipStateLabel.TextColor3 = Colors.Gray
NoclipStateLabel.TextSize = 14
NoclipStateLabel.TextXAlignment = Enum.TextXAlignment.Right
NoclipStateLabel.Parent = NoclipButton

FlyButton = Instance.new("TextButton")
FlyButton.Name = "FlyButton"
FlyButton.Size = UDim2.new(1, 0, 0, 22)
FlyButton.BackgroundColor3 = Colors.Button
FlyButton.BorderSizePixel = 0
FlyButton.Font = Enum.Font.Code
FlyButton.Text = "Fly"
FlyButton.TextColor3 = Colors.White
FlyButton.TextSize = 14
FlyButton.TextXAlignment = Enum.TextXAlignment.Left
FlyButton.AutoButtonColor = false
FlyButton.LayoutOrder = 6
FlyButton.Parent = Content

local FlyPadding = Instance.new("UIPadding")
FlyPadding.PaddingLeft = UDim.new(0, 8)
FlyPadding.PaddingRight = UDim.new(0, 8)
FlyPadding.Parent = FlyButton

FlyStateLabel = Instance.new("TextLabel")
FlyStateLabel.Name = "StateLabel"
FlyStateLabel.Size = UDim2.new(0, 40, 1, 0)
FlyStateLabel.Position = UDim2.new(1, -40, 0, 0)
FlyStateLabel.BackgroundTransparency = 1
FlyStateLabel.Font = Enum.Font.Code
FlyStateLabel.Text = "OFF"
FlyStateLabel.TextColor3 = Colors.Gray
FlyStateLabel.TextSize = 14
FlyStateLabel.TextXAlignment = Enum.TextXAlignment.Right
FlyStateLabel.Parent = FlyButton

local FlingButton = Instance.new("TextButton")
FlingButton.Name = "FlingButton"
FlingButton.Size = UDim2.new(1, 0, 0, 22)
FlingButton.BackgroundColor3 = Colors.Button
FlingButton.BorderSizePixel = 0
FlingButton.Font = Enum.Font.Code
FlingButton.Text = "Fling Others"
FlingButton.TextColor3 = Colors.White
FlingButton.TextSize = 14
FlingButton.TextXAlignment = Enum.TextXAlignment.Left
FlingButton.AutoButtonColor = false
FlingButton.LayoutOrder = 7
FlingButton.Parent = Content

local FlingPadding = Instance.new("UIPadding")
FlingPadding.PaddingLeft = UDim.new(0, 8)
FlingPadding.PaddingRight = UDim.new(0, 8)
FlingPadding.Parent = FlingButton

HookDrag(Holder, TitleBar)

HookHover(NoclipButton, function()
	return State.Noclip
end)

HookHover(FlyButton, function()
	return State.Fly
end)

HookHover(FlingButton, nil)
HookHover(JumpModeButton, nil)

WalkInput.Focused:Connect(function()
	TweenService:Create(WalkInput, TweenInfo.new(0.1), {BackgroundColor3 = Colors.ButtonHover}):Play()
end)

WalkInput.FocusLost:Connect(function()
	TweenService:Create(WalkInput, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Button}):Play()
	ApplyWalkSpeed(WalkInput.Text)
end)

JumpInput.Focused:Connect(function()
	TweenService:Create(JumpInput, TweenInfo.new(0.1), {BackgroundColor3 = Colors.ButtonHover}):Play()
end)

JumpInput.FocusLost:Connect(function()
	TweenService:Create(JumpInput, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Button}):Play()
	ApplyJump(JumpInput.Text)
end)

JumpModeButton.MouseButton1Click:Connect(function()
	State.UseJumpPower = not State.UseJumpPower
	JumpModeButton.Text = State.UseJumpPower and "PWR" or "HGT"
	JumpInput.Text = State.UseJumpPower and tostring(State.JumpPower) or tostring(State.JumpHeight)

	if Humanoid then
		Humanoid.UseJumpPower = State.UseJumpPower

		if State.UseJumpPower then
			Humanoid.JumpPower = State.JumpPower
		else
			Humanoid.JumpHeight = State.JumpHeight
		end
	end
end)

NoclipButton.MouseButton1Click:Connect(function()
	SetNoclipState(not State.Noclip)
end)

FlyButton.MouseButton1Click:Connect(function()
	SetFlyState(not State.Fly)
end)

FlingButton.MouseButton1Click:Connect(function()
	FlingOthers()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	if Content.Visible then
		Content.Visible = false
		Holder.Size = MinimizedSize
	else
		Content.Visible = true
		Holder.Size = WindowSize
	end
end)

-----/Init/-----
SetupCharacter(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(SetupCharacter)

print("Admin Panel | Loaded")
