-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Tracks = {}
local CurrentIndex = 0
local CurrentSound = nil
local IsLooping = false
local InputMode = "Import"

local PendingVolume = 1
local PendingSpeed = 1
local PendingPitch = 1

local Colors = {
	Background = Color3.fromRGB(0, 0, 0),
	Panel = Color3.fromRGB(7, 7, 7),
	PanelAlt = Color3.fromRGB(10, 10, 10),
	Accent = Color3.fromRGB(168, 85, 247),
	AccentDim = Color3.fromRGB(122, 66, 178),
	Danger = Color3.fromRGB(200, 60, 60),
	White = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(150, 150, 150),
	GrayDark = Color3.fromRGB(100, 100, 100)
}

-----/Functions/-----
local function Create(ClassName, Properties)
	local Object = Instance.new(ClassName)

	for Property, Value in pairs(Properties) do
		Object[Property] = Value
	end

	return Object
end

local function Corner(Parent, Radius)
	local Object = Instance.new("UICorner")
	Object.CornerRadius = UDim.new(0, Radius)
	Object.Parent = Parent
	return Object
end

local function Stroke(Parent, Transparency, Color)
	local Object = Instance.new("UIStroke")
	Object.Color = Color or Color3.fromRGB(255, 255, 255)
	Object.Transparency = Transparency
	Object.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Object.Parent = Parent
	return Object
end

local function Hover(Object, NormalColor, HoverColor)
	Object.MouseEnter:Connect(function()
		TweenService:Create(Object, TweenInfo.new(0.15), {BackgroundColor3 = HoverColor}):Play()
	end)

	Object.MouseLeave:Connect(function()
		TweenService:Create(Object, TweenInfo.new(0.15), {BackgroundColor3 = NormalColor}):Play()
	end)
end

local function BindSlider(Bar, Callback)
	local Dragging = false

	local function Update(Input)
		local Percent = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
		Callback(Percent)
	end

	Bar.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			Update(Input)
		end
	end)

	Bar.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			Update(Input)
		end
	end)
end

local function BindStepper(MinusButton, PlusButton, ValueLabel, Get, Set, Min, Max, Step)
	local function Refresh()
		ValueLabel.Text = string.format("%.1f", Get())
	end

	MinusButton.MouseButton1Click:Connect(function()
		Set(math.clamp(Get() - Step, Min, Max))
		Refresh()
	end)

	PlusButton.MouseButton1Click:Connect(function()
		Set(math.clamp(Get() + Step, Min, Max))
		Refresh()
	end)

	Refresh()
end

local function FormatTime(Time)
	Time = math.max(Time, 0)

	local Minutes = math.floor(Time / 60)
	local Seconds = math.floor(Time % 60)

	return string.format("%d:%02d", Minutes, Seconds)
end

local function GetSoundId(Id)
	Id = tostring(Id):gsub("%s+", "")

	if Id:find("rbxassetid://") then
		return Id
	end

	return "rbxassetid://" .. Id
end

local function EncodeTrack(Track)
	return table.concat({
		Track.Id,
		"Volume-" .. tostring(Track.Volume),
		"Speed-" .. tostring(Track.Speed),
		"Pitch-" .. tostring(Track.Pitch)
	}, ":")
end

local function ExportTracks()
	local Result = {}

	for _, Track in ipairs(Tracks) do
		table.insert(Result, EncodeTrack(Track))
	end

	return table.concat(Result, ", ")
end

local function ParseTrack(Data)
	local Parts = string.split(Data, ":")

	local Id = Parts[1]
	local Volume = 1
	local Speed = 1
	local Pitch = 1

	for Index = 2, #Parts do
		local Part = Parts[Index]
		local Key, Value = Part:match("([^%-]+)%-(.+)")

		if Key and Value then
			Value = tonumber(Value)

			if Key == "Volume" and Value then
				Volume = Value
			elseif Key == "Speed" and Value then
				Speed = Value
			elseif Key == "Pitch" and Value then
				Pitch = Value
			end
		end
	end

	return {
		Id = Id,
		Volume = Volume,
		Speed = Speed,
		Pitch = Pitch
	}
end

local function ImportTracks(Data)
	table.clear(Tracks)

	for _, TrackData in ipairs(string.split(Data, ",")) do
		TrackData = TrackData:gsub("^%s+", ""):gsub("%s+$", "")

		if TrackData ~= "" then
			local Track = ParseTrack(TrackData)

			if Track.Id and Track.Id ~= "" then
				table.insert(Tracks, Track)
			end
		end
	end
end

-----/Assets/-----
local Sound = Instance.new("Sound")
Sound.Name = "SkiddifySound"
Sound.Volume = 1
Sound.Parent = PlayerGui

-----/UI/-----
local ScreenGui = Create("ScreenGui", {
	Name = "Skiddify",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = PlayerGui
})

local MainFrame = Create("Frame", {
	Name = "MainFrame",
	Size = UDim2.fromOffset(760, 580),
	Position = UDim2.new(0.5, -380, 0.5, -290),
	BackgroundColor3 = Colors.Background,
	BorderSizePixel = 0,
	Parent = ScreenGui
})

Corner(MainFrame, 10)
Stroke(MainFrame, 0.8)

local TopBar = Create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 55),
	BackgroundTransparency = 1,
	Parent = MainFrame
})

local Title = Create("TextLabel", {
	Name = "Title",
	Size = UDim2.fromOffset(300, 26),
	Position = UDim2.fromOffset(18, 6),
	BackgroundTransparency = 1,
	Text = "Skiddify",
	TextColor3 = Colors.White,
	TextSize = 20,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TopBar
})

local HintLabel = Create("TextLabel", {
	Name = "HintLabel",
	Size = UDim2.fromOffset(300, 18),
	Position = UDim2.fromOffset(18, 31),
	BackgroundTransparency = 1,
	Text = "RightCtrl to hide UI • Enter to add track",
	TextColor3 = Colors.GrayDark,
	TextSize = 11,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TopBar
})

local ExportButton = Create("TextButton", {
	Name = "ExportButton",
	Size = UDim2.fromOffset(90, 34),
	Position = UDim2.new(1, -349, 0, 10),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "Export",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(ExportButton, 7)
Stroke(ExportButton, 0.8)
Hover(ExportButton, Colors.PanelAlt, Colors.Accent)

local ImportButton = Create("TextButton", {
	Name = "ImportButton",
	Size = UDim2.fromOffset(90, 34),
	Position = UDim2.new(1, -247, 0, 10),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "Import",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(ImportButton, 7)
Stroke(ImportButton, 0.8)
Hover(ImportButton, Colors.PanelAlt, Colors.Accent)

local LoopButton = Create("TextButton", {
	Name = "LoopButton",
	Size = UDim2.fromOffset(90, 34),
	Position = UDim2.new(1, -145, 0, 10),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "Loop",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(LoopButton, 7)
Stroke(LoopButton, 0.8)

local CloseButton = Create("TextButton", {
	Name = "CloseButton",
	Size = UDim2.fromOffset(35, 35),
	Position = UDim2.new(1, -45, 0, 10),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "×",
	TextColor3 = Colors.White,
	TextSize = 20,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(CloseButton, 7)
Stroke(CloseButton, 0.8)
Hover(CloseButton, Colors.PanelAlt, Colors.Danger)

local ToastLabel = Create("TextLabel", {
	Name = "ToastLabel",
	Size = UDim2.fromOffset(300, 40),
	Position = UDim2.new(0.5, -150, 1, -70),
	BackgroundColor3 = Colors.PanelAlt,
	BackgroundTransparency = 1,
	TextTransparency = 1,
	Text = "",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	Visible = false,
	ZIndex = 30,
	Parent = ScreenGui
})

Corner(ToastLabel, 8)

-----/TrackList/-----
local SearchBox = Create("TextBox", {
	Name = "SearchBox",
	Size = UDim2.fromOffset(355, 34),
	Position = UDim2.fromOffset(18, 75),
	BackgroundColor3 = Colors.PanelAlt,
	PlaceholderText = "Search tracks...",
	PlaceholderColor3 = Colors.GrayDark,
	Text = "",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	ClearTextOnFocus = false,
	Parent = MainFrame
})

Corner(SearchBox, 7)
Stroke(SearchBox, 0.8)

local TrackList = Create("ScrollingFrame", {
	Name = "TrackList",
	Size = UDim2.fromOffset(355, 445),
	Position = UDim2.fromOffset(18, 117),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Colors.Accent,
	CanvasSize = UDim2.new(),
	Parent = MainFrame
})

Corner(TrackList, 8)
Stroke(TrackList, 0.9)

local TrackLayout = Create("UIListLayout", {
	Padding = UDim.new(0, 6),
	Parent = TrackList
})

local TrackPadding = Create("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	Parent = TrackList
})

local EmptyLabel = Create("TextLabel", {
	Name = "EmptyLabel",
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	Text = "No tracks yet — add one on the right",
	TextColor3 = Colors.GrayDark,
	TextSize = 13,
	Font = Enum.Font.Code,
	TextWrapped = true,
	Visible = false,
	Parent = TrackList
})

-----/Player/-----
local PlayerFrame = Create("Frame", {
	Name = "PlayerFrame",
	Size = UDim2.fromOffset(355, 180),
	Position = UDim2.fromOffset(387, 75),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Parent = MainFrame
})

Corner(PlayerFrame, 8)
Stroke(PlayerFrame, 0.9)

local CurrentLabel = Create("TextLabel", {
	Name = "CurrentLabel",
	Size = UDim2.new(1, -20, 0, 26),
	Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1,
	Text = "Nothing playing",
	TextColor3 = Colors.White,
	TextSize = 16,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = PlayerFrame
})

local TimeLabel = Create("TextLabel", {
	Name = "TimeLabel",
	Size = UDim2.fromOffset(160, 18),
	Position = UDim2.fromOffset(10, 40),
	BackgroundTransparency = 1,
	Text = "0:00 / 0:00",
	TextColor3 = Colors.Gray,
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = PlayerFrame
})

local Progress = Create("Frame", {
	Name = "Progress",
	Size = UDim2.new(1, -20, 0, 4),
	Position = UDim2.fromOffset(10, 64),
	BackgroundColor3 = Colors.PanelAlt,
	BorderSizePixel = 0,
	Parent = PlayerFrame
})

Corner(Progress, 4)

local ProgressFill = Create("Frame", {
	Name = "ProgressFill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Colors.Accent,
	BorderSizePixel = 0,
	Parent = Progress
})

Corner(ProgressFill, 4)

local PlayButton = Create("TextButton", {
	Name = "PlayButton",
	Size = UDim2.fromOffset(42, 32),
	Position = UDim2.fromOffset(156, 80),
	BackgroundColor3 = Colors.Accent,
	Text = "▶",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(PlayButton, 7)
Hover(PlayButton, Colors.Accent, Colors.AccentDim)

local PreviousButton = Create("TextButton", {
	Name = "PreviousButton",
	Size = UDim2.fromOffset(38, 32),
	Position = UDim2.fromOffset(110, 80),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "◀",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(PreviousButton, 7)
Stroke(PreviousButton, 0.8)
Hover(PreviousButton, Colors.PanelAlt, Colors.Accent)

local NextButton = Create("TextButton", {
	Name = "NextButton",
	Size = UDim2.fromOffset(38, 32),
	Position = UDim2.fromOffset(206, 80),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "▶",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(NextButton, 7)
Stroke(NextButton, 0.8)
Hover(NextButton, Colors.PanelAlt, Colors.Accent)

local VolumeLabel = Create("TextLabel", {
	Name = "VolumeLabel",
	Size = UDim2.fromOffset(30, 20),
	Position = UDim2.fromOffset(10, 124),
	BackgroundTransparency = 1,
	Text = "Vol",
	TextColor3 = Colors.Gray,
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = PlayerFrame
})

local VolumeBar = Create("Frame", {
	Name = "VolumeBar",
	Size = UDim2.new(1, -95, 0, 4),
	Position = UDim2.fromOffset(45, 130),
	BackgroundColor3 = Colors.PanelAlt,
	BorderSizePixel = 0,
	Parent = PlayerFrame
})

Corner(VolumeBar, 4)

local VolumeFill = Create("Frame", {
	Name = "VolumeFill",
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundColor3 = Colors.Accent,
	BorderSizePixel = 0,
	Parent = VolumeBar
})

Corner(VolumeFill, 4)

local VolumePercent = Create("TextLabel", {
	Name = "VolumePercent",
	Size = UDim2.fromOffset(35, 20),
	Position = UDim2.new(1, -35, 0, 124),
	BackgroundTransparency = 1,
	Text = "1.0",
	TextColor3 = Colors.Gray,
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = PlayerFrame
})

-----/Add/-----
local AddFrame = Create("Frame", {
	Name = "AddFrame",
	Size = UDim2.fromOffset(355, 293),
	Position = UDim2.fromOffset(387, 269),
	BackgroundColor3 = Colors.Panel,
	BorderSizePixel = 0,
	Parent = MainFrame
})

Corner(AddFrame, 8)
Stroke(AddFrame, 0.9)

local IdBox = Create("TextBox", {
	Name = "IdBox",
	Size = UDim2.new(1, -20, 0, 38),
	Position = UDim2.fromOffset(10, 10),
	BackgroundColor3 = Colors.PanelAlt,
	PlaceholderText = "Sound ID or URL",
	PlaceholderColor3 = Colors.GrayDark,
	Text = "",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	ClearTextOnFocus = false,
	Parent = AddFrame
})

Corner(IdBox, 7)
Stroke(IdBox, 0.8)

local function StepperRow(Name, Y, LabelText)
	local Label = Create("TextLabel", {
		Name = Name .. "Label",
		Size = UDim2.fromOffset(150, 30),
		Position = UDim2.fromOffset(10, Y),
		BackgroundTransparency = 1,
		Text = LabelText,
		TextColor3 = Colors.White,
		TextSize = 13,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = AddFrame
	})

	local MinusButton = Create("TextButton", {
		Name = Name .. "Minus",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.fromOffset(195, Y),
		BackgroundColor3 = Colors.PanelAlt,
		Text = "-",
		TextColor3 = Colors.White,
		TextSize = 16,
		Font = Enum.Font.Code,
		Parent = AddFrame
	})

	Corner(MinusButton, 6)
	Stroke(MinusButton, 0.8)
	Hover(MinusButton, Colors.PanelAlt, Colors.Accent)

	local ValueLabel = Create("TextLabel", {
		Name = Name .. "Value",
		Size = UDim2.fromOffset(55, 30),
		Position = UDim2.fromOffset(230, Y),
		BackgroundTransparency = 1,
		Text = "1.0",
		TextColor3 = Colors.White,
		TextSize = 13,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = AddFrame
	})

	local PlusButton = Create("TextButton", {
		Name = Name .. "Plus",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.fromOffset(290, Y),
		BackgroundColor3 = Colors.PanelAlt,
		Text = "+",
		TextColor3 = Colors.White,
		TextSize = 16,
		Font = Enum.Font.Code,
		Parent = AddFrame
	})

	Corner(PlusButton, 6)
	Stroke(PlusButton, 0.8)
	Hover(PlusButton, Colors.PanelAlt, Colors.Accent)

	return MinusButton, PlusButton, ValueLabel
end

local VolumeMinus, VolumePlus, VolumeValue = StepperRow("Volume", 58, "Volume")
local SpeedMinus, SpeedPlus, SpeedValue = StepperRow("Speed", 98, "Speed")
local PitchMinus, PitchPlus, PitchValue = StepperRow("Pitch", 138, "Pitch")

BindStepper(VolumeMinus, VolumePlus, VolumeValue,
	function() return PendingVolume end,
	function(Value) PendingVolume = Value end,
	0, 2, 0.1)

BindStepper(SpeedMinus, SpeedPlus, SpeedValue,
	function() return PendingSpeed end,
	function(Value) PendingSpeed = Value end,
	0.1, 3, 0.1)

BindStepper(PitchMinus, PitchPlus, PitchValue,
	function() return PendingPitch end,
	function(Value) PendingPitch = Value end,
	0.1, 3, 0.1)

local AddTrackButton = Create("TextButton", {
	Name = "AddTrackButton",
	Size = UDim2.new(1, -20, 0, 40),
	Position = UDim2.fromOffset(10, 182),
	BackgroundColor3 = Colors.Accent,
	Text = "Add Track",
	TextColor3 = Colors.White,
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = AddFrame
})

Corner(AddTrackButton, 7)
Hover(AddTrackButton, Colors.Accent, Colors.AccentDim)

local AddHint = Create("TextLabel", {
	Name = "AddHint",
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.fromOffset(10, 230),
	BackgroundTransparency = 1,
	Text = "Tip: paste an ID or a store link, then press Enter",
	TextColor3 = Colors.GrayDark,
	TextSize = 11,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Parent = AddFrame
})

-----/ImportExport/-----
local InputFrame = Create("Frame", {
	Name = "InputFrame",
	Size = UDim2.fromOffset(600, 300),
	Position = UDim2.new(0.5, -300, 0.5, -150),
	BackgroundColor3 = Colors.Background,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
	Parent = ScreenGui
})

Corner(InputFrame, 10)
Stroke(InputFrame, 0.8)

local InputTitle = Create("TextLabel", {
	Name = "InputTitle",
	Size = UDim2.new(1, -60, 0, 45),
	Position = UDim2.fromOffset(15, 0),
	BackgroundTransparency = 1,
	Text = "Import",
	TextColor3 = Colors.White,
	TextSize = 18,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
	Parent = InputFrame
})

local CloseInput = Create("TextButton", {
	Name = "CloseInput",
	Size = UDim2.fromOffset(35, 35),
	Position = UDim2.new(1, -45, 0, 5),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "×",
	TextColor3 = Colors.White,
	TextSize = 20,
	Font = Enum.Font.Code,
	ZIndex = 21,
	Parent = InputFrame
})

Corner(CloseInput, 7)
Hover(CloseInput, Colors.PanelAlt, Colors.Danger)

local DataBox = Create("TextBox", {
	Name = "DataBox",
	Size = UDim2.new(1, -30, 0, 180),
	Position = UDim2.fromOffset(15, 50),
	BackgroundColor3 = Colors.PanelAlt,
	Text = "",
	PlaceholderText = "43294322432:Volume-1:Speed-1:Pitch-1, 48548352371:Volume-1:Speed-1:Pitch-1",
	PlaceholderColor3 = Colors.GrayDark,
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ClearTextOnFocus = false,
	ZIndex = 21,
	Parent = InputFrame
})

Corner(DataBox, 7)
Stroke(DataBox, 0.8)

local ConfirmInput = Create("TextButton", {
	Name = "ConfirmInput",
	Size = UDim2.fromOffset(130, 35),
	Position = UDim2.new(1, -145, 1, -50),
	BackgroundColor3 = Colors.Accent,
	Text = "Import",
	TextColor3 = Colors.White,
	TextSize = 13,
	Font = Enum.Font.Code,
	ZIndex = 21,
	Parent = InputFrame
})

Corner(ConfirmInput, 7)
Hover(ConfirmInput, Colors.Accent, Colors.AccentDim)

-----/Functions/-----
local function UpdateCanvas()
	TrackList.CanvasSize = UDim2.fromOffset(0, TrackLayout.AbsoluteContentSize.Y + 16)
end

local function ClearTrackUI()
	for _, Object in ipairs(TrackList:GetChildren()) do
		if Object:IsA("Frame") then
			Object:Destroy()
		end
	end
end

local function ShowToast(Text)
	ToastLabel.Text = Text
	ToastLabel.Visible = true
	ToastLabel.TextTransparency = 0
	ToastLabel.BackgroundTransparency = 0.1

	local FadeTween = TweenService:Create(
		ToastLabel,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1.4),
		{TextTransparency = 1, BackgroundTransparency = 1}
	)

	FadeTween:Play()

	FadeTween.Completed:Connect(function()
		ToastLabel.Visible = false
	end)
end

local function UpdateVolumeVisual()
	local Percent = math.clamp(Sound.Volume / 2, 0, 1)
	VolumeFill.Size = UDim2.new(Percent, 0, 1, 0)
	VolumePercent.Text = string.format("%.1f", Sound.Volume)
end

local function PlayTrack(Index)
	if #Tracks == 0 then
		return
	end

	Index = math.clamp(Index, 1, #Tracks)

	CurrentIndex = Index

	local Track = Tracks[Index]

	if CurrentSound then
		CurrentSound:Stop()
	end

	CurrentSound = Sound
	CurrentSound.SoundId = GetSoundId(Track.Id)
	CurrentSound.Volume = Track.Volume
	CurrentSound.PlaybackSpeed = Track.Speed

	pcall(function()
		CurrentSound.Pitch = Track.Pitch
	end)

	CurrentLabel.Text = Track.Id
	PlayButton.Text = "⏸"

	CurrentSound:Play()

	UpdateVolumeVisual()
	RefreshTracks()
end

function RefreshTracks()
	ClearTrackUI()

	local Query = SearchBox.Text:lower()
	local Matches = 0

	for Index, Track in ipairs(Tracks) do
		local IdText = tostring(Track.Id):lower()

		if Query == "" or IdText:find(Query, 1, true) then
			Matches = Matches + 1

			local TrackFrame = Create("Frame", {
				Name = "Track_" .. Index,
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Colors.PanelAlt,
				BorderSizePixel = 0,
				Parent = TrackList
			})

			Corner(TrackFrame, 7)
			Stroke(TrackFrame, (Index == CurrentIndex) and 0.3 or 1, Colors.Accent)

			local Number = Create("TextLabel", {
				Size = UDim2.fromOffset(35, 52),
				BackgroundTransparency = 1,
				Text = tostring(Index),
				TextColor3 = Colors.GrayDark,
				TextSize = 12,
				Font = Enum.Font.Code,
				Parent = TrackFrame
			})

			local TrackName = Create("TextLabel", {
				Size = UDim2.new(1, -115, 0, 28),
				Position = UDim2.fromOffset(35, 4),
				BackgroundTransparency = 1,
				Text = Track.Id,
				TextColor3 = Colors.White,
				TextSize = 13,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = TrackFrame
			})

			local TrackSettings = Create("TextLabel", {
				Size = UDim2.new(1, -115, 0, 18),
				Position = UDim2.fromOffset(35, 28),
				BackgroundTransparency = 1,
				Text = "V:" .. Track.Volume .. "  S:" .. Track.Speed .. "  P:" .. Track.Pitch,
				TextColor3 = Colors.GrayDark,
				TextSize = 10,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = TrackFrame
			})

			local PlayTrackButton = Create("TextButton", {
				Size = UDim2.fromOffset(32, 32),
				Position = UDim2.new(1, -72, 0.5, -16),
				BackgroundColor3 = Colors.White,
				Text = "▶",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 11,
				Font = Enum.Font.Code,
				Parent = TrackFrame
			})

			Corner(PlayTrackButton, 6)
			Hover(PlayTrackButton, Colors.White, Colors.Accent)

			local DeleteButton = Create("TextButton", {
				Size = UDim2.fromOffset(32, 32),
				Position = UDim2.new(1, -36, 0.5, -16),
				BackgroundColor3 = Colors.PanelAlt,
				Text = "×",
				TextColor3 = Colors.White,
				TextSize = 16,
				Font = Enum.Font.Code,
				Parent = TrackFrame
			})

			Corner(DeleteButton, 6)
			Hover(DeleteButton, Colors.PanelAlt, Colors.Danger)

			PlayTrackButton.MouseButton1Click:Connect(function()
				PlayTrack(Index)
			end)

			DeleteButton.MouseButton1Click:Connect(function()
				if CurrentIndex == Index and CurrentSound then
					CurrentSound:Stop()
					CurrentIndex = 0
					CurrentLabel.Text = "Nothing playing"
					PlayButton.Text = "▶"
				elseif CurrentIndex > Index then
					CurrentIndex = CurrentIndex - 1
				end

				table.remove(Tracks, Index)
				RefreshTracks()
			end)
		end
	end

	EmptyLabel.Visible = (Matches == 0)
	EmptyLabel.Text = (#Tracks == 0) and "No tracks yet — add one on the right" or "No matches found"

	UpdateCanvas()
end

-----/Main/-----
local function AddTrackFromInput()
	local Id = IdBox.Text:gsub("%s+", "")

	if Id == "" then
		return
	end

	Id = Id:gsub("rbxassetid://", "")
	Id = Id:gsub("https://www.roblox.com/library/", "")
	Id = Id:gsub("https://create.roblox.com/store/asset/", "")

	table.insert(Tracks, {
		Id = Id,
		Volume = PendingVolume,
		Speed = PendingSpeed,
		Pitch = PendingPitch
	})

	IdBox.Text = ""

	RefreshTracks()
end

AddTrackButton.MouseButton1Click:Connect(AddTrackFromInput)

IdBox.FocusLost:Connect(function(EnterPressed)
	if EnterPressed then
		AddTrackFromInput()
	end
end)

PlayButton.MouseButton1Click:Connect(function()
	if not CurrentSound then
		if #Tracks > 0 then
			PlayTrack(1)
		end

		return
	end

	if CurrentSound.IsPlaying then
		CurrentSound:Pause()
		PlayButton.Text = "▶"
	else
		CurrentSound:Resume()
		PlayButton.Text = "⏸"
	end
end)

NextButton.MouseButton1Click:Connect(function()
	if #Tracks == 0 then
		return
	end

	local NextIndex = CurrentIndex + 1

	if NextIndex > #Tracks then
		NextIndex = 1
	end

	PlayTrack(NextIndex)
end)

PreviousButton.MouseButton1Click:Connect(function()
	if #Tracks == 0 then
		return
	end

	local PreviousIndex = CurrentIndex - 1

	if PreviousIndex < 1 then
		PreviousIndex = #Tracks
	end

	PlayTrack(PreviousIndex)
end)

LoopButton.MouseButton1Click:Connect(function()
	IsLooping = not IsLooping
	LoopButton.BackgroundColor3 = IsLooping and Colors.Accent or Colors.PanelAlt
end)

CloseButton.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = false
end)

ExportButton.MouseButton1Click:Connect(function()
	InputMode = "Export"
	DataBox.Text = ExportTracks()
	InputTitle.Text = "Export"
	ConfirmInput.Text = "Copy"
	InputFrame.Visible = true
end)

ImportButton.MouseButton1Click:Connect(function()
	InputMode = "Import"
	DataBox.Text = ""
	InputTitle.Text = "Import"
	ConfirmInput.Text = "Import"
	InputFrame.Visible = true
end)

CloseInput.MouseButton1Click:Connect(function()
	InputFrame.Visible = false
end)

ConfirmInput.MouseButton1Click:Connect(function()
	if InputMode == "Export" then
		local Success = pcall(setclipboard, DataBox.Text)
		ShowToast(Success and "Copied to clipboard" or "Copy not supported here")
	else
		local Data = DataBox.Text

		if Data ~= "" then
			ImportTracks(Data)
			RefreshTracks()
			ShowToast("Imported " .. #Tracks .. " track(s)")
		end
	end

	InputFrame.Visible = false
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshTracks)

BindSlider(Progress, function(Percent)
	if Sound.TimeLength > 0 then
		Sound.TimePosition = Percent * Sound.TimeLength
	end
end)

BindSlider(VolumeBar, function(Percent)
	Sound.Volume = Percent * 2
end)

Sound.Ended:Connect(function()
	if #Tracks == 0 then
		return
	end

	if IsLooping then
		PlayTrack(CurrentIndex)
		return
	end

	local NextIndex = CurrentIndex + 1

	if NextIndex > #Tracks then
		NextIndex = 1
	end

	PlayTrack(NextIndex)
end)

Sound:GetPropertyChangedSignal("TimePosition"):Connect(function()
	if Sound.TimeLength > 0 then
		local Percent = math.clamp(Sound.TimePosition / Sound.TimeLength, 0, 1)

		ProgressFill.Size = UDim2.new(Percent, 0, 1, 0)
		TimeLabel.Text = FormatTime(Sound.TimePosition) .. " / " .. FormatTime(Sound.TimeLength)
	end
end)

Sound:GetPropertyChangedSignal("Volume"):Connect(UpdateVolumeVisual)

-----/Keybinds/-----
UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	if GameProcessed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.RightControl then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end)

-----/Drag/-----
local Dragging = false
local DragStart
local StartPosition

TopBar.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = true
		DragStart = Input.Position
		StartPosition = MainFrame.Position
	end
end)

TopBar.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local Delta = Input.Position - DragStart

		MainFrame.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end
end)

-----/Init/-----
UpdateVolumeVisual()
RefreshTracks()
