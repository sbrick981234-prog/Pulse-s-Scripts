local Player = owner

-- ================================================================
-- HL1 HUD + Source Engine Movement (Framework Structure)
-- ================================================================

-----/Services/-----
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

-----/Variables/-----
local Camera = workspace.CurrentCamera
local Gui = Player:WaitForChild("PlayerGui")

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local GmodDeathSound
local JumpAnimTrack

-- Fall / landing effect state
local LastVelocityY = 0
local LandingOffset = CFrame.new()
local LandingRoll = 0

local DeathOverlayTween
local VignetteTween

local LastHealth = 100
local ImpactTween
local ColorLerpAlpha = 0

-- Movement state
local ScriptEnabled = true
local SpaceHeld = false
local CrouchHeld = false
local MobileInputs = {W = false, A = false, S = false, D = false}

local Velocity = Vector3.new()
local IsGrounded = false
local WasGrounded = false
local MoveDir = Vector3.new()

local FootstepTimer = 0
local LastFootstepIndex = 0

local CurrentCameraOffset = 0
local TargetCameraOffset = 0

-----/Values/-----
-- Camera / FOV
local DEFAULT_FOV = 75
local ZOOM_FOV = 20

-- Colors
local WHITE = Color3.fromRGB(255, 255, 255)
local HL_ORANGE = Color3.fromRGB(255, 215, 0)
local HL_RED = Color3.fromRGB(255, 0, 0)
local HL_BLACK = Color3.new(0, 0, 0)

-- Landing effect
local MIN_FALL_SPEED = 38

-- Jump animation asset
local JumpAnim = Instance.new("Animation")
JumpAnim.AnimationId = "rbxassetid://131814798893284"

-- Movement physics config
local Cfg = {
	groundAccel = 25,
	airAccel = 10000,
	maxAirSpeed = 1,
	runSpeed = 26,
	jumpPower = 35,
	gravity = 100,
	friction = 4,
	stopSpeed = 6,
	abhMultiplier = -5,
	postImpulseGain = 0,
	surfSlopeLimit = 4,
}

local FootstepInterval = 0.35
local CrouchSpeed = 15
local RocketBlastRadius = 25

-- Footstep sounds by material
local FootstepSounds = {
	Slate = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
	Concrete = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
	Brick = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
	Wood = {"rbxassetid://87921439933530", "rbxassetid://89597871459985", "rbxassetid://139932856876296", "rbxassetid://75643573822739"},
	WoodPlanks = {"rbxassetid://87921439933530", "rbxassetid://89597871459985", "rbxassetid://139932856876296", "rbxassetid://75643573822739"},
	Metal = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
	DiamondPlate = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
	CorrodedMetal = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
	Grass = {"rbxassetid://105277634319381", "rbxassetid://98069158661569", "rbxassetid://135182192451997", "rbxassetid://116425333836106"},
	Sand = {"rbxassetid://84209465430801", "rbxassetid://115151668857364", "rbxassetid://93919782627384", "rbxassetid://105793766638092"},
	Mud = {"rbxassetid://125078502573216", "rbxassetid://119139580459950", "rbxassetid://132103348107931", "rbxassetid://137748446979624"},
	Snow = {"rbxassetid://90615555465225", "rbxassetid://125184282810966", "rbxassetid://114138676251211", "rbxassetid://132337775532551"},
	Plastic = {"rbxassetid://135712042029119", "rbxassetid://90507702118699", "rbxassetid://98172042741214", "rbxassetid://106319783012941"},
	SmoothPlastic = {"rbxassetid://135712042029119", "rbxassetid://90507702118699", "rbxassetid://98172042741214", "rbxassetid://106319783012941"},
	Fabric = {"rbxassetid://134707629631621", "rbxassetid://120658421045233", "rbxassetid://82315729709772", "rbxassetid://101186178877521"},
	Glass = {"rbxassetid://88813292437651", "rbxassetid://126359516625890", "rbxassetid://133178229418641", "rbxassetid://80572007771746"},
	Ice = {"rbxassetid://105786448375088", "rbxassetid://106093339008891", "rbxassetid://86217431358704", "rbxassetid://131109062323793"},
	Air = {""},
}

local JumpSounds = {"rbxassetid://142258831", "rbxassetid://142258874", "rbxassetid://142258905"}

-----/Main/-----

-- ===== UI: base containers =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HL_HUD_Final_Unified"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local DeathOverlay = Instance.new("Frame")
DeathOverlay.Size = UDim2.new(1, 0, 1, 0)
DeathOverlay.BackgroundColor3 = HL_RED
DeathOverlay.BackgroundTransparency = 1
DeathOverlay.BorderSizePixel = 0
DeathOverlay.ZIndex = 999
DeathOverlay.Parent = ScreenGui

-- ===== UI: vignette (zoom) =====
local Vignette = Instance.new("Frame")
Vignette.Size = UDim2.new(1, 0, 1, 0)
Vignette.BackgroundTransparency = 1
Vignette.BorderSizePixel = 0
Vignette.ZIndex = 900
Vignette.Parent = ScreenGui

local LeftBorder = Instance.new("Frame")
LeftBorder.Size = UDim2.new(0, 60, 1, 0)
LeftBorder.Position = UDim2.new(0, 0, 0, 0)
LeftBorder.BackgroundColor3 = HL_BLACK
LeftBorder.BackgroundTransparency = 1
LeftBorder.BorderSizePixel = 0
LeftBorder.ZIndex = 901
LeftBorder.Parent = Vignette

local LeftGradient = Instance.new("UIGradient", LeftBorder)
LeftGradient.Rotation = 0
LeftGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})
LeftGradient.Color = ColorSequence.new(HL_BLACK)

local RightBorder = Instance.new("Frame")
RightBorder.Size = UDim2.new(0, 60, 1, 0)
RightBorder.Position = UDim2.new(1, -60, 0, 0)
RightBorder.BackgroundColor3 = HL_BLACK
RightBorder.BackgroundTransparency = 1
RightBorder.BorderSizePixel = 0
RightBorder.ZIndex = 901
RightBorder.Parent = Vignette

local RightGradient = Instance.new("UIGradient", RightBorder)
RightGradient.Rotation = 180
RightGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})
RightGradient.Color = ColorSequence.new(HL_BLACK)

local TopBorder = Instance.new("Frame")
TopBorder.Size = UDim2.new(1, 0, 0, 40)
TopBorder.Position = UDim2.new(0, 0, 0, 0)
TopBorder.BackgroundColor3 = HL_BLACK
TopBorder.BackgroundTransparency = 1
TopBorder.BorderSizePixel = 0
TopBorder.ZIndex = 901
TopBorder.Parent = Vignette

local TopGradient = Instance.new("UIGradient", TopBorder)
TopGradient.Rotation = 90
TopGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})
TopGradient.Color = ColorSequence.new(HL_BLACK)

local BottomBorder = Instance.new("Frame")
BottomBorder.Size = UDim2.new(1, 0, 0, 40)
BottomBorder.Position = UDim2.new(0, 0, 1, -40)
BottomBorder.BackgroundColor3 = HL_BLACK
BottomBorder.BackgroundTransparency = 1
BottomBorder.BorderSizePixel = 0
BottomBorder.ZIndex = 901
BottomBorder.Parent = Vignette

local BottomGradient = Instance.new("UIGradient", BottomBorder)
BottomGradient.Rotation = -90
BottomGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})
BottomGradient.Color = ColorSequence.new(HL_BLACK)

local CornerTopLeft = Instance.new("Frame")
CornerTopLeft.Size = UDim2.new(0, 60, 0, 40)
CornerTopLeft.Position = UDim2.new(0, 0, 0, 0)
CornerTopLeft.BackgroundColor3 = HL_BLACK
CornerTopLeft.BackgroundTransparency = 1
CornerTopLeft.BorderSizePixel = 0
CornerTopLeft.ZIndex = 902
CornerTopLeft.Parent = Vignette

local CornerTLGradient = Instance.new("UIGradient", CornerTopLeft)
CornerTLGradient.Rotation = 45
CornerTLGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
CornerTLGradient.Color = ColorSequence.new(HL_BLACK)

local CornerTopRight = Instance.new("Frame")
CornerTopRight.Size = UDim2.new(0, 60, 0, 40)
CornerTopRight.Position = UDim2.new(1, -60, 0, 0)
CornerTopRight.BackgroundColor3 = HL_BLACK
CornerTopRight.BackgroundTransparency = 1
CornerTopRight.BorderSizePixel = 0
CornerTopRight.ZIndex = 902
CornerTopRight.Parent = Vignette

local CornerTRGradient = Instance.new("UIGradient", CornerTopRight)
CornerTRGradient.Rotation = 135
CornerTRGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
CornerTRGradient.Color = ColorSequence.new(HL_BLACK)

local CornerBottomLeft = Instance.new("Frame")
CornerBottomLeft.Size = UDim2.new(0, 60, 0, 40)
CornerBottomLeft.Position = UDim2.new(0, 0, 1, -40)
CornerBottomLeft.BackgroundColor3 = HL_BLACK
CornerBottomLeft.BackgroundTransparency = 1
CornerBottomLeft.BorderSizePixel = 0
CornerBottomLeft.ZIndex = 902
CornerBottomLeft.Parent = Vignette

local CornerBLGradient = Instance.new("UIGradient", CornerBottomLeft)
CornerBLGradient.Rotation = -45
CornerBLGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
CornerBLGradient.Color = ColorSequence.new(HL_BLACK)

local CornerBottomRight = Instance.new("Frame")
CornerBottomRight.Size = UDim2.new(0, 60, 0, 40)
CornerBottomRight.Position = UDim2.new(1, -60, 1, -40)
CornerBottomRight.BackgroundColor3 = HL_BLACK
CornerBottomRight.BackgroundTransparency = 1
CornerBottomRight.BorderSizePixel = 0
CornerBottomRight.ZIndex = 902
CornerBottomRight.Parent = Vignette

local CornerBRGradient = Instance.new("UIGradient", CornerBottomRight)
CornerBRGradient.Rotation = -135
CornerBRGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
CornerBRGradient.Color = ColorSequence.new(HL_BLACK)

-- ===== UI: speedometer =====
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 200, 0, 50)
SpeedLabel.Position = UDim2.new(0.5, -100, 1, -250)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = HL_ORANGE
SpeedLabel.TextSize = 47
SpeedLabel.Text = "0.0"
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.Parent = ScreenGui

local SpeedStroke = Instance.new("UIStroke", SpeedLabel)
SpeedStroke.Thickness = 0
SpeedStroke.Color = HL_ORANGE

-- ===== UI: health =====
local HealthContainer = Instance.new("Frame")
HealthContainer.Size = UDim2.new(0, 275, 0, 99)
HealthContainer.Position = UDim2.new(0, 50, 0.99, -100)
HealthContainer.BackgroundColor3 = HL_BLACK
HealthContainer.BackgroundTransparency = 0.85
HealthContainer.ZIndex = 500
HealthContainer.Parent = ScreenGui
Instance.new("UICorner", HealthContainer).CornerRadius = UDim.new(0, 10)

local HealthLabelText = Instance.new("TextLabel")
HealthLabelText.Text = "HEALTH"
HealthLabelText.Size = UDim2.new(0, 30, 1, 0)
HealthLabelText.Position = UDim2.new(0, 19, 0, 21)
HealthLabelText.TextColor3 = HL_ORANGE
HealthLabelText.TextTransparency = 0.4
HealthLabelText.TextSize = 17
HealthLabelText.BackgroundTransparency = 1
HealthLabelText.TextXAlignment = Enum.TextXAlignment.Left
HealthLabelText.ZIndex = 1000
HealthLabelText.Parent = HealthContainer

local HealthValue = Instance.new("TextLabel")
HealthValue.Size = UDim2.new(0, 100, 1, 0)
HealthValue.Position = UDim2.new(0, 145, 0, 7)
HealthValue.TextColor3 = HL_ORANGE
HealthValue.TextTransparency = 0.15
HealthValue.TextSize = 80
HealthValue.BackgroundTransparency = 1
HealthValue.TextXAlignment = Enum.TextXAlignment.Left
HealthValue.Text = "100"
HealthValue.Font = Enum.Font.Gotham
HealthValue.ZIndex = 1000
HealthValue.Parent = HealthContainer

local Glow = Instance.new("UIStroke")
Glow.Color = HL_ORANGE
Glow.Thickness = 0
Glow.Transparency = 1
Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
Glow.ZIndex = 800
Glow.Parent = HealthValue

-- ===== Functions: HUD effects =====
local function PlayGlowEffect()
	Glow.Transparency = 0.3
	Glow.Thickness = 7
	Glow.Color = HealthValue.TextColor3

	TweenService:Create(Glow, TweenInfo.new(7.0, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Transparency = 1,
		Thickness = 0,
	}):Play()
end

local function PlayImpactFlash(isCritical)
	if ImpactTween then ImpactTween:Cancel() end

	if isCritical then
		HealthContainer.BackgroundColor3 = HL_RED
		HealthContainer.BackgroundTransparency = 0
	else
		HealthContainer.BackgroundTransparency = 0
	end

	ImpactTween = TweenService:Create(HealthContainer, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.85,
		BackgroundColor3 = HL_BLACK,
	})
	ImpactTween:Play()
end

local function ApplyLandingEffect(fallSpeed)
	local Intensity = math.clamp(fallSpeed / 60, 0.5, 2)

	local TIME_TO_BEND = 0.08
	local TIME_TO_RECOVER = 0.3

	task.spawn(function()
		local T1 = 0
		local TargetRoll = math.rad(Intensity * 9) * (math.random() > 0.5 and 1 or -1)
		local TargetOffset = CFrame.new(0, -Intensity * 1.5, 0)

		while T1 < 1 do
			local Dt = RunService.RenderStepped:Wait()
			T1 = T1 + (Dt / TIME_TO_BEND)

			LandingRoll = math.lerp(0, TargetRoll, T1)
			LandingOffset = CFrame.new():Lerp(TargetOffset, T1)
		end

		local T2 = 0
		while T2 < 1 do
			local Dt = RunService.RenderStepped:Wait()
			T2 = T2 + (Dt / TIME_TO_RECOVER)

			local Alpha = math.sin(T2 * math.pi * 0.5)

			LandingRoll = math.lerp(TargetRoll, 0, Alpha)
			LandingOffset = TargetOffset:Lerp(CFrame.new(), Alpha)
		end

		LandingRoll = 0
		LandingOffset = CFrame.new()
	end)
end

-- ===== Functions: character setup (HUD side) =====
local function SetupCharacter(newChar)
	Character = newChar
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")

	GmodDeathSound = Instance.new("Sound")
	GmodDeathSound.SoundId = "rbxassetid://260341777"
	GmodDeathSound.Volume = 20
	GmodDeathSound.Parent = RootPart

	JumpAnimTrack = Humanoid:LoadAnimation(JumpAnim)
	JumpAnimTrack.Priority = Enum.AnimationPriority.Action

	DeathOverlay.BackgroundTransparency = 1
	LastHealth = Humanoid.Health

	Humanoid.Died:Connect(function()
		if GmodDeathSound then GmodDeathSound:Play() end

		if DeathOverlayTween then
			DeathOverlayTween:Cancel()
		end

		DeathOverlay.BackgroundTransparency = 0.70

		DeathOverlayTween = TweenService:Create(DeathOverlay, TweenInfo.new(5.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		DeathOverlayTween:Play()

		Glow.Thickness = 0
		Glow.Transparency = 1
	end)

	Humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			if JumpAnimTrack then JumpAnimTrack:Play() end
		elseif newState == Enum.HumanoidStateType.Landed then
			if JumpAnimTrack then JumpAnimTrack:Stop(0.1) end
			if math.abs(LastVelocityY) > MIN_FALL_SPEED then
				ApplyLandingEffect(math.abs(LastVelocityY))
			end
		end
	end)
end

-- ===== Functions: movement / sound helpers =====
local function GetFloorMaterial()
	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {Character}
	local Result = workspace:Raycast(RootPart.Position, Vector3.new(0, -3.8, 0), RayParams)
	if Result and Result.Instance then
		local MatName = Result.Instance.Material.Name
		return FootstepSounds[MatName] and MatName or "Slate"
	end
	return "Slate"
end

local function PlayFootstep(vol)
	local Material = GetFloorMaterial()
	local SoundTable = FootstepSounds[Material] or FootstepSounds.Slate
	local Sound = Instance.new("Sound", workspace)
	LastFootstepIndex = (LastFootstepIndex % #SoundTable) + 1
	Sound.SoundId = SoundTable[LastFootstepIndex]
	Sound.Volume = vol or 1.2
	Sound.PlaybackSpeed = 1.0 + math.random(-10, 10) / 100
	Sound:Play()
	Debris:AddItem(Sound, 2)
end

local function PlayJump()
	local Sound = Instance.new("Sound", workspace)
	Sound.SoundId = JumpSounds[math.random(1, #JumpSounds)]
	Sound.Volume = 1.3
	Sound.PlaybackSpeed = 1.0 + math.random(-5, 5) / 100
	Sound:Play()
	Debris:AddItem(Sound, 2)
	PlayFootstep(0.6)
end

local function PlayLand()
	PlayFootstep(1.3)
	if Velocity.Y < -60 then
		local Impact = Instance.new("Sound", workspace)
		Impact.SoundId = "rbxassetid://155416568"
		Impact.Volume = 1.5
		Impact:Play()
		Debris:AddItem(Impact, 2)
	end
end

local function FireRocket()
	if not ScriptEnabled then return end
	local Cam = workspace.CurrentCamera
	local Direction = Cam.CFrame.LookVector
	local Rocket = Instance.new("Part", workspace)
	Rocket.Size = Vector3.new(0.5, 0.5, 2)
	Rocket.CFrame = CFrame.lookAt(RootPart.Position + Direction * 3, RootPart.Position + Direction * 4)
	Rocket.Velocity = Direction * 150
	Rocket.CanCollide = false
	Rocket.BrickColor = BrickColor.new("Really red")
	Rocket.Material = Enum.Material.Neon

	local Sound = Instance.new("Sound", RootPart)
	Sound.SoundId = "rbxassetid://2156366946"
	Sound:Play()
	Debris:AddItem(Sound, 2)

	Rocket.Touched:Connect(function(hit)
		if hit and not hit:IsDescendantOf(Character) then
			local Pos = Rocket.Position
			local Explosion = Instance.new("Explosion", workspace)
			Explosion.Position = Pos
			Explosion.BlastRadius = RocketBlastRadius
			Explosion.BlastPressure = 0
			if (RootPart.Position - Pos).Magnitude <= RocketBlastRadius then
				Velocity += (RootPart.Position - Pos).Unit * 100
			end
			Rocket:Destroy()
		end
	end)
	Debris:AddItem(Rocket, 5)
end

local function ToggleScript()
	ScriptEnabled = not ScriptEnabled
	if not ScriptEnabled then
		Humanoid.WalkSpeed, Humanoid.JumpPower, Humanoid.AutoRotate = 16, 50, true
		Humanoid.CameraOffset = Vector3.new(0, 0, 0)
		CrouchHeld, Velocity = false, Vector3.new()
	end
end

-- ===== Functions: mobile GUI =====
local function CreateGui()
	local G = Instance.new("ScreenGui", Gui)
	G.ResetOnSpawn = false
	G.Name = "SourceDBG"

	local Toggle = Instance.new("TextButton", G)
	Toggle.Size = UDim2.new(0, 60, 0, 25)
	Toggle.Position = UDim2.new(1, -70, 0, 80)
	Toggle.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
	Toggle.Text = "ON"
	Toggle.MouseButton1Click:Connect(ToggleScript)

	local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if IsMobile then
		local JumpButton = Instance.new("TextButton", G)
		JumpButton.Size = UDim2.new(0, 110, 0, 110)
		JumpButton.Position = UDim2.new(1, -145, 1, -155)
		JumpButton.BackgroundTransparency = 0.5
		JumpButton.BackgroundColor3 = Color3.new(0, 0, 0)
		JumpButton.Text = "JUMP"
		JumpButton.TextColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", JumpButton).CornerRadius = UDim.new(1, 0)
		JumpButton.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then SpaceHeld = true end end)
		JumpButton.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then SpaceHeld = false end end)

		local CrouchButton = Instance.new("TextButton", G)
		CrouchButton.Size = UDim2.new(0, 80, 0, 80)
		CrouchButton.Position = UDim2.new(1, -235, 1, -125)
		CrouchButton.BackgroundTransparency = 0.5
		CrouchButton.BackgroundColor3 = Color3.new(0, 0, 0)
		CrouchButton.Text = "C"
		CrouchButton.TextColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", CrouchButton).CornerRadius = UDim.new(1, 0)
		CrouchButton.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then CrouchHeld = true end end)
		CrouchButton.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then CrouchHeld = false end end)

		local GrenadeButton = Instance.new("TextButton", G)
		GrenadeButton.Size = UDim2.new(0, 70, 0, 70)
		GrenadeButton.Position = UDim2.new(1, -125, 1, -240)
		GrenadeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		GrenadeButton.Text = "X"
		Instance.new("UICorner", GrenadeButton).CornerRadius = UDim.new(1, 0)
		GrenadeButton.MouseButton1Click:Connect(FireRocket)

		local Layout = {W = UDim2.new(0, 110, 1, -210), A = UDim2.new(0, 30, 1, -130), S = UDim2.new(0, 110, 1, -130), D = UDim2.new(0, 190, 1, -130)}
		for key, pos in pairs(Layout) do
			local Btn = Instance.new("TextButton", G)
			Btn.Size = UDim2.new(0, 70, 0, 70)
			Btn.Position = pos
			Btn.BackgroundTransparency = 0.5
			Btn.BackgroundColor3 = Color3.new(0, 0, 0)
			Btn.Text = key
			Btn.TextColor3 = Color3.new(1, 1, 1)
			Instance.new("UICorner", Btn)
			Btn.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then MobileInputs[key] = true end end)
			Btn.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then MobileInputs[key] = false end end)
		end
	end
end

-- ===== Functions: physics/movement process =====
local function Process(dt)
	if not ScriptEnabled then return end
	Humanoid.WalkSpeed, Humanoid.JumpPower, Humanoid.AutoRotate = 0, 0, false

	TargetCameraOffset = CrouchHeld and -2.5 or 0
	CurrentCameraOffset = CurrentCameraOffset + (TargetCameraOffset - CurrentCameraOffset) * math.min(dt * CrouchSpeed, 1)
	Humanoid.CameraOffset = Vector3.new(0, CurrentCameraOffset, 0)

	WasGrounded = IsGrounded
	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {Character}
	local Res = workspace:Raycast(RootPart.Position, Vector3.new(0, -3.8, 0), RayParams)
	IsGrounded = Res and Res.Instance and Res.Instance.CanCollide

	if IsGrounded and not WasGrounded then PlayLand() end

	local Cam = workspace.CurrentCamera
	local Fwd = Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z).Unit
	local Right = Vector3.new(Cam.CFrame.RightVector.X, 0, Cam.CFrame.RightVector.Z).Unit
	local Input = Vector3.new()
	local SPressed = false

	if UserInputService.KeyboardEnabled then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then Input += Fwd end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then Input -= Fwd SPressed = true end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then Input -= Right end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then Input += Right end
	end
	if MobileInputs.W then Input += Fwd end
	if MobileInputs.S then Input -= Fwd SPressed = true end
	if MobileInputs.A then Input -= Right end
	if MobileInputs.D then Input += Right end

	MoveDir = Input.Magnitude > 0 and Input.Unit or Vector3.new()
	RootPart.CFrame = CFrame.new(RootPart.Position, RootPart.Position + Fwd)

	local CurrentForwardSpeed = Velocity:Dot(Fwd)
	local CurrentTotalSpeed = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude

	if IsGrounded then
		if not (SpaceHeld and CrouchHeld and CurrentForwardSpeed < -1) then
			local Speed = Velocity.Magnitude
			if not SpaceHeld and Speed > 0.1 then
				local Drop = math.max(Speed, Cfg.stopSpeed) * (CrouchHeld and 0.4 or Cfg.friction) * dt
				Velocity *= math.max(Speed - Drop, 0) / Speed
			end
			local CurS = Velocity:Dot(MoveDir)
			local AddS = Cfg.runSpeed - CurS
			if AddS > 0 then Velocity += MoveDir * math.min(Cfg.groundAccel * dt * Cfg.runSpeed, AddS) end
		end

		if SpaceHeld then
			PlayJump()
			if CurrentForwardSpeed < 0.1 and CurrentTotalSpeed > (Cfg.runSpeed + 4) and not SPressed and CrouchHeld then
				Velocity += (Fwd * ((Cfg.runSpeed - CurrentForwardSpeed) * 0.25 * -1))
			end
			Velocity = Vector3.new(Velocity.X, Cfg.jumpPower, Velocity.Z)
		else
			Velocity = Vector3.new(Velocity.X, 0, Velocity.Z)
		end

		if MoveDir.Magnitude > 0.1 then
			FootstepTimer += dt
			if FootstepTimer >= FootstepInterval then PlayFootstep() FootstepTimer = 0 end
		end
	else
		local CurAS = Velocity:Dot(MoveDir)
		local AddAS = Cfg.maxAirSpeed - CurAS
		if AddAS > 0 then Velocity += MoveDir * math.min(Cfg.airAccel * dt * Cfg.maxAirSpeed, AddAS) end
		Velocity += Vector3.new(0, -Cfg.gravity * dt, 0)
	end

	RootPart.AssemblyLinearVelocity = Velocity
end

-----/Init/-----

-- HUD character setup
SetupCharacter(Character)
Player.CharacterAdded:Connect(SetupCharacter)

-- HUD update loop (speedometer, health, landing tilt, zoom vignette)
RunService.RenderStepped:Connect(function(dt)
	if RootPart and Humanoid and Humanoid.Health > 0 then
		LastVelocityY = RootPart.AssemblyLinearVelocity.Y
		Camera.CFrame = Camera.CFrame * LandingOffset * CFrame.Angles(0, 0, LandingRoll)

		local HVel = Vector3.new(RootPart.AssemblyLinearVelocity.X, 0, RootPart.AssemblyLinearVelocity.Z).Magnitude
		SpeedLabel.Text = string.format("%.1f", HVel * 11.02)

		local CurrentHP = Humanoid.Health
		HealthValue.Text = string.format("%.0f", CurrentHP)

		if CurrentHP < LastHealth then
			PlayImpactFlash(CurrentHP <= 20)
			PlayGlowEffect()
		end
		LastHealth = CurrentHP

		local TargetAlpha = (CurrentHP <= 20) and 1 or 0
		ColorLerpAlpha = math.clamp(ColorLerpAlpha + (dt * 0.8 * (TargetAlpha == 1 and 1 or -1)), 0, 1)

		local DynamicColor = HL_ORANGE:Lerp(HL_RED, ColorLerpAlpha)

		if CurrentHP <= 20 then
			local Pulse = 1 - ((tick() * 1.5) % 1)

			if not ImpactTween or ImpactTween.PlaybackState ~= Enum.PlaybackState.Playing or HealthContainer.BackgroundTransparency >= 0.85 then
				HealthContainer.BackgroundColor3 = HL_BLACK:Lerp(HL_RED, Pulse * ColorLerpAlpha)
				HealthContainer.BackgroundTransparency = 0.85
			end

			HealthValue.TextColor3 = DynamicColor
			HealthLabelText.TextColor3 = DynamicColor
			Glow.Color = HL_RED
			Glow.Thickness = 6 * Pulse
			Glow.Transparency = 1 - (0.3 * Pulse)
		else
			HealthContainer.BackgroundColor3 = HL_BLACK
			HealthContainer.BackgroundTransparency = 0.85
			HealthValue.TextColor3 = DynamicColor
			HealthLabelText.TextColor3 = DynamicColor
		end
	elseif Humanoid and Humanoid.Health <= 0 then
		HealthValue.Text = "0"
	end
end)

-- Zoom control (FOV + vignette)
ContextActionService:BindAction("ActionZoom", function(name, state)
	if state == Enum.UserInputState.Begin then
		TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = ZOOM_FOV}):Play()

		if VignetteTween then
			VignetteTween:Cancel()
		end

		VignetteTween = TweenService:Create(LeftBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
		VignetteTween:Play()
		TweenService:Create(RightBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(TopBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(BottomBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(CornerTopLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(CornerTopRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(CornerBottomLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(CornerBottomRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	elseif state == Enum.UserInputState.End then
		TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = DEFAULT_FOV}):Play()

		if VignetteTween then
			VignetteTween:Cancel()
		end

		VignetteTween = TweenService:Create(LeftBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		VignetteTween:Play()
		TweenService:Create(RightBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(TopBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(BottomBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(CornerTopLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(CornerTopRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(CornerBottomLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(CornerBottomRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	end
end, true, Enum.KeyCode.Z)

-- Back-view flip
ContextActionService:BindAction("BackViewAction", function(name, state)
	if state == Enum.UserInputState.Begin or state == Enum.UserInputState.End then
		Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.pi, 0)
	end
end, true, Enum.KeyCode.Q)

-- Mobile GUI
CreateGui()

-- Movement input
UserInputService.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if i.KeyCode == Enum.KeyCode.Space then SpaceHeld = true
	elseif i.KeyCode == Enum.KeyCode.C then CrouchHeld = true
	elseif i.KeyCode == Enum.KeyCode.X then FireRocket()
	elseif i.KeyCode == Enum.KeyCode.R then ToggleScript() end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.Space then SpaceHeld = false
	elseif i.KeyCode == Enum.KeyCode.C then CrouchHeld = false end
end)

-- Physics loop
RunService.Heartbeat:Connect(function(dt)
	if Humanoid and Humanoid.Health > 0 then Process(dt) end
end)

-- Character respawn reset (movement state)
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	RootPart = char:WaitForChild("HumanoidRootPart")
	Velocity = Vector3.new()
end)
