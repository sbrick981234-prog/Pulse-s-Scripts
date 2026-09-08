local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Larp%20UI/Source.lua"))()

-----/Services/-----
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

-----/Variables/-----
local Player = Players.LocalPlayer

local FlyConnection
local NoclipConnection
local InfiniteJumpConnection

local FlyEnabled = false
local NoclipEnabled = false
local InfiniteJumpEnabled = false

local FlySpeed = 50
local WalkSpeed = 16
local JumpPower = 50
local Gravity = workspace.Gravity

local OriginalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient
}

-----/Functions/-----

local function GetCharacter()
	return Player.Character
end

local function GetHumanoid()
	local Character = GetCharacter()

	if not Character then
		return nil
	end

	return Character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
	local Character = GetCharacter()

	if not Character then
		return nil
	end

	return Character:FindFirstChild("HumanoidRootPart")
end

local function StopFly()
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end

	local RootPart = GetRootPart()

	if RootPart then
		RootPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function StartFly()
	StopFly()

	FlyConnection = RunService.RenderStepped:Connect(function()
		local RootPart = GetRootPart()

		if not RootPart then
			return
		end

		local Camera = workspace.CurrentCamera

		if not Camera then
			return
		end

		local Direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			Direction += Camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			Direction -= Camera.CFrame.LookVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			Direction -= Camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			Direction += Camera.CFrame.RightVector
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			Direction += Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			Direction -= Vector3.yAxis
		end

		if Direction.Magnitude > 0 then
			Direction = Direction.Unit
		end

		RootPart.AssemblyLinearVelocity = Direction * FlySpeed
	end)
end

local function StopNoclip()
	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end

	local Character = GetCharacter()

	if not Character then
		return
	end

	for _, Part in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CanCollide = true
		end
	end
end

local function StartNoclip()
	StopNoclip()

	NoclipConnection = RunService.Stepped:Connect(function()
		local Character = GetCharacter()

		if not Character then
			return
		end

		for _, Part in ipairs(Character:GetDescendants()) do
			if Part:IsA("BasePart") then
				Part.CanCollide = false
			end
		end
	end)
end

local function StopInfiniteJump()
	if InfiniteJumpConnection then
		InfiniteJumpConnection:Disconnect()
		InfiniteJumpConnection = nil
	end
end

local function StartInfiniteJump()
	StopInfiniteJump()

	InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
		local Humanoid = GetHumanoid()

		if Humanoid then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

local function SetWalkSpeed(Value)
	WalkSpeed = Value

	local Humanoid = GetHumanoid()

	if Humanoid then
		Humanoid.WalkSpeed = Value
	end
end

local function SetJumpPower(Value)
	JumpPower = Value

	local Humanoid = GetHumanoid()

	if Humanoid then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = Value
	end
end

local function SetGravity(Value)
	Gravity = Value
	workspace.Gravity = Value
end

local function ResetCharacter()
	local Character = GetCharacter()
	local Humanoid = GetHumanoid()

	if Character and Humanoid then
		Humanoid.Health = 0
	end
end

-----/Window/-----

local Window = UILib:CreateWindow("Vanta")

-----/Player/-----

local PlayerTab = Window:CreateTab("Player")

PlayerTab:CreateLabel("Movement")

PlayerTab:CreateSlider({
	Text = "WalkSpeed",
	Min = 0,
	Max = 250,
	Default = 16,

	Callback = function(Value)
		SetWalkSpeed(Value)
	end
})

PlayerTab:CreateSlider({
	Text = "JumpPower",
	Min = 0,
	Max = 250,
	Default = 50,

	Callback = function(Value)
		SetJumpPower(Value)
	end
})

PlayerTab:CreateSlider({
	Text = "Gravity",
	Min = 0,
	Max = 300,
	Default = 196,

	Callback = function(Value)
		SetGravity(Value)
	end
})

PlayerTab:CreateSlider({
	Text = "Fly Speed",
	Min = 1,
	Max = 250,
	Default = 50,

	Callback = function(Value)
		FlySpeed = Value
	end
})

PlayerTab:CreateToggle({
	Text = "Fly",
	Default = false,

	Callback = function(State)
		FlyEnabled = State

		if State then
			StartFly()
		else
			StopFly()
		end
	end
})

PlayerTab:CreateToggle({
	Text = "Noclip",
	Default = false,

	Callback = function(State)
		NoclipEnabled = State

		if State then
			StartNoclip()
		else
			StopNoclip()
		end
	end
})

PlayerTab:CreateToggle({
	Text = "Infinite Jump",
	Default = false,

	Callback = function(State)
		InfiniteJumpEnabled = State

		if State then
			StartInfiniteJump()
		else
			StopInfiniteJump()
		end
	end
})

PlayerTab:CreateButton({
	Text = "Reset Character",

	Callback = function()
		ResetCharacter()
	end
})

PlayerTab:CreateButton({
	Text = "Sit",

	Callback = function()
		local Humanoid = GetHumanoid()

		if Humanoid then
			Humanoid.Sit = true
		end
	end
})

-----/Visuals/-----

local Visuals = Window:CreateTab("Visuals")

Visuals:CreateLabel("Player ESP")

Visuals:CreateToggle({
	Text = "Player ESP",
	Default = false,

	Callback = function(State)
		-- ESP intentionally left as a separate system.
	end
})

Visuals:CreateLabel("World")

Visuals:CreateToggle({
	Text = "Fullbright",
	Default = false,

	Callback = function(State)
		if State then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		else
			Lighting.Brightness = OriginalLighting.Brightness
			Lighting.ClockTime = OriginalLighting.ClockTime
			Lighting.FogEnd = OriginalLighting.FogEnd
			Lighting.GlobalShadows = OriginalLighting.GlobalShadows
			Lighting.Ambient = OriginalLighting.Ambient
		end
	end
})

Visuals:CreateSlider({
	Text = "FOV",
	Min = 40,
	Max = 120,
	Default = 70,

	Callback = function(Value)
		local Camera = workspace.CurrentCamera

		if Camera then
			Camera.FieldOfView = Value
		end
	end
})

-----/Server/-----

local Server = Window:CreateTab("Server")

Server:CreateButton({
	Text = "Rejoin",

	Callback = function()
		TeleportService:Teleport(
			game.PlaceId,
			Player
		)
	end
})

Server:CreateButton({
	Text = "Copy JobId",

	Callback = function()
		if setclipboard then
			setclipboard(game.JobId)
		end
	end
})

-----/Settings/-----

local Settings = Window:CreateTab("Settings")

Settings:CreateLabel("Interface")

Settings:CreateButton({
	Text = "Unload",

	Callback = function()
		StopFly()
		StopNoclip()
		StopInfiniteJump()

		local Character = GetCharacter()

		if Character then
			for _, Part in ipairs(Character:GetDescendants()) do
				if Part:IsA("BasePart") then
					Part.CanCollide = true
				end
			end
		end

		workspace.Gravity = Gravity
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.ClockTime = OriginalLighting.ClockTime
		Lighting.FogEnd = OriginalLighting.FogEnd
		Lighting.GlobalShadows = OriginalLighting.GlobalShadows
		Lighting.Ambient = OriginalLighting.Ambient
	end
})

Settings:CreateLabel("NPCs")

Settings:CreateToggle({
	Text = "NPCs",
	Default = false,

	Callback = function(State)
		-- NPC system can be connected here.
	end
})
