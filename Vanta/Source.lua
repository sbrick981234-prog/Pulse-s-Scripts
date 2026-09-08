local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Larp%20UI/Source.lua"))()

-----/Settings/-----
local Settings = UILib:CreateTab("Settings")

-----/NPCs/-----
local NPCs = Settings:CreateLabel("NPCs")

local NPCESPEnabled = false
local NPCBox = true
local NPCName = true
local NPCHealth = true
local NPCDistance = true
local NPCTracers = false
local NPCMaxDistance = 500
local NPCIgnoreDead = true
local NPCOnlyHumanoids = true
local NPCFilter = ""

local NPCObjects = {}
local NPCConnection

local function IsNPC(Model)
	if not Model:IsA("Model") then
		return false
	end

	if Players:GetPlayerFromCharacter(Model) then
		return false
	end

	local Humanoid = Model:FindFirstChildOfClass("Humanoid")
	local RootPart = Model:FindFirstChild("HumanoidRootPart")

	if NPCOnlyHumanoids and not Humanoid then
		return false
	end

	if not RootPart then
		return false
	end

	if NPCFilter ~= "" then
		if not string.find(
			Model.Name:lower(),
			NPCFilter:lower(),
			1,
			true
			) then
			return false
		end
	end

	if NPCIgnoreDead and Humanoid and Humanoid.Health <= 0 then
		return false
	end

	return true
end

local function CreateNPCESP(Model)
	if NPCObjects[Model] then
		return
	end

	local Box = Drawing.new("Square")
	Box.Thickness = 1
	Box.Filled = false
	Box.Color = ESPColor
	Box.Visible = false

	local Name = Drawing.new("Text")
	Name.Center = true
	Name.Outline = true
	Name.Size = 13
	Name.Font = 2
	Name.Color = ESPColor
	Name.Visible = false

	local Health = Drawing.new("Text")
	Health.Center = true
	Health.Outline = true
	Health.Size = 12
	Health.Font = 2
	Health.Color = Color3.fromRGB(0, 255, 0)
	Health.Visible = false

	local Distance = Drawing.new("Text")
	Distance.Center = true
	Distance.Outline = true
	Distance.Size = 12
	Distance.Font = 2
	Distance.Color = ESPColor
	Distance.Visible = false

	local Tracer = Drawing.new("Line")
	Tracer.Thickness = 1
	Tracer.Color = ESPColor
	Tracer.Visible = false

	NPCObjects[Model] = {
		Box = Box,
		Name = Name,
		Health = Health,
		Distance = Distance,
		Tracer = Tracer
	}
end

local function RemoveNPCESP(Model)
	local Object = NPCObjects[Model]

	if not Object then
		return
	end

	for _, DrawingObject in pairs(Object) do
		pcall(function()
			DrawingObject:Remove()
		end)
	end

	NPCObjects[Model] = nil
end

local function HideNPCESP(Object)
	Object.Box.Visible = false
	Object.Name.Visible = false
	Object.Health.Visible = false
	Object.Distance.Visible = false
	Object.Tracer.Visible = false
end

local function UpdateNPCESP(Model, Object)
	if not NPCESPEnabled then
		HideNPCESP(Object)
		return
	end

	if not Model.Parent or not IsNPC(Model) then
		HideNPCESP(Object)
		return
	end

	local Humanoid = Model:FindFirstChildOfClass("Humanoid")
	local RootPart = Model:FindFirstChild("HumanoidRootPart")
	local Head = Model:FindFirstChild("Head")
	local Camera = workspace.CurrentCamera

	if not Humanoid or not RootPart or not Head or not Camera then
		HideNPCESP(Object)
		return
	end

	local DistanceFromPlayer = (
		Camera.CFrame.Position - RootPart.Position
	).Magnitude

	if DistanceFromPlayer > NPCMaxDistance then
		HideNPCESP(Object)
		return
	end

	local RootPosition, OnScreen = Camera:WorldToViewportPoint(
		RootPart.Position
	)

	if not OnScreen or RootPosition.Z <= 0 then
		HideNPCESP(Object)
		return
	end

	local HeadPosition = Camera:WorldToViewportPoint(
		Head.Position + Vector3.new(0, 0.5, 0)
	)

	local BottomPosition = Camera:WorldToViewportPoint(
		RootPart.Position - Vector3.new(0, 3, 0)
	)

	local Height = math.abs(
		HeadPosition.Y - BottomPosition.Y
	)

	local Width = Height * 0.55

	local X = RootPosition.X - Width / 2
	local Y = HeadPosition.Y

	if ESPBox and NPCBox then
		Object.Box.Size = Vector2.new(Width, Height)
		Object.Box.Position = Vector2.new(X, Y)
		Object.Box.Color = ESPColor
		Object.Box.Visible = true
	else
		Object.Box.Visible = false
	end

	if ESPName and NPCName then
		Object.Name.Text = Model.Name

		Object.Name.Position = Vector2.new(
			RootPosition.X,
			Y - 16
		)

		Object.Name.Color = ESPColor
		Object.Name.Visible = true
	else
		Object.Name.Visible = false
	end

	if ESPHealth and NPCHealth then
		local HealthPercent = math.clamp(
			Humanoid.Health / Humanoid.MaxHealth,
			0,
			1
		)

		Object.Health.Text = string.format(
			"HP: %d/%d",
			Humanoid.Health,
			Humanoid.MaxHealth
		)

		Object.Health.Position = Vector2.new(
			RootPosition.X,
			Y + Height + 2
		)

		Object.Health.Color = Color3.fromRGB(
			255 - (255 * HealthPercent),
			255 * HealthPercent,
			0
		)

		Object.Health.Visible = true
	else
		Object.Health.Visible = false
	end

	if ESPDistance and NPCDistance then
		Object.Distance.Text = string.format(
			"%dm",
			math.floor(DistanceFromPlayer)
		)

		Object.Distance.Position = Vector2.new(
			RootPosition.X,
			Y + Height + (NPCHealth and 16 or 2)
		)

		Object.Distance.Color = ESPColor
		Object.Distance.Visible = true
	else
		Object.Distance.Visible = false
	end

	if ESPTracers and NPCTracers then
		local ViewportSize = Camera.ViewportSize

		Object.Tracer.From = Vector2.new(
			ViewportSize.X / 2,
			ViewportSize.Y
		)

		Object.Tracer.To = Vector2.new(
			RootPosition.X,
			RootPosition.Y
		)

		Object.Tracer.Color = ESPColor
		Object.Tracer.Visible = true
	else
		Object.Tracer.Visible = false
	end
end

local function ScanNPCs()
	for _, Object in pairs(NPCObjects) do
		HideNPCESP(Object)
	end

	for _, Object in ipairs(workspace:GetDescendants()) do
		if Object:IsA("Model") and IsNPC(Object) then
			CreateNPCESP(Object)
		end
	end
end

local function StartNPCESP()
	if NPCConnection then
		return
	end

	ScanNPCs()

	NPCConnection = RunService.RenderStepped:Connect(function()
		for Model, Object in pairs(NPCObjects) do
			if Model and Model.Parent then
				UpdateNPCESP(Model, Object)
			else
				RemoveNPCESP(Model)
			end
		end
	end)
end

local function StopNPCESP()
	if NPCConnection then
		NPCConnection:Disconnect()
		NPCConnection = nil
	end

	for _, Object in pairs(NPCObjects) do
		HideNPCESP(Object)
	end
end

-----/NPC Settings/-----

Settings:CreateToggle({
	Text = "Enable NPC ESP",
	Default = false,

	Callback = function(State)
		NPCESPEnabled = State

		if State then
			StartNPCESP()
		else
			StopNPCESP()
		end
	end
})

Settings:CreateToggle({
	Text = "Box",
	Default = true,

	Callback = function(State)
		NPCBox = State
	end
})

Settings:CreateToggle({
	Text = "Name",
	Default = true,

	Callback = function(State)
		NPCName = State
	end
})

Settings:CreateToggle({
	Text = "Health",
	Default = true,

	Callback = function(State)
		NPCHealth = State
	end
})

Settings:CreateToggle({
	Text = "Distance",
	Default = true,

	Callback = function(State)
		NPCDistance = State
	end
})

Settings:CreateToggle({
	Text = "Tracers",
	Default = false,

	Callback = function(State)
		NPCTracers = State
	end
})

Settings:CreateToggle({
	Text = "Ignore Dead NPCs",
	Default = true,

	Callback = function(State)
		NPCIgnoreDead = State
	end
})

Settings:CreateToggle({
	Text = "Only Humanoids",
	Default = true,

	Callback = function(State)
		NPCOnlyHumanoids = State
	end
})

Settings:CreateSlider({
	Text = "Max Distance",
	Min = 50,
	Max = 5000,
	Default = 500,

	Callback = function(Value)
		NPCMaxDistance = Value
	end
})

Settings:CreateTextBox({
	Text = "NPC Filter",
	PlaceholderText = "NPC name...",
	Default = "",

	Callback = function(Value)
		NPCFilter = Value
	end
})

Settings:CreateButton({
	Text = "Refresh NPCs",

	Callback = function()
		ScanNPCs()
	end
})
