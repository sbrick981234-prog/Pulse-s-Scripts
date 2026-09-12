-----/Services/-----
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-----/Variables/-----
local Library = {}

-----/Functions/-----
function Library:Drag(Frame)
	local Dragging = false
	local DragStart = nil
	local StartPosition = nil

	local TweenInfoData = TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

	Frame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPosition = Frame.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end

		if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local Delta = Input.Position - DragStart

		local NewPosition = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)

		TweenService:Create(Frame,TweenInfoData,{Position = NewPosition}):Play()
	end)

	return Frame
end

function Library:Cells(Frame)
	local GridSize = 60
	local LineThickness = 1
	local LineColor = Color3.fromRGB(255,255,255)
	local LineTransparency = 0.95
	local ScrollSpeed = 20

	local Cells = Frame:FindFirstChild("Cells")

	if not Cells then
		Cells = Instance.new("Folder")
		Cells.Name = "Cells"
		Cells.Parent = Frame
	end

	local HorizontalLines = {}

	local function BuildGrid()
		for _,Child in ipairs(Cells:GetChildren()) do
			Child:Destroy()
		end

		table.clear(HorizontalLines)

		local FrameWidth = Frame.AbsoluteSize.X
		local FrameHeight = Frame.AbsoluteSize.Y

		for X = 0,FrameWidth + GridSize,GridSize do
			local Line = Instance.new("Frame")
			Line.Name = "Vertical"
			Line.ZIndex = 0
			Line.BorderSizePixel = 0
			Line.BackgroundColor3 = LineColor
			Line.BackgroundTransparency = LineTransparency
			Line.Size = UDim2.new(0,LineThickness,1,0)
			Line.Position = UDim2.fromOffset(X,0)
			Line.Parent = Cells
		end

		for Y = -GridSize,FrameHeight + GridSize,GridSize do
			local Line = Instance.new("Frame")
			Line.Name = "Horizontal"
			Line.ZIndex = 0
			Line.BorderSizePixel = 0
			Line.BackgroundColor3 = LineColor
			Line.BackgroundTransparency = LineTransparency
			Line.Size = UDim2.new(1,0,0,LineThickness)
			Line.Position = UDim2.fromOffset(0,Y)
			Line.Parent = Cells

			table.insert(HorizontalLines,{
				Object = Line,
				StartY = Y
			})
		end
	end

	task.wait()
	BuildGrid()

	Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(BuildGrid)

	local Offset = 0

	RunService.RenderStepped:Connect(function(DeltaTime)
		if not Frame.Parent then
			return
		end

		Offset = (Offset + ScrollSpeed * DeltaTime) % GridSize

		for _,Data in ipairs(HorizontalLines) do
			if Data.Object.Parent then
				local Y = Data.StartY + Offset
				Data.Object.Position = UDim2.fromOffset(0,math.floor(Y + 0.5))
			end
		end
	end)

	return Cells
end

function Library:Stars(Frame)
	local StarLifeTime = 5
	local StarRate = 0.1
	local StarSize = 1

	local StarFolder = Frame:FindFirstChild("Stars")

	if not StarFolder then
		StarFolder = Instance.new("Folder")
		StarFolder.Name = "Stars"
		StarFolder.Parent = Frame
	end

	local function CreateStar(Position)
		local Star = Instance.new("Frame")
		Star.Name = "Star"
		Star.Size = UDim2.new(0,0,0,0)
		Star.Position = Position
		Star.Rotation = math.random(0,360)
		Star.BackgroundColor3 = Color3.fromRGB(255,255,255)
		Star.BackgroundTransparency = 1
		Star.BorderSizePixel = 0
		Star.ZIndex = 0
		Star.Parent = StarFolder

		Debris:AddItem(Star,StarLifeTime)

		local StartTween = TweenService:Create(
			Star,
			TweenInfo.new(StarLifeTime / 2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
			{
				Size = UDim2.new(0,StarSize,0,StarSize),
				BackgroundTransparency = 0.5
			}
		)

		StartTween:Play()

		StartTween.Completed:Connect(function()
			if not Star.Parent then
				return
			end

			local EndTween = TweenService:Create(
				Star,
				TweenInfo.new(StarLifeTime / 2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0,0,0,0),
					BackgroundTransparency = 1
				}
			)

			EndTween:Play()
		end)
	end

	task.spawn(function()
		while Frame.Parent do
			local X = math.random(0,100) / 100
			local Y = math.random(0,100) / 100

			CreateStar(UDim2.new(X,0,Y,0))

			task.wait(StarRate)
		end
	end)

	return StarFolder
end

-----/Main/-----
return Library
