local Player = Players.LocalPlayer or owner

-----/Services/-----
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-----/Variables/-----
local Backpack = Player:WaitForChild("Backpack")

-----/Main/-----
local function CreateModel(Position, ThrowDirection)
	local Model = Instance.new("Model")
	Model.Name = "Penis"

	local function CreatePart(Name, Size, PartPosition, Rotate, Color, Shape)
		local Part = Instance.new("Part")
		Part.Name = Name
		Part.Size = Size
		Part.Orientation = Rotate or Vector3.new(0, 0, 0)
		Part.Color = Color or Color3.fromRGB(255, 0, 200)
		Part.Material = Enum.Material.Plastic
		Part.Shape = Shape or Enum.PartType.Block
		Part.CanCollide = true
		Part.Anchored = false
		Part.Position = PartPosition
		Part.Parent = Model
		
		spawn(function()
			Part.TopSurface = Enum.SurfaceType.Studs
			Part.BottomSurface = Enum.SurfaceType.Studs
			
			Part.FrontSurface = Enum.SurfaceType.Studs
			Part.BackSurface = Enum.SurfaceType.Studs
			
			Part.RightSurface = Enum.SurfaceType.Studs
			Part.LeftSurface = Enum.SurfaceType.Studs
		end)

		return Part
	end

	local Top = CreatePart(
		"TopCircle",
		Vector3.new(10, 10, 10),
		Position + Vector3.new(0, 10, 0),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(200, 0, 150),
		Enum.PartType.Ball
	)

	local Stick = CreatePart(
		"Stick",
		Vector3.new(20, 5, 5),
		Position,
		Vector3.new(0, 0, -90),
		Color3.fromRGB(255, 0, 200),
		Enum.PartType.Cylinder
	)

	local Circle1 = CreatePart(
		"CircleLeft",
		Vector3.new(10, 10, 10),
		Position + Vector3.new(-4, -10, 0),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(255, 0, 200),
		Enum.PartType.Ball
	)

	local Circle2 = CreatePart(
		"CircleRight",
		Vector3.new(10, 10, 10),
		Position + Vector3.new(4, -10, 0),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(255, 0, 200),
		Enum.PartType.Ball
	)

	Model.Parent = workspace

	for _, Part in pairs(Model:GetChildren()) do
		local Weld = Instance.new("WeldConstraint")
		Weld.Part0 = Stick
		Weld.Part1 = Part
		Weld.Parent = Stick
		
		Part.Touched:Connect(function(Hit)
			if Part.AssemblyLinearVelocity.Magnitude > 25 then
				if Hit.Parent:FindFirstChild("Humanoid") then
					Hit.Parent:FindFirstChild("Humanoid"):TakeDamage(25)
				end
			end
		end)
	end

	if ThrowDirection then
		local Velocity = Instance.new("BodyVelocity")
		Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		Velocity.Velocity = ThrowDirection * 500 + Vector3.new(0, 80, 0)
		Velocity.Parent = Stick

		Debris:AddItem(Velocity, 0.01)
	end
	
	spawn(function()
		local RandomRotateX = math.random(-360, 360)
		local RandomRotateY = math.random(-360, 360)
		local RandomRotateZ = math.random(-360, 360)

		Model.Orientation = Vector3.new(RandomRotateX, RandomRotateY, RandomRotateZ)
	end)
end

local ThrowTool = Instance.new("Tool")
ThrowTool.Name = "Penis"
ThrowTool.RequiresHandle = false
ThrowTool.Parent = Backpack

ThrowTool.Activated:Connect(function()
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Root = Character:WaitForChild("HumanoidRootPart")

	CreateModel(
		Root.Position + Root.CFrame.LookVector * 25 + Vector3.new(0, 0, 10),
		Root.CFrame.LookVector
	)
end)

local RainTool = Instance.new("Tool")
RainTool.Name = "Penis Rain"
RainTool.RequiresHandle = false
RainTool.Parent = Backpack

RainTool.Activated:Connect(function()
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Root = Character:WaitForChild("HumanoidRootPart")

	for i = 1, 100 do
		task.wait(math.random(1, 10) / 100)

		CreateModel(
			Root.Position + Vector3.new(
				math.random(-500, 500),
				math.random(60, 120),
				math.random(-500, 500)
			)
		)
	end
end)
