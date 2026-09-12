-----/Loadstrings/-----
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Library/Source.lua"))()

-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UILib = {}
UILib.__index = UILib

-----/Values/-----
local Theme = {
	Background = Color3.fromRGB(0, 0, 0),
	BackgroundLight = Color3.fromRGB(10, 10, 10),

	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.8,

	Text = Color3.fromRGB(255, 255, 255),
	Placeholder = Color3.fromRGB(120, 120, 120),

	Font = Enum.Font.Code,

	CornerRadius = UDim.new(0, 10),
	CornerRadiusSmall = UDim.new(0, 6),

	TweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	TweenInfoFast = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	TweenInfoDrag = TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
}

-----/Functions/-----
local function ApplyCorner(UIElement, Radius)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = Radius or Theme.CornerRadius
	Corner.Parent = UIElement

	return Corner
end

local function ApplyStroke(UIElement, Thickness)
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Theme.Stroke
	Stroke.Transparency = Theme.StrokeTransparency
	Stroke.Thickness = Thickness or 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = UIElement

	return Stroke
end

local function ApplyTextStyle(UIElement)
	UIElement.Font = Theme.Font
	UIElement.TextColor3 = Theme.Text
	UIElement.TextSize = 14

	return UIElement
end

-----/Window/-----
function UILib:CreateWindow(UITitle)
	UITitle = UITitle or "UI Lib"

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = UITitle
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	local Main = Instance.new("CanvasGroup")
	Main.Name = "Main"
	Main.Size = UDim2.new(0, 480, 0, 360)
	Main.Position = UDim2.new(0.5, -240, 0.5, -180)
	Main.BackgroundColor3 = Theme.Background
	Main.BorderSizePixel = 0
	Main.Parent = ScreenGui

	Library:Drag(Main)
	Library:Cells(Main)
	Library:Stars(Main)

	ApplyCorner(Main)
	ApplyStroke(Main, 1)

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 34)
	TopBar.BackgroundColor3 = Theme.BackgroundLight
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Main

	ApplyCorner(TopBar)
	ApplyStroke(TopBar, 1)

	local Fix = Instance.new("Frame")
	Fix.Name = "Fix"
	Fix.Size = UDim2.new(1, 0, 0, 10)
	Fix.Position = UDim2.new(0, 0, 1, -10)
	Fix.BackgroundColor3 = Theme.BackgroundLight
	Fix.BorderSizePixel = 0
	Fix.ZIndex = 0
	Fix.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, -20, 1, 0)
	Title.Position = UDim2.new(0, 12, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = UITitle
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar

	ApplyTextStyle(Title)
	Title.TextSize = 15

	local TabHolder = Instance.new("Frame")
	TabHolder.Name = "TabHolder"
	TabHolder.Size = UDim2.new(0, 120, 1, -44)
	TabHolder.Position = UDim2.new(0, 6, 0, 40)
	TabHolder.BackgroundTransparency = 1
	TabHolder.Parent = Main

	local TabList = Instance.new("UIListLayout")
	TabList.Padding = UDim.new(0, 6)
	TabList.SortOrder = Enum.SortOrder.LayoutOrder
	TabList.Parent = TabHolder

	local Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Size = UDim2.new(1, -140, 1, -44)
	Container.Position = UDim2.new(0, 132, 0, 40)
	Container.BackgroundColor3 = Theme.BackgroundLight
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = true
	Container.Parent = Main

	ApplyCorner(Container, Theme.CornerRadiusSmall)
	ApplyStroke(Container, 1)

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		TopBar = TopBar,
		Title = Title,
		TabHolder = TabHolder,
		Container = Container,
		Tabs = {},
	}, UILib)

	return Window
end

-----/Tabs/-----
function UILib:CreateTab(Name)
	Name = Name or "Tab"

	local TabButton = Instance.new("TextButton")
	TabButton.Name = Name .. "Button"
	TabButton.Size = UDim2.new(1, 0, 0, 32)
	TabButton.BackgroundColor3 = Theme.BackgroundLight
	TabButton.AutoButtonColor = false
	TabButton.Text = ""
	TabButton.Parent = self.TabHolder

	ApplyCorner(TabButton, Theme.CornerRadiusSmall)
	ApplyStroke(TabButton, 1)

	local TabLabel = Instance.new("TextLabel")
	TabLabel.Name = "Label"
	TabLabel.Size = UDim2.new(1, -10, 1, 0)
	TabLabel.Position = UDim2.new(0, 8, 0, 0)
	TabLabel.BackgroundTransparency = 1
	TabLabel.Text = Name
	TabLabel.TextXAlignment = Enum.TextXAlignment.Left
	TabLabel.Parent = TabButton

	ApplyTextStyle(TabLabel)

	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name .. "Page"
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = Theme.Stroke
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Visible = #self.Tabs == 0
	Page.Parent = self.Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 8)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Page

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Page

	local TabObject = {
		Name = Name,
		Button = TabButton,
		Label = TabLabel,
		Page = Page,
	}

	table.insert(self.Tabs, TabObject)

	local function SelectTab()
		for _, Tab in ipairs(self.Tabs) do
			Tab.Page.Visible = false

			TweenService:Create(Tab.Button, Theme.TweenInfo, {
				BackgroundColor3 = Theme.BackgroundLight
			}):Play()
		end

		Page.Visible = true

		TweenService:Create(TabButton, Theme.TweenInfo, {
			BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		}):Play()
	end

	TabButton.MouseButton1Click:Connect(SelectTab)

	if #self.Tabs == 1 then
		TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end

	local TabMethods = {}
	TabMethods.__index = TabMethods

	-----/Label/-----
	function TabMethods:CreateLabel(Text)
		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, 0, 0, 20)
		Label.BackgroundTransparency = 1
		Label.Text = tostring(Text or "")
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.Parent = Page

		ApplyTextStyle(Label)

		return {
			Object = Label,

			Set = function(_, NewText)
				Label.Text = tostring(NewText or "")
			end,

			Get = function()
				return Label.Text
			end,
		}
	end

	-----/Button/-----
	function TabMethods:CreateButton(Config)
		Config = Config or {}

		local Button = Instance.new("TextButton")
		Button.Name = "Button"
		Button.Size = UDim2.new(1, 0, 0, 34)
		Button.BackgroundColor3 = Theme.BackgroundLight
		Button.AutoButtonColor = false
		Button.Text = ""
		Button.Parent = Page

		ApplyCorner(Button, Theme.CornerRadiusSmall)
		ApplyStroke(Button, 1)

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, -12, 1, 0)
		Label.Position = UDim2.new(0, 6, 0, 0)
		Label.BackgroundTransparency = 1
		Label.Text = tostring(Config.Text or "Button")
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.Parent = Button

		ApplyTextStyle(Label)

		Button.MouseEnter:Connect(function()
			TweenService:Create(Button, Theme.TweenInfoFast, {
				BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			}):Play()
		end)

		Button.MouseLeave:Connect(function()
			TweenService:Create(Button, Theme.TweenInfoFast, {
				BackgroundColor3 = Theme.BackgroundLight
			}):Play()
		end)

		Button.MouseButton1Click:Connect(function()
			TweenService:Create(Button, Theme.TweenInfoFast, {
				BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			}):Play()

			task.delay(0.12, function()
				if Button.Parent then
					TweenService:Create(Button, Theme.TweenInfo, {
						BackgroundColor3 = Theme.BackgroundLight
					}):Play()
				end
			end)

			if typeof(Config.Callback) == "function" then
				task.spawn(Config.Callback)
			end
		end)

		return Button
	end

	-----/Toggle/-----
	function TabMethods:CreateToggle(Config)
		Config = Config or {}

		local State = Config.Default == true

		local Holder = Instance.new("TextButton")
		Holder.Name = "Toggle"
		Holder.Size = UDim2.new(1, 0, 0, 34)
		Holder.BackgroundColor3 = Theme.BackgroundLight
		Holder.AutoButtonColor = false
		Holder.Text = ""
		Holder.Parent = Page

		ApplyCorner(Holder, Theme.CornerRadiusSmall)
		ApplyStroke(Holder, 1)

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, -50, 1, 0)
		Label.Position = UDim2.new(0, 6, 0, 0)
		Label.BackgroundTransparency = 1
		Label.Text = tostring(Config.Text or "Toggle")
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.Parent = Holder

		ApplyTextStyle(Label)

		local Box = Instance.new("Frame")
		Box.Name = "Box"
		Box.Size = UDim2.new(0, 20, 0, 20)
		Box.Position = UDim2.new(1, -28, 0.5, -10)
		Box.BackgroundColor3 = Theme.Background
		Box.Parent = Holder

		ApplyCorner(Box, UDim.new(0, 5))
		ApplyStroke(Box, 1)

		local Check = Instance.new("Frame")
		Check.Name = "Check"
		Check.AnchorPoint = Vector2.new(0.5, 0.5)
		Check.Size = UDim2.new(0, 12, 0, 12)
		Check.Position = UDim2.new(0.5, 0, 0.5, 0)
		Check.BackgroundColor3 = Theme.Text
		Check.BackgroundTransparency = State and 0 or 1
		Check.Parent = Box

		ApplyCorner(Check, UDim.new(0, 3))

		local function Set(NewState, FireCallback)
			State = NewState == true

			if State then
				Check.BackgroundTransparency = 0
				Check.Size = UDim2.new(0, 6, 0, 6)

				TweenService:Create(Check, Theme.TweenInfo, {
					Size = UDim2.new(0, 12, 0, 12)
				}):Play()
			else
				TweenService:Create(Check, Theme.TweenInfo, {
					Size = UDim2.new(0, 0, 0, 0)
				}):Play()

				task.delay(Theme.TweenInfo.Time, function()
					if not State and Check.Parent then
						Check.BackgroundTransparency = 1
						Check.Size = UDim2.new(0, 12, 0, 12)
					end
				end)
			end

			if FireCallback ~= false and typeof(Config.Callback) == "function" then
				task.spawn(Config.Callback, State)
			end
		end

		Holder.MouseEnter:Connect(function()
			TweenService:Create(Holder, Theme.TweenInfoFast, {
				BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			}):Play()
		end)

		Holder.MouseLeave:Connect(function()
			TweenService:Create(Holder, Theme.TweenInfoFast, {
				BackgroundColor3 = Theme.BackgroundLight
			}):Play()
		end)

		Holder.MouseButton1Click:Connect(function()
			Set(not State)
		end)

		return {
			Object = Holder,
			Set = function(_, NewState)
				Set(NewState)
			end,
			Get = function()
				return State
			end,
		}
	end

	-----/Slider/-----
	function TabMethods:CreateSlider(Config)
		Config = Config or {}

		local Min = tonumber(Config.Min) or 0
		local Max = tonumber(Config.Max) or 100

		if Max < Min then
			Min, Max = Max, Min
		end

		local Value = tonumber(Config.Default) or Min
		Value = math.clamp(Value, Min, Max)

		local Holder = Instance.new("Frame")
		Holder.Name = "Slider"
		Holder.Size = UDim2.new(1, 0, 0, 44)
		Holder.BackgroundColor3 = Theme.BackgroundLight
		Holder.Parent = Page

		ApplyCorner(Holder, Theme.CornerRadiusSmall)
		ApplyStroke(Holder, 1)

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, -12, 0, 18)
		Label.Position = UDim2.new(0, 6, 0, 2)
		Label.BackgroundTransparency = 1
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.Parent = Holder

		ApplyTextStyle(Label)

		local Track = Instance.new("Frame")
		Track.Name = "Track"
		Track.Size = UDim2.new(1, -16, 0, 6)
		Track.Position = UDim2.new(0, 8, 1, -14)
		Track.BackgroundColor3 = Theme.Background
		Track.Parent = Holder

		ApplyCorner(Track, UDim.new(0, 3))
		ApplyStroke(Track, 1)

		local Fill = Instance.new("Frame")
		Fill.Name = "Fill"
		Fill.BackgroundColor3 = Theme.Text
		Fill.Parent = Track

		ApplyCorner(Fill, UDim.new(0, 3))

		local Dragging = false

		local function UpdateLabel()
			Label.Text = tostring(Config.Text or "Slider") .. " : " .. tostring(Value)
		end

		local function Set(NewValue, FireCallback)
			NewValue = tonumber(NewValue)

			if not NewValue then
				return
			end

			NewValue = math.clamp(NewValue, Min, Max)

			if Config.Rounding ~= false then
				NewValue = math.floor(NewValue + 0.5)
			end

			Value = NewValue

			local Alpha = 0

			if Max ~= Min then
				Alpha = (Value - Min) / (Max - Min)
			end

			TweenService:Create(Fill, Theme.TweenInfoDrag, {
				Size = UDim2.new(Alpha, 0, 1, 0)
			}):Play()

			UpdateLabel()

			if FireCallback ~= false and typeof(Config.Callback) == "function" then
				task.spawn(Config.Callback, Value)
			end
		end

		local function UpdateFromInput(InputX)
			if Track.AbsoluteSize.X <= 0 then
				return
			end

			local Alpha = math.clamp(
				(InputX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X,
				0,
				1
			)

			Set(Min + (Max - Min) * Alpha)
		end

		UpdateLabel()

		local InitialAlpha = 0

		if Max ~= Min then
			InitialAlpha = (Value - Min) / (Max - Min)
		end

		Fill.Size = UDim2.new(InitialAlpha, 0, 1, 0)

		Track.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				UpdateFromInput(Input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = false
			end
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
				UpdateFromInput(Input.Position.X)
			end
		end)

		return {
			Object = Holder,
			Set = function(_, NewValue)
				Set(NewValue)
			end,
			Get = function()
				return Value
			end,
		}
	end

	```lua
-----/ColorPicker/-----
function TabMethods:CreateColorPicker(Config)
	Config = Config or {}

	local Value = typeof(Config.Default) == "Color3" and Config.Default or Color3.fromRGB(255,255,255)

	local Holder = Instance.new("TextButton")
	Holder.Name = "ColorPicker"
	Holder.Size = UDim2.new(1,0,0,34)
	Holder.BackgroundColor3 = Theme.BackgroundLight
	Holder.AutoButtonColor = false
	Holder.Text = ""
	Holder.Parent = Page

	ApplyCorner(Holder,Theme.CornerRadiusSmall)
	ApplyStroke(Holder,1)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(1,-48,1,0)
	Label.Position = UDim2.new(0,6,0,0)
	Label.BackgroundTransparency = 1
	Label.Text = tostring(Config.Text or "Color")
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Holder

	ApplyTextStyle(Label)

	local Preview = Instance.new("Frame")
	Preview.Name = "Preview"
	Preview.Size = UDim2.new(0,24,0,24)
	Preview.Position = UDim2.new(1,-30,0.5,-12)
	Preview.BackgroundColor3 = Value
	Preview.BorderSizePixel = 0
	Preview.Parent = Holder

	ApplyCorner(Preview,UDim.new(0,5))
	ApplyStroke(Preview,1)

	local PickerGui = Instance.new("ScreenGui")
	PickerGui.Name = "ColorPicker"
	PickerGui.ResetOnSpawn = false
	PickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	PickerGui.Enabled = false
	PickerGui.Parent = PlayerGui

	local Picker = Instance.new("CanvasGroup")
	Picker.Name = "Window"
	Picker.Size = UDim2.new(0,260,0,220)
	Picker.AnchorPoint = Vector2.new(0.5,0.5)
	Picker.Position = UDim2.new(0.5,0,0.5,0)
	Picker.BackgroundColor3 = Theme.Background
	Picker.BorderSizePixel = 0
	Picker.GroupTransparency = 1
	Picker.Parent = PickerGui

	ApplyCorner(Picker)
	ApplyStroke(Picker,1)

	local PickerTitle = Instance.new("TextLabel")
	PickerTitle.Name = "Title"
	PickerTitle.Size = UDim2.new(1,-40,0,32)
	PickerTitle.Position = UDim2.new(0,10,0,0)
	PickerTitle.BackgroundTransparency = 1
	PickerTitle.Text = tostring(Config.Text or "Color Picker")
	PickerTitle.TextXAlignment = Enum.TextXAlignment.Left
	PickerTitle.Parent = Picker

	ApplyTextStyle(PickerTitle)
	PickerTitle.TextSize = 15

	local Close = Instance.new("TextButton")
	Close.Name = "Close"
	Close.Size = UDim2.new(0,28,0,28)
	Close.Position = UDim2.new(1,-32,0,2)
	Close.BackgroundTransparency = 1
	Close.Text = "×"
	Close.Parent = Picker

	ApplyTextStyle(Close)
	Close.TextSize = 20

	local ColorBox = Instance.new("Frame")
	ColorBox.Name = "ColorBox"
	ColorBox.Size = UDim2.new(1,-20,0,120)
	ColorBox.Position = UDim2.new(0,10,0,40)
	ColorBox.BackgroundColor3 = Value
	ColorBox.BorderSizePixel = 0
	ColorBox.Parent = Picker

	ApplyCorner(ColorBox,Theme.CornerRadiusSmall)
	ApplyStroke(ColorBox,1)

	local Input = Instance.new("TextBox")
	Input.Name = "RGB"
	Input.Size = UDim2.new(1,-20,0,32)
	Input.Position = UDim2.new(0,10,1,-42)
	Input.BackgroundColor3 = Theme.BackgroundLight
	Input.BorderSizePixel = 0
	Input.ClearTextOnFocus = false
	Input.PlaceholderText = "255,255,255"
	Input.PlaceholderColor3 = Theme.Placeholder
	Input.Text = string.format("%d,%d,%d",Value.R*255,Value.G*255,Value.B*255)
	Input.TextXAlignment = Enum.TextXAlignment.Left
	Input.Parent = Picker

	ApplyCorner(Input,Theme.CornerRadiusSmall)
	ApplyStroke(Input,1)
	ApplyTextStyle(Input)

	local function UpdateColor(NewColor,FireCallback)
		if typeof(NewColor) ~= "Color3" then
			return
		end

		Value = NewColor
		Preview.BackgroundColor3 = Value
		ColorBox.BackgroundColor3 = Value
		Input.Text = string.format("%d,%d,%d",Value.R*255,Value.G*255,Value.B*255)

		if FireCallback ~= false and typeof(Config.Callback) == "function" then
			task.spawn(Config.Callback,Value)
		end
	end

	local function ParseRGB(Text)
		local R,G,B = string.match(Text,"(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")

		R = tonumber(R)
		G = tonumber(G)
		B = tonumber(B)

		if not R or not G or not B then
			return
		end

		R = math.clamp(R,0,255)
		G = math.clamp(G,0,255)
		B = math.clamp(B,0,255)

		UpdateColor(Color3.fromRGB(R,G,B))
	end

	Input.FocusLost:Connect(function()
		ParseRGB(Input.Text)
	end)

	local Open = false

	local function SetVisible(State)
		Open = State == true

		if Open then
			PickerGui.Enabled = true
			Picker.Size = UDim2.new(0,240,0,200)
			Picker.GroupTransparency = 1

			TweenService:Create(Picker,Theme.TweenInfo,{
				Size = UDim2.new(0,260,0,220),
				GroupTransparency = 0
			}):Play()
		else
			local Tween = TweenService:Create(Picker,Theme.TweenInfo,{
				Size = UDim2.new(0,240,0,200),
				GroupTransparency = 1
			})

			Tween:Play()

			Tween.Completed:Once(function()
				if not Open then
					PickerGui.Enabled = false
				end
			end)
		end
	end

	Holder.MouseEnter:Connect(function()
		TweenService:Create(Holder,Theme.TweenInfoFast,{
			BackgroundColor3 = Color3.fromRGB(18,18,18)
		}):Play()
	end)

	Holder.MouseLeave:Connect(function()
		TweenService:Create(Holder,Theme.TweenInfoFast,{
			BackgroundColor3 = Theme.BackgroundLight
		}):Play()
	end)

	Holder.MouseButton1Click:Connect(function()
		SetVisible(not Open)
	end)

	Close.MouseButton1Click:Connect(function()
		SetVisible(false)
	end)

	return {
		Object = Holder,
		Set = function(_,NewColor)
			UpdateColor(NewColor)
		end,
		Get = function()
			return Value
		end,
		Open = function()
			SetVisible(true)
		end,
		Close = function()
			SetVisible(false)
		end,
	}
end
```


	-----/Textbox/-----
	function TabMethods:CreateTextbox(Config)
		Config = Config or {}

		local Holder = Instance.new("Frame")
		Holder.Name = "Textbox"
		Holder.Size = UDim2.new(1, 0, 0, 34)
		Holder.BackgroundColor3 = Theme.BackgroundLight
		Holder.Parent = Page

		ApplyCorner(Holder, Theme.CornerRadiusSmall)
		ApplyStroke(Holder, 1)

		local Box = Instance.new("TextBox")
		Box.Name = "Input"
		Box.Size = UDim2.new(1, -12, 1, 0)
		Box.Position = UDim2.new(0, 6, 0, 0)
		Box.BackgroundTransparency = 1
		Box.PlaceholderText = tostring(Config.Placeholder or "")
		Box.Text = tostring(Config.Text or "")
		Box.ClearTextOnFocus = false
		Box.PlaceholderColor3 = Theme.Placeholder
		Box.TextXAlignment = Enum.TextXAlignment.Left
		Box.Parent = Holder

		ApplyTextStyle(Box)

		Box.Focused:Connect(function()
			TweenService:Create(Holder, Theme.TweenInfoFast, {
				BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			}):Play()
		end)

		Box.FocusLost:Connect(function(EnterPressed)
			TweenService:Create(Holder, Theme.TweenInfoFast, {
				BackgroundColor3 = Theme.BackgroundLight
			}):Play()

			if typeof(Config.Callback) == "function" then
				task.spawn(Config.Callback, Box.Text, EnterPressed)
			end
		end)

		return {
			Object = Holder,
			TextBox = Box,

			Set = function(_, Text)
				Box.Text = tostring(Text or "")
			end,

			Get = function()
				return Box.Text
			end,

			Clear = function()
				Box.Text = ""
			end,

			Focus = function()
				Box:CaptureFocus()
			end,

			Release = function()
				Box:ReleaseFocus()
			end,
		}
	end

	-----/Tab Methods/-----
	function TabMethods:SetVisible(State)
		Page.Visible = State == true
	end

	function TabMethods:GetVisible()
		return Page.Visible
	end

	function TabMethods:Select()
		SelectTab()
	end

	function TabMethods:Destroy()
		local Index = table.find(self.Tabs, TabObject)

		if Index then
			table.remove(self.Tabs, Index)
		end

		TabButton:Destroy()
		Page:Destroy()
	end

	return setmetatable(TabObject, TabMethods)
end

-----/Window Methods/-----
function UILib:SetTitle(NewTitle)
	if self.Title then
		self.Title.Text = tostring(NewTitle or "")
	end
end

function UILib:GetTitle()
	if self.Title then
		return self.Title.Text
	end

	return nil
end

function UILib:SelectTab(Tab)
	if typeof(Tab) == "table" then
		if Tab.Select then
			Tab:Select()
		end

		return
	end

	for _, CurrentTab in ipairs(self.Tabs) do
		if CurrentTab.Name == Tab then
			for _, OtherTab in ipairs(self.Tabs) do
				OtherTab.Page.Visible = false

				TweenService:Create(OtherTab.Button, Theme.TweenInfo, {
					BackgroundColor3 = Theme.BackgroundLight
				}):Play()
			end

			CurrentTab.Page.Visible = true

			TweenService:Create(CurrentTab.Button, Theme.TweenInfo, {
				BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			}):Play()

			break
		end
	end
end

function UILib:SetVisible(State)
	if self.ScreenGui then
		self.ScreenGui.Enabled = State == true
	end
end

function UILib:GetVisible()
	if self.ScreenGui then
		return self.ScreenGui.Enabled
	end

	return false
end

function UILib:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	self.Tabs = {}
end

-----/Return/-----
return UILib
