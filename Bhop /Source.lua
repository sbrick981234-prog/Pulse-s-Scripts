-- LocalScript: HUD HL1 Authentic Speed + Landing Effect + Jump Animation
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- [AUTHORIZED MODIFICATION: GMOD DEATH SOUND VARIABLE]
local gmodDeathSound
-- [END MODIFICATION]

-- [AUTHORIZED MODIFICATION: ANIMATION SETUP]
local jumpAnim = Instance.new("Animation")
jumpAnim.AnimationId = "rbxassetid://131814798893284"
local jumpAnimTrack
-- [END MODIFICATION]

-- CONFIGURATION
local DEFAULT_FOV = 75
local ZOOM_FOV = 20
Camera.FieldOfView = DEFAULT_FOV
local WHITE = Color3.fromRGB(255, 255, 255)
local HL_ORANGE = Color3.fromRGB(255, 215, 0)
local HL_RED = Color3.fromRGB(255, 0, 0)
local HL_BLACK = Color3.new(0, 0, 0)

-- FALL VARIABLES
local lastVelocityY = 0
local landingOffset = CFrame.new()
local landingRoll = 0
local MIN_FALL_SPEED = 38

local deathOverlayTween

-- [AUTHORIZED MODIFICATION: VIGNETTE FOR ZOOM]
local vignetteTween
-- [END MODIFICATION]

local cursorEnabled = false
UserInputService.MouseIconEnabled = false

-- INTERFACE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HL_HUD_Final_Unified"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = player:WaitForChild("PlayerGui")

local deathOverlay = Instance.new("Frame")
deathOverlay.Size = UDim2.new(1, 0, 1, 0)
deathOverlay.BackgroundColor3 = HL_RED
deathOverlay.BackgroundTransparency = 1
deathOverlay.BorderSizePixel = 0
deathOverlay.ZIndex = 999
deathOverlay.Parent = screenGui

-- [AUTHORIZED MODIFICATION: VIGNETTE FRAME - TODOS LOS LADOS CON GRADIENTES + ESQUINAS]
local vignette = Instance.new("Frame")
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1 -- Contenedor transparente
vignette.BorderSizePixel = 0
vignette.ZIndex = 900 -- Debajo del death overlay
vignette.Parent = screenGui

-- Borde izquierdo
local leftBorder = Instance.new("Frame")
leftBorder.Size = UDim2.new(0, 60, 1, 0) -- Ancho fijo, alto completo
leftBorder.Position = UDim2.new(0, 0, 0, 0)
leftBorder.BackgroundColor3 = HL_BLACK
leftBorder.BackgroundTransparency = 1 -- Transparente inicialmente
leftBorder.BorderSizePixel = 0
leftBorder.ZIndex = 901
leftBorder.Parent = vignette

-- Gradiente para borde izquierdo (opaco en borde, transparente hacia el centro)
local leftGradient = Instance.new("UIGradient", leftBorder)
leftGradient.Rotation = 0
leftGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Borde izquierdo completamente opaco
    NumberSequenceKeypoint.new(0.5, 0.7), -- Medio: 70% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Borde derecho completamente transparente
})
leftGradient.Color = ColorSequence.new(HL_BLACK)

-- Borde derecho
local rightBorder = Instance.new("Frame")
rightBorder.Size = UDim2.new(0, 60, 1, 0)
rightBorder.Position = UDim2.new(1, -60, 0, 0) -- Alineado a la derecha
rightBorder.BackgroundColor3 = HL_BLACK
rightBorder.BackgroundTransparency = 1
rightBorder.BorderSizePixel = 0
rightBorder.ZIndex = 901
rightBorder.Parent = vignette

-- Gradiente para borde derecho (opaco en borde, transparente hacia el centro)
local rightGradient = Instance.new("UIGradient", rightBorder)
rightGradient.Rotation = 180
rightGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Borde derecho completamente opaco
    NumberSequenceKeypoint.new(0.5, 0.7), -- Medio: 70% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Borde izquierdo completamente transparente
})
rightGradient.Color = ColorSequence.new(HL_BLACK)

-- Borde superior
local topBorder = Instance.new("Frame")
topBorder.Size = UDim2.new(1, 0, 0, 40) -- Ancho completo
topBorder.Position = UDim2.new(0, 0, 0, 0)
topBorder.BackgroundColor3 = HL_BLACK
topBorder.BackgroundTransparency = 1
topBorder.BorderSizePixel = 0
topBorder.ZIndex = 901
topBorder.Parent = vignette

-- Gradiente para borde superior (opaco en borde, transparente hacia abajo)
local topGradient = Instance.new("UIGradient", topBorder)
topGradient.Rotation = 90
topGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Borde superior completamente opaco
    NumberSequenceKeypoint.new(0.5, 0.7), -- Medio: 70% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Borde inferior completamente transparente
})
topGradient.Color = ColorSequence.new(HL_BLACK)

-- Borde inferior
local bottomBorder = Instance.new("Frame")
bottomBorder.Size = UDim2.new(1, 0, 0, 40)
bottomBorder.Position = UDim2.new(0, 0, 1, -40) -- Alineado al fondo
bottomBorder.BackgroundColor3 = HL_BLACK
bottomBorder.BackgroundTransparency = 1
bottomBorder.BorderSizePixel = 0
bottomBorder.ZIndex = 901
bottomBorder.Parent = vignette

-- Gradiente para borde inferior (opaco en borde, transparente hacia arriba)
local bottomGradient = Instance.new("UIGradient", bottomBorder)
bottomGradient.Rotation = -90
bottomGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Borde inferior completamente opaco
    NumberSequenceKeypoint.new(0.5, 0.7), -- Medio: 70% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Borde superior completamente transparente
})
bottomGradient.Color = ColorSequence.new(HL_BLACK)

-- [AUTHORIZED MODIFICATION: ESQUINAS CON GRADIENTES RADIALES]
-- Esquina superior izquierda
local cornerTopLeft = Instance.new("Frame")
cornerTopLeft.Size = UDim2.new(0, 60, 0, 40)
cornerTopLeft.Position = UDim2.new(0, 0, 0, 0)
cornerTopLeft.BackgroundColor3 = HL_BLACK
cornerTopLeft.BackgroundTransparency = 1
cornerTopLeft.BorderSizePixel = 0
cornerTopLeft.ZIndex = 902
cornerTopLeft.Parent = vignette

-- Gradiente radial para esquina superior izquierda
local cornerTLGradient = Instance.new("UIGradient", cornerTopLeft)
cornerTLGradient.Rotation = 45
cornerTLGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Esquina completamente opaca
    NumberSequenceKeypoint.new(0.5, 0.5), -- Medio: 50% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Centro completamente transparente
})
cornerTLGradient.Color = ColorSequence.new(HL_BLACK)

-- Esquina superior derecha
local cornerTopRight = Instance.new("Frame")
cornerTopRight.Size = UDim2.new(0, 60, 0, 40)
cornerTopRight.Position = UDim2.new(1, -60, 0, 0)
cornerTopRight.BackgroundColor3 = HL_BLACK
cornerTopRight.BackgroundTransparency = 1
cornerTopRight.BorderSizePixel = 0
cornerTopRight.ZIndex = 902
cornerTopRight.Parent = vignette

-- Gradiente radial para esquina superior derecha
local cornerTRGradient = Instance.new("UIGradient", cornerTopRight)
cornerTRGradient.Rotation = 135
cornerTRGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Esquina completamente opaca
    NumberSequenceKeypoint.new(0.5, 0.5), -- Medio: 50% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Centro completamente transparente
})
cornerTRGradient.Color = ColorSequence.new(HL_BLACK)

-- Esquina inferior izquierda
local cornerBottomLeft = Instance.new("Frame")
cornerBottomLeft.Size = UDim2.new(0, 60, 0, 40)
cornerBottomLeft.Position = UDim2.new(0, 0, 1, -40)
cornerBottomLeft.BackgroundColor3 = HL_BLACK
cornerBottomLeft.BackgroundTransparency = 1
cornerBottomLeft.BorderSizePixel = 0
cornerBottomLeft.ZIndex = 902
cornerBottomLeft.Parent = vignette

-- Gradiente radial para esquina inferior izquierda
local cornerBLGradient = Instance.new("UIGradient", cornerBottomLeft)
cornerBLGradient.Rotation = -45
cornerBLGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Esquina completamente opaca
    NumberSequenceKeypoint.new(0.5, 0.5), -- Medio: 50% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Centro completamente transparente
})
cornerBLGradient.Color = ColorSequence.new(HL_BLACK)

-- Esquina inferior derecha
local cornerBottomRight = Instance.new("Frame")
cornerBottomRight.Size = UDim2.new(0, 60, 0, 40)
cornerBottomRight.Position = UDim2.new(1, -60, 1, -40)
cornerBottomRight.BackgroundColor3 = HL_BLACK
cornerBottomRight.BackgroundTransparency = 1
cornerBottomRight.BorderSizePixel = 0
cornerBottomRight.ZIndex = 902
cornerBottomRight.Parent = vignette

-- Gradiente radial para esquina inferior derecha
local cornerBRGradient = Instance.new("UIGradient", cornerBottomRight)
cornerBRGradient.Rotation = -135
cornerBRGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),    -- Esquina completamente opaca
    NumberSequenceKeypoint.new(0.5, 0.5), -- Medio: 50% transparencia
    NumberSequenceKeypoint.new(1, 1)     -- Centro completamente transparente
})
cornerBRGradient.Color = ColorSequence.new(HL_BLACK)
-- [END MODIFICATION]

local customCursor = Instance.new("Frame")
customCursor.Size = UDim2.new(0, 5, 0, 5)
customCursor.AnchorPoint = Vector2.new(0.5, 0.5)
customCursor.BackgroundColor3 = WHITE
customCursor.Visible = cursorEnabled
customCursor.Parent = screenGui
Instance.new("UICorner", customCursor).CornerRadius = UDim.new(1, 0)

-- SPEEDOMETER
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 200, 0, 50)
speedLabel.Position = UDim2.new(0.5, -100, 1, -250)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = HL_ORANGE
speedLabel.TextSize = 47
speedLabel.Text = "0.0"
speedLabel.Font = Enum.Font.Gotham  -- 🔥 NUEVA FUENTE PARA VELOCIDAD
speedLabel.Parent = screenGui

local speedStroke = Instance.new("UIStroke", speedLabel)
speedStroke.Thickness = 0
speedStroke.Color = HL_ORANGE

-- HEALTH CONTAINER
local healthContainer = Instance.new("Frame")
healthContainer.Size = UDim2.new(0, 275, 0, 99)
healthContainer.Position = UDim2.new(0, 50, 0.99, -100)
healthContainer.BackgroundColor3 = HL_BLACK
healthContainer.BackgroundTransparency = 0.85
healthContainer.ZIndex = 500
healthContainer.Parent = screenGui
Instance.new("UICorner", healthContainer).CornerRadius = UDim.new(0, 10)

local healthLabelText = Instance.new("TextLabel")
healthLabelText.Text = "HEALTH"
healthLabelText.Size = UDim2.new(0, 30, 1, 0)
healthLabelText.Position = UDim2.new(0, 19, 0, 21)
healthLabelText.TextColor3 = HL_ORANGE
healthLabelText.TextTransparency = 0.4
healthLabelText.TextSize = 17
healthLabelText.BackgroundTransparency = 1
healthLabelText.TextXAlignment = Enum.TextXAlignment.Left
healthLabelText.ZIndex = 1000
healthLabelText.Parent = healthContainer

local healthValue = Instance.new("TextLabel")
healthValue.Size = UDim2.new(0, 100, 1, 0)
healthValue.Position = UDim2.new(0, 145, 0, 7)
healthValue.TextColor3 = HL_ORANGE
healthValue.TextTransparency = 0.15
healthValue.TextSize = 80
healthValue.BackgroundTransparency = 1
healthValue.TextXAlignment = Enum.TextXAlignment.Left
healthValue.Text = "100"
healthValue.Font = Enum.Font.Gotham  -- 🔥 FUENTE GOTHAM (similar a FF Din) para los números
healthValue.ZIndex = 1000
healthValue.Parent = healthContainer

local glow = Instance.new("UIStroke")
glow.Color = HL_ORANGE
glow.Thickness = 0
glow.Transparency = 1
glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
glow.ZIndex = 800
glow.Parent = healthValue

-- ANIMATIONS LOGIC
local lastHealth = 100
local impactTween

local function playGlowEffect()
	glow.Transparency = 0.3
	glow.Thickness = 7
	glow.Color = healthValue.TextColor3
	
	TweenService:Create(glow, TweenInfo.new(7.0, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Transparency = 1,
		Thickness = 0
	}):Play()
end

local function playImpactFlash(isCritical)
	if impactTween then impactTween:Cancel() end
	
	if isCritical then
		healthContainer.BackgroundColor3 = HL_RED
		healthContainer.BackgroundTransparency = 0
	else
		healthContainer.BackgroundTransparency = 0
	end
	
	impactTween = TweenService:Create(healthContainer, TweenInfo.new(1., Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.85,
		BackgroundColor3 = HL_BLACK
	})
	impactTween:Play()
end

local function applyLandingEffect(fallSpeed)
	local intensity = math.clamp(fallSpeed / 60, 0.5, 2)
	
	-- VALORES DE TIEMPO (Aquí controlas la duración)
	local TIME_TO_BEND = 0.08   -- Cuánto tarda en "agacharse" la cámara (el giro hacia abajo)
	local TIME_TO_RECOVER = 0.3 -- Cuánto tarda en volver a la normalidad
	
	task.spawn(function()
		-- FASE 1: INCLINACIÓN (La bajada que buscas)
		local t1 = 0
		local targetRoll = math.rad(intensity * 9) * (math.random() > 0.5 and 1 or -1)
		local targetOffset = CFrame.new(0, -intensity * 1.5, 0)
		
		while t1 < 1 do
			local dt = RunService.RenderStepped:Wait()
			t1 = t1 + (dt / TIME_TO_BEND) -- Esto define la velocidad de la inclinación
			
			-- Usamos un Lerp suave para la bajada
			landingRoll = math.lerp(0, targetRoll, t1)
			landingOffset = CFrame.new():Lerp(targetOffset, t1)
		end
		
		-- FASE 2: RECUPERACIÓN (El regreso elástico)
		local t2 = 0
		while t2 < 1 do
			local dt = RunService.RenderStepped:Wait()
			t2 = t2 + (dt / TIME_TO_RECOVER)
			
			-- Curva de suavizado para que se vea "pro" como en el video
			local alpha = math.sin(t2 * math.pi * 0.5) -- Movimiento circular/elástico
			
			landingRoll = math.lerp(targetRoll, 0, alpha)
			landingOffset = targetOffset:Lerp(CFrame.new(), alpha)
		end
		
		-- Reset final
		landingRoll = 0
		landingOffset = CFrame.new()
	end)
end

local function setupCharacter(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- [AUTHORIZED MODIFICATION: AUTHENTIC GMOD FLATLINE SOUND]
	gmodDeathSound = Instance.new("Sound")
	gmodDeathSound.SoundId = "rbxassetid://260341777" -- Flatline Authentic GMod/HL2
	gmodDeathSound.Volume = 20
	gmodDeathSound.Parent = rootPart
	-- [END MODIFICATION]
	
	-- [AUTHORIZED MODIFICATION: LOAD TRACK]
	jumpAnimTrack = humanoid:LoadAnimation(jumpAnim)
	jumpAnimTrack.Priority = Enum.AnimationPriority.Action
	-- [END MODIFICATION]
	
	deathOverlay.BackgroundTransparency = 1
	lastHealth = humanoid.Health
	humanoid.Died:Connect(function()
		-- [AUTHORIZED MODIFICATION: PLAY SOUND]
		if gmodDeathSound then gmodDeathSound:Play() end
		-- [END MODIFICATION]
		
		-- 🔥 CANCELAR TWEEN ANTERIOR SI EXISTE
		if deathOverlayTween then
			deathOverlayTween:Cancel()
		end
		
		-- 🔥 APARECE CON 0.70 DE TRANSPARENCIA
		deathOverlay.BackgroundTransparency = 0.70
		
		-- 🔥 DESAPARECE GRADUALMENTE HASTA 1.0 (INVISIBLE)
		deathOverlayTween = TweenService:Create(deathOverlay, TweenInfo.new(5.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		})
		deathOverlayTween:Play()
		
		glow.Thickness = 0 glow.Transparency = 1
	end)
	
	humanoid.StateChanged:Connect(function(oldState, newState)
		-- [AUTHORIZED MODIFICATION: ANIMATION TRIGGERS]
		if newState == Enum.HumanoidStateType.Jumping then
			if jumpAnimTrack then jumpAnimTrack:Play() end
		elseif newState == Enum.HumanoidStateType.Landed then
			if jumpAnimTrack then jumpAnimTrack:Stop(0.1) end
			if math.abs(lastVelocityY) > MIN_FALL_SPEED then
				applyLandingEffect(math.abs(lastVelocityY))
			end
		end
		-- [END MODIFICATION]
	end)
end

setupCharacter(character)
player.CharacterAdded:Connect(setupCharacter)

local colorLerpAlpha = 0

RunService.RenderStepped:Connect(function(dt)
	UserInputService.MouseIconEnabled = false
	if cursorEnabled then
		local mPos = UserInputService:GetMouseLocation()
		customCursor.Position = UDim2.new(0, mPos.X, 0, mPos.Y)
	end
	
	if rootPart and humanoid and humanoid.Health > 0 then
		lastVelocityY = rootPart.AssemblyLinearVelocity.Y
		Camera.CFrame = Camera.CFrame * landingOffset * CFrame.Angles(0, 0, landingRoll)
		
		local hVel = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
        -- MODIFICACIÓN AUTORIZADA: Factor de conversión exacto para Half-Life Units (11.02)
		speedLabel.Text = string.format("%.1f", hVel * 11.02)
		
		local currentHP = humanoid.Health
		healthValue.Text = string.format("%.0f", currentHP)
		
		if currentHP < lastHealth then
			playImpactFlash(currentHP <= 20)
			playGlowEffect()
		end
		lastHealth = currentHP

		local targetAlpha = (currentHP <= 20) and 1 or 0
		colorLerpAlpha = math.clamp(colorLerpAlpha + (dt * 0.8 * (targetAlpha == 1 and 1 or -1)), 0, 1)
		
		local dynamicColor = HL_ORANGE:Lerp(HL_RED, colorLerpAlpha)
		
		if currentHP <= 20 then
			local pulse = 1 - ((tick() * 1.5) % 1)
			
			if not impactTween or impactTween.PlaybackState ~= Enum.PlaybackState.Playing or healthContainer.BackgroundTransparency >= 0.85 then
				healthContainer.BackgroundColor3 = HL_BLACK:Lerp(HL_RED, pulse * colorLerpAlpha)
				healthContainer.BackgroundTransparency = 0.85
			end
			
			healthValue.TextColor3 = dynamicColor
			healthLabelText.TextColor3 = dynamicColor
			glow.Color = HL_RED
			glow.Thickness = 6 * pulse
			glow.Transparency = 1 - (0.3 * pulse)
		else
			healthContainer.BackgroundColor3 = HL_BLACK
			healthContainer.BackgroundTransparency = 0.85
			healthValue.TextColor3 = dynamicColor
			healthLabelText.TextColor3 = dynamicColor
		end
	elseif humanoid and humanoid.Health <= 0 then
		healthValue.Text = "0"
	end
end)

-- CONTROLS
ContextActionService:BindAction("ToggleCursor", function(name, state)
	if state == Enum.UserInputState.Begin then cursorEnabled = not cursorEnabled customCursor.Visible = cursorEnabled end
end, false, Enum.KeyCode.T)

ContextActionService:BindAction("ActionZoom", function(name, state)
	if state == Enum.UserInputState.Begin then 
		-- Aplicar zoom de FOV
		TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = ZOOM_FOV}):Play()
		
		-- [AUTHORIZED MODIFICATION: ACTIVAR VINETA EN TODOS LOS LADOS + ESQUINAS]
		if vignetteTween then
			vignetteTween:Cancel()
		end
		
		-- Mostrar todos los bordes y esquinas
		vignetteTween = TweenService:Create(leftBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		})
		vignetteTween:Play()
		
		TweenService:Create(rightBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(topBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(bottomBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		-- Mostrar esquinas
		TweenService:Create(cornerTopLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(cornerTopRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(cornerBottomLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
		TweenService:Create(cornerBottomRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0
		}):Play()
		
	elseif state == Enum.UserInputState.End then 
		-- Quitar zoom de FOV
		TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = DEFAULT_FOV}):Play()
		
		-- [AUTHORIZED MODIFICATION: DESACTIVAR VINETA EN TODOS LOS LADOS + ESQUINAS]
		if vignetteTween then
			vignetteTween:Cancel()
		end
		
		-- Ocultar todos los bordes y esquinas gradualmente
		vignetteTween = TweenService:Create(leftBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		})
		vignetteTween:Play()
		
		TweenService:Create(rightBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(topBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(bottomBorder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		-- Ocultar esquinas
		TweenService:Create(cornerTopLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(cornerTopRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(cornerBottomLeft, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(cornerBottomRight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
	end
end, true, Enum.KeyCode.Z)

ContextActionService:BindAction("BackViewAction", function(name, state)
	if state == Enum.UserInputState.Begin or state == Enum.UserInputState.End then Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.pi, 0) end
end, true, Enum.KeyCode.Q)

-- Source Engine Movement for Roblox + ABH (Crouch-Only) + HL1/HL2/CS Jump Sounds + Crouch Sliding
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local scriptEnabled = true
local spaceHeld = false
local crouchHeld = false 
local mobileInputs = {W = false, A = false, S = false, D = false}

local velocity = Vector3.new()
local isGrounded = false
local wasGrounded = false
local moveDir = Vector3.new()

local footstepTimer = 0
local footstepInterval = 0.35
local lastFootstepIndex = 0

-- Animación de cámara
local currentCameraOffset = 0
local targetCameraOffset = 0
local crouchSpeed = 15 

-- Configuration (Física Original Intacta)
local cfg = {
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
    surfSlopeLimit = 4 
}

local rocketBlastRadius = 25

-- [RESTAURADO] Tabla Completa de Sonidos
local footstepSounds = {
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

local jumpSounds = {"rbxassetid://142258831", "rbxassetid://142258874", "rbxassetid://142258905"}

-- [RESTAURADO] Funciones de Sonido y Materiales
local function getFloorMaterial()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    if result and result.Instance then
        local matName = result.Instance.Material.Name
        return footstepSounds[matName] and matName or "Slate"
    end
    return "Slate"
end

local function playFootstep(vol)
    local material = getFloorMaterial()
    local soundTable = footstepSounds[material] or footstepSounds.Slate
    local sound = Instance.new("Sound", workspace)
    lastFootstepIndex = (lastFootstepIndex % #soundTable) + 1
    sound.SoundId = soundTable[lastFootstepIndex]
    sound.Volume = vol or 1.2
    sound.PlaybackSpeed = 1.0 + math.random(-10, 10) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playJump()
    local sound = Instance.new("Sound", workspace)
    sound.SoundId = jumpSounds[math.random(1, #jumpSounds)]
    sound.Volume = 1.3
    sound.PlaybackSpeed = 1.0 + math.random(-5, 5) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
    playFootstep(0.6)
end

local function playLand()
    playFootstep(1.3)
    if velocity.Y < -60 then
        local impact = Instance.new("Sound", workspace)
        impact.SoundId = "rbxassetid://155416568"
        impact.Volume = 1.5
        impact:Play()
        game:GetService("Debris"):AddItem(impact, 2)
    end
end

-- Rocket logic (Fuego de Granada/X)
local function fireRocket()
    if not scriptEnabled then return end
    local cam = workspace.CurrentCamera
    local direction = cam.CFrame.LookVector
    local rocket = Instance.new("Part", workspace)
    rocket.Size = Vector3.new(0.5, 0.5, 2)
    rocket.CFrame = CFrame.lookAt(root.Position + direction * 3, root.Position + direction * 4)
    rocket.Velocity = direction * 150
    rocket.CanCollide = false
    rocket.BrickColor = BrickColor.new("Really red")
    rocket.Material = Enum.Material.Neon
    
    local sound = Instance.new("Sound", root)
    sound.SoundId = "rbxassetid://2156366946"
    sound:Play()
    game.Debris:AddItem(sound, 2)

    rocket.Touched:Connect(function(hit)
        if hit and not hit:IsDescendantOf(character) then
            local pos = rocket.Position
            local explosion = Instance.new("Explosion", workspace)
            explosion.Position = pos
            explosion.BlastRadius = rocketBlastRadius
            explosion.BlastPressure = 0
            if (root.Position - pos).Magnitude <= rocketBlastRadius then
                velocity += (root.Position - pos).Unit * 100
            end
            rocket:Destroy()
        end
    end)
    game.Debris:AddItem(rocket, 5)
end

local function toggleScript()
    scriptEnabled = not scriptEnabled
    if not scriptEnabled then
        humanoid.WalkSpeed, humanoid.JumpPower, humanoid.AutoRotate = 16, 50, true
        humanoid.CameraOffset = Vector3.new(0,0,0)
        crouchHeld, velocity = false, Vector3.new()
    end
end

-- [MODIFICADO] UI LÓGICA (Solo móvil, alineado a lo pedido)
local function createGui()
    local g = Instance.new("ScreenGui", gui)
    g.ResetOnSpawn = false
    g.Name = "SourceDBG"
    
    local toggle = Instance.new("TextButton", g)
    toggle.Size = UDim2.new(0, 60, 0, 25)
    toggle.Position = UDim2.new(1, -70, 0, 80)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
    toggle.Text = "ON"
    toggle.MouseButton1Click:Connect(toggleScript)

    -- Fix: Solo aparece si NO hay teclado (PC)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobile then
        -- Salto (Tamaño y posición Roblox Original)
        local jumpButton = Instance.new("TextButton", g)
        jumpButton.Size = UDim2.new(0, 110, 0, 110)
        jumpButton.Position = UDim2.new(1, -145, 1, -155)
        jumpButton.BackgroundTransparency = 0.5
        jumpButton.BackgroundColor3 = Color3.new(0,0,0)
        jumpButton.Text = "JUMP"
        jumpButton.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", jumpButton).CornerRadius = UDim.new(1, 0)
        jumpButton.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then spaceHeld = true end end)
        jumpButton.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then spaceHeld = false end end)
        
        -- Crouch (Al lado del salto)
        local crouchButton = Instance.new("TextButton", g)
        crouchButton.Size = UDim2.new(0, 80, 0, 80)
        crouchButton.Position = UDim2.new(1, -235, 1, -125)
        crouchButton.BackgroundTransparency = 0.5
        crouchButton.BackgroundColor3 = Color3.new(0,0,0)
        crouchButton.Text = "C"
        crouchButton.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", crouchButton).CornerRadius = UDim.new(1, 0)
        crouchButton.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then crouchHeld = true end end)
        crouchButton.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then crouchHeld = false end end)

        -- Granada (Arriba del salto)
        local grenadeButton = Instance.new("TextButton", g)
        grenadeButton.Size = UDim2.new(0, 70, 0, 70)
        grenadeButton.Position = UDim2.new(1, -125, 1, -240)
        grenadeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        grenadeButton.Text = "X"
        Instance.new("UICorner", grenadeButton).CornerRadius = UDim.new(1, 0)
        grenadeButton.MouseButton1Click:Connect(fireRocket)

        -- WASD Izquierda
        local layout = {W = UDim2.new(0, 110, 1, -210), A = UDim2.new(0, 30, 1, -130), S = UDim2.new(0, 110, 1, -130), D = UDim2.new(0, 190, 1, -130)}
        for key, pos in pairs(layout) do
            local btn = Instance.new("TextButton", g)
            btn.Size = UDim2.new(0, 70, 0, 70)
            btn.Position = pos
            btn.BackgroundTransparency = 0.5
            btn.BackgroundColor3 = Color3.new(0,0,0)
            btn.Text = key
            btn.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", btn)
            btn.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then mobileInputs[key] = true end end)
            btn.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then mobileInputs[key] = false end end)
        end
    end
end
createGui()

-- [RESTAURADO COMPLETO] Proceso de Física y Movimiento (ABH + PASOS)
local function process(dt)
    if not scriptEnabled then return end
    humanoid.WalkSpeed, humanoid.JumpPower, humanoid.AutoRotate = 0, 0, false

    targetCameraOffset = crouchHeld and -2.5 or 0
    currentCameraOffset = currentCameraOffset + (targetCameraOffset - currentCameraOffset) * math.min(dt * crouchSpeed, 1)
    humanoid.CameraOffset = Vector3.new(0, currentCameraOffset, 0)

    wasGrounded = isGrounded
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    local res = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    isGrounded = res and res.Instance and res.Instance.CanCollide

    if isGrounded and not wasGrounded then playLand() end

    local cam = workspace.CurrentCamera
    local fwd = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
    local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
    local input = Vector3.new()
    local sPressed = false

    -- Entrada Híbrida
    if UserInputService.KeyboardEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then input += fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then input -= fwd sPressed = true end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then input -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then input += right end
    end
    if mobileInputs.W then input += fwd end
    if mobileInputs.S then input -= fwd sPressed = true end
    if mobileInputs.A then input -= right end
    if mobileInputs.D then input += right end
    
    moveDir = input.Magnitude > 0 and input.Unit or Vector3.new()
    root.CFrame = CFrame.new(root.Position, root.Position + fwd)

    local currentForwardSpeed = velocity:Dot(fwd)
    local currentTotalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

    if isGrounded then
        if not (spaceHeld and crouchHeld and currentForwardSpeed < -1) then
            -- Friction
            local speed = velocity.Magnitude
            if not spaceHeld and speed > 0.1 then
                local drop = math.max(speed, cfg.stopSpeed) * (crouchHeld and 0.4 or cfg.friction) * dt
                velocity *= math.max(speed - drop, 0) / speed
            end
            -- Accel Ground
            local curS = velocity:Dot(moveDir)
            local addS = cfg.runSpeed - curS
            if addS > 0 then velocity += moveDir * math.min(cfg.groundAccel * dt * cfg.runSpeed, addS) end
        end

        if spaceHeld then
            playJump()
            -- ABH Lógica
            if currentForwardSpeed < 0.1 and currentTotalSpeed > (cfg.runSpeed + 4) and not sPressed and crouchHeld then 
                velocity += (fwd * ((cfg.runSpeed - currentForwardSpeed) * 0.25 * -1))
            end
            velocity = Vector3.new(velocity.X, cfg.jumpPower, velocity.Z)
        else
            velocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
        
        -- PASOS (Restaurado)
        if moveDir.Magnitude > 0.1 then
            footstepTimer += dt
            if footstepTimer >= footstepInterval then playFootstep() footstepTimer = 0 end
        end
    else
        -- Air Accel
        local curAS = velocity:Dot(moveDir)
        local addAS = cfg.maxAirSpeed - curAS
        if addAS > 0 then velocity += moveDir * math.min(cfg.airAccel * dt * cfg.maxAirSpeed, addAS) end
        velocity += Vector3.new(0, -cfg.gravity * dt, 0)
    end
    
    root.AssemblyLinearVelocity = velocity
end

-- [RESTAURADO] Daño de caída persistente
local FALL_THRESHOLD = -100
local FIXED_DAMAGE = 10
local function iniciarDanioDeCaida(char)
    local hum = char:WaitForChild("Humanoid")
    local rtp = char:WaitForChild("HumanoidRootPart")
    local lastV = 0
    RunService.Heartbeat:Connect(function()
        if not char:IsDescendantOf(workspace) then return end
        local curV = rtp.AssemblyLinearVelocity.Y
        if lastV < FALL_THRESHOLD and curV >= -1 then
            hum.Health = math.max(0, hum.Health - FIXED_DAMAGE)
        end
        lastV = curV
    end)
end

-- Conexiones finales
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = true
    elseif i.KeyCode == Enum.KeyCode.C then crouchHeld = true
    elseif i.KeyCode == Enum.KeyCode.X then fireRocket()
    elseif i.KeyCode == Enum.KeyCode.R then toggleScript() end
end)
UserInputService.InputEnded:Connect(function(i) 
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = false 
    elseif i.KeyCode == Enum.KeyCode.C then crouchHeld = false end 
end)
RunService.Heartbeat:Connect(function(dt) if humanoid and humanoid.Health > 0 then process(dt) end end)
player.CharacterAdded:Connect(function(char)
    character, humanoid, root = char, char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
    velocity = Vector3.new()
    iniciarDanioDeCaida(char)
end)
if player.Character then task.spawn(iniciarDanioDeCaida, player.Character) end
