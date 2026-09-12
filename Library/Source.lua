-----/Services/-----
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-----/Variables-----
local SmoothDrag = {}

-----/Functions-----
function SmoothDrag:Attach(Frame)
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

-----/Main-----
return SmoothDrag
