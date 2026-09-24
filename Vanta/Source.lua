-----/Services/-----
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer

local WalkSpeed = StarterPlayer.CharacterWalkSpeed
local JumpPower = StarterPlayer.CharacterJumpPower
local JumpHeight = StarterPlayer.CharacterJumpHeight

local FlySpeed = 50

local IsESPEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)
local IsESPTeamColor = false
local IsESPIgnoreTeammates = false
local IsESPDeathFilter = false
local IsNoclipEnabled = false
local IsFlyEnabled = false

local NoclipConnection
local FlyConnection

local OriginalCollide = setmetatable({}, { __mode = "k" })

-----/Assets/-----
local UILibUrl = "https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Larp%20UI/Source.lua"
local ScriptListUrl = "https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Vanta/Assets/Scripts.lua"

-----/Modules/-----
local UILib = loadstring(game:HttpGet(UILibUrl))()

-----/Values/-----
local ESPTag = "LarpESP"
local ESPWatchedAttribute = "LarpESPWatched"
local FlyVelocityName = "LarpFlyVelocity"
local FlyGyroName = "LarpFlyGyro"

-----/Functions/-----
local function LoadScriptList(Source : string) : { any }
	if type(Source) ~= "string" or Source == "" then
		return {}
	end

	local Chunk = loadstring(Source)

	if Chunk then
		local Success, Result = pcall(Chunk)

		if Success and type(Result) == "table" then
			return Result
		end
	end

	local Wrapped = loadstring("return " .. Source)

	if Wrapped then
		local Success, Result = pcall(Wrapped)

		if Success and type(Result) == "table" then
			return Result
		end
	end

	return {}
end

local function GetLocalHumanoid() : Humanoid?
	local Character = Player.Character

	if not Character then
		return nil
	end

	return Character:FindFirstChildOfClass("Humanoid")
end

local function IsTeammate(TargetPlayer : Player) : boolean
	if not TargetPlayer then
		return false
	end

	local MyTeam = Player.Team
	local TheirTeam = TargetPlayer.Team

	return MyTeam ~= nil and TheirTeam ~= nil and MyTeam == TheirTeam
end

local function ApplyESP(Model : Model)
	if not Model or not Model:IsA("Model") then
		return
	end

	local Humanoid = Model:FindFirstChildOfClass("Humanoid")
	local Existing = Model:FindFirstChild(ESPTag)
	local TargetPlayer = Players:GetPlayerFromCharacter(Model)

	if not Humanoid or not IsESPEnabled or (IsESPDeathFilter and Humanoid.Health <= 0) or (IsESPIgnoreTeammates and IsTeammate(TargetPlayer)) then
		if Existing then
			Existing:Destroy()
		end

		return
	end

	local ESP = Existing

	if not ESP then
		ESP = Instance.new("Highlight")
		ESP.Name = ESPTag
		ESP.FillTransparency = 0.5
		ESP.OutlineTransparency = 0
		ESP.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		ESP.Parent = Model
	end

	local Color = ESPColor

	if IsESPTeamColor and TargetPlayer then
		Color = TargetPlayer.TeamColor.Color
	end

	ESP.FillColor = Color
	ESP.OutlineColor = Color
end

local function RefreshAllESP()
	for _, Descendant in ipairs(Workspace:GetDescendants()) do
		if Descendant:IsA("Humanoid") then
			ApplyESP(Descendant.Parent)
		end
	end
end

local function WatchHumanoid(Humanoid : Humanoid)
	if Humanoid:GetAttribute(ESPWatchedAttribute) then
		return
	end

	Humanoid:SetAttribute(ESPWatchedAttribute, true)
	Humanoid.HealthChanged:Connect(function()
		ApplyESP(Humanoid.Parent)
	end)
end

local function SetNoclip(State : boolean)
	local Character = Player.Character

	if not Character then
		return
	end

	for _, Descendant in ipairs(Character:GetDescendants()) do
		if not Descendant:IsA("BasePart") then
			continue
		end

		if State then
			if OriginalCollide[Descendant] == nil then
				OriginalCollide[Descendant] = Descendant.CanCollide
			end

			Descendant.CanCollide = false
		else
			local Original = OriginalCollide[Descendant]

			if Original ~= nil then
				Descendant.CanCollide = Original
				OriginalCollide[Descendant] = nil
			end
		end
	end
end

local function StopFly()
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end

	local Character = Player.Character

	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Root = Character:FindFirstChild("HumanoidRootPart")

	if Root then
		local Velocity = Root:FindFirstChild(FlyVelocityName)

		if Velocity then
			Velocity:Destroy()
		end

		local Gyro = Root:FindFirstChild(FlyGyroName)

		if Gyro then
			Gyro:Destroy()
		end
	end

	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

local function StartFly()
	local Character = Player.Character

	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Root = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not Root then
		return
	end

	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.Name = FlyVelocityName
	BodyVelocity.MaxForce = Vector3.one * math.huge
	BodyVelocity.Velocity = Vector3.zero
	BodyVelocity.Parent = Root

	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.Name = FlyGyroName
	BodyGyro.MaxTorque = Vector3.one * math.huge
	BodyGyro.D = 10
	BodyGyro.P = 100
	BodyGyro.CFrame = Root.CFrame
	BodyGyro.Parent = Root

	Humanoid.PlatformStand = true

	FlyConnection = RunService.RenderStepped:Connect(function()
		local Camera = Workspace.CurrentCamera

		if not Camera or not Root.Parent then
			StopFly()
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

		BodyVelocity.Velocity = Direction * FlySpeed
		BodyGyro.CFrame = Camera.CFrame
	end)
end

local function SetWalkSpeed(Text : string, EnterPressed : boolean)
	local Digits = Text:gsub("%D+", "")
	WalkSpeed = tonumber(Digits) or WalkSpeed

	if not EnterPressed then
		return
	end

	local Humanoid = GetLocalHumanoid()

	if Humanoid then
		Humanoid.WalkSpeed = WalkSpeed
	end
end

local function SetJumpPower(Text : string, EnterPressed : boolean)
	local Digits = Text:gsub("%D+", "")
	JumpPower = tonumber(Digits) or JumpPower

	if not EnterPressed then
		return
	end

	local Humanoid = GetLocalHumanoid()

	if Humanoid then
		Humanoid.JumpPower = JumpPower
	end
end

local function SetJumpHeight(Text : string, EnterPressed : boolean)
	local Digits = Text:gsub("%D+", "")
	JumpHeight = tonumber(Digits) or JumpHeight

	if not EnterPressed then
		return
	end

	local Humanoid = GetLocalHumanoid()

	if Humanoid then
		Humanoid.JumpHeight = JumpHeight
	end
end

local function SetFlySpeed(Text : string, EnterPressed : boolean)
	local Digits = Text:gsub("%D+", "")
	FlySpeed = tonumber(Digits) or FlySpeed
end

local function OnNoclipToggle(State : boolean)
	IsNoclipEnabled = State

	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end

	SetNoclip(State)

	if State then
		NoclipConnection = RunService.Stepped:Connect(function()
			SetNoclip(true)
		end)
	end
end

local function OnFlyToggle(State : boolean)
	IsFlyEnabled = State

	if State then
		StartFly()
	else
		StopFly()
	end
end

local function OnESPToggle(State : boolean)
	IsESPEnabled = State

	RefreshAllESP()
end

local function OnESPTeamColorToggle(State : boolean)
	IsESPTeamColor = State

	RefreshAllESP()
end

local function OnESPIgnoreTeammatesToggle(State : boolean)
	IsESPIgnoreTeammates = State

	RefreshAllESP()
end

local function OnESPDeathFilterToggle(State : boolean)
	IsESPDeathFilter = State

	RefreshAllESP()
end

local function RunScriptEntry(ScriptEntry)
	local Success, Error = pcall(function()
		loadstring(ScriptEntry.Source)()
	end)

	if not Success then
		print("Script Hub | Failed to load " .. ScriptEntry.Name .. " : " .. tostring(Error))
	end
end

-----/Main/-----
local Window = UILib:CreateWindow("Vanta")

local CharacterTab = Window:CreateTab("Character")

CharacterTab:CreateLabel("Movement")

CharacterTab:CreateToggle({
	Text = "Noclip",
	Default = false,

	Callback = OnNoclipToggle,
})

CharacterTab:CreateToggle({
	Text = "Fly",
	Default = false,

	Callback = OnFlyToggle,
})

CharacterTab:CreateTextbox({
	Text = "",
	Placeholder = "FlySpeed : " .. FlySpeed,

	Callback = SetFlySpeed,
})

CharacterTab:CreateLabel("Humanoid")

CharacterTab:CreateTextbox({
	Text = "",
	Placeholder = "WalkSpeed : " .. WalkSpeed,

	Callback = SetWalkSpeed,
})

if StarterPlayer.CharacterUseJumpPower then
	CharacterTab:CreateTextbox({
		Text = "",
		Placeholder = "JumpPower : " .. JumpPower,

		Callback = SetJumpPower,
	})
else
	CharacterTab:CreateTextbox({
		Text = "",
		Placeholder = "JumpHeight : " .. JumpHeight,

		Callback = SetJumpHeight,
	})
end

local VisualTab = Window:CreateTab("Visual")

VisualTab:CreateLabel("Main")

VisualTab:CreateToggle({
	Text = "ESP",
	Default = false,

	Callback = OnESPToggle,
})

VisualTab:CreateLabel("Settings")

VisualTab:CreateToggle({
	Text = "Team Color",
	Default = IsESPTeamColor,

	Callback = OnESPTeamColorToggle,
})

VisualTab:CreateToggle({
	Text = "Ignore Teammates",
	Default = IsESPIgnoreTeammates,

	Callback = OnESPIgnoreTeammatesToggle,
})

VisualTab:CreateToggle({
	Text = "Death Filter",
	Default = IsESPDeathFilter,

	Callback = OnESPDeathFilterToggle,
})

local ScriptHubTab = Window:CreateTab("Script Hub")

local ScriptList = LoadScriptList(game:HttpGet(ScriptListUrl))

if #ScriptList == 0 then
	print("Script Hub | Failed to load script list")
else
	for _, ScriptEntry in ipairs(ScriptList) do
		ScriptHubTab:CreateButton({
			Text = ScriptEntry.Name,
			Callback = function()
				RunScriptEntry(ScriptEntry)
			end,
		})
	end
end

-----/Init/-----
for _, Descendant in ipairs(Workspace:GetDescendants()) do
	if Descendant:IsA("Humanoid") then
		WatchHumanoid(Descendant)
		ApplyESP(Descendant.Parent)
	end
end

Workspace.DescendantAdded:Connect(function(Descendant)
	if Descendant:IsA("Humanoid") then
		WatchHumanoid(Descendant)
		ApplyESP(Descendant.Parent)
	end
end)
