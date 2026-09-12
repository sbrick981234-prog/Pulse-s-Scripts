-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Tracks = {}
local CurrentIndex = 0
local CurrentSound = nil

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

local function Stroke(Parent, Transparency)
	local Object = Instance.new("UIStroke")
	Object.Color = Color3.fromRGB(255, 255, 255)
	Object.Transparency = Transparency
	Object.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Object.Parent = Parent
	return Object
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
	Size = UDim2.fromOffset(720, 460),
	Position = UDim2.new(0.5, -360, 0.5, -230),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
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
	Size = UDim2.fromOffset(200, 55),
	Position = UDim2.fromOffset(18, 0),
	BackgroundTransparency = 1,
	Text = "Skiddify",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 20,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TopBar
})

local ExportButton = Create("TextButton", {
	Name = "ExportButton",
	Size = UDim2.fromOffset(90, 34),
	Position = UDim2.new(1, -200, 0, 10),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Text = "Export",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(ExportButton, 7)
Stroke(ExportButton, 0.8)

local ImportButton = Create("TextButton", {
	Name = "ImportButton",
	Size = UDim2.fromOffset(90, 34),
	Position = UDim2.new(1, -102, 0, 10),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Text = "Import",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = TopBar
})

Corner(ImportButton, 7)
Stroke(ImportButton, 0.8)

-----/TrackList/-----
local TrackList = Create("ScrollingFrame", {
	Name = "TrackList",
	Size = UDim2.fromOffset(335, 335),
	Position = UDim2.fromOffset(18, 70),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
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

-----/Player/-----
local PlayerFrame = Create("Frame", {
	Name = "PlayerFrame",
	Size = UDim2.fromOffset(335, 150),
	Position = UDim2.fromOffset(365, 70),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BorderSizePixel = 0,
	Parent = MainFrame
})

Corner(PlayerFrame, 8)
Stroke(PlayerFrame, 0.9)

local CurrentLabel = Create("TextLabel", {
	Name = "CurrentLabel",
	Size = UDim2.new(1, -20, 0, 35),
	Position = UDim2.fromOffset(10, 10),
	BackgroundTransparency = 1,
	Text = "Nothing playing",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = PlayerFrame
})

local TimeLabel = Create("TextLabel", {
	Name = "TimeLabel",
	Size = UDim2.fromOffset(60, 25),
	Position = UDim2.fromOffset(10, 55),
	BackgroundTransparency = 1,
	Text = "0:00",
	TextColor3 = Color3.fromRGB(150, 150, 150),
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = PlayerFrame
})

local Progress = Create("Frame", {
	Name = "Progress",
	Size = UDim2.new(1, -90, 4, 0),
	Position = UDim2.fromOffset(60, 65),
	BackgroundColor3 = Color3.fromRGB(35, 35, 35),
	BorderSizePixel = 0,
	Parent = PlayerFrame
})

Corner(Progress, 4)

local ProgressFill = Create("Frame", {
	Name = "ProgressFill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Parent = Progress
})

Corner(ProgressFill, 4)

local PlayButton = Create("TextButton", {
	Name = "PlayButton",
	Size = UDim2.fromOffset(42, 32),
	Position = UDim2.fromOffset(146, 85),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "▶",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(PlayButton, 7)

local PreviousButton = Create("TextButton", {
	Name = "PreviousButton",
	Size = UDim2.fromOffset(38, 32),
	Position = UDim2.fromOffset(100, 85),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Text = "◀",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(PreviousButton, 7)
Stroke(PreviousButton, 0.8)

local NextButton = Create("TextButton", {
	Name = "NextButton",
	Size = UDim2.fromOffset(38, 32),
	Position = UDim2.fromOffset(196, 85),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Text = "▶",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.Code,
	Parent = PlayerFrame
})

Corner(NextButton, 7)
Stroke(NextButton, 0.8)

-----/Add/-----
local AddFrame = Create("Frame", {
	Name = "AddFrame",
	Size = UDim2.fromOffset(335, 165),
	Position = UDim2.fromOffset(365, 235),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BorderSizePixel = 0,
	Parent = MainFrame
})

Corner(AddFrame, 8)
Stroke(AddFrame, 0.9)

local IdBox = Create("TextBox", {
	Name = "IdBox",
	Size = UDim2.new(1, -20, 0, 38),
	Position = UDim2.fromOffset(10, 10),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	PlaceholderText = "Sound ID",
	PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.Code,
	ClearTextOnFocus = false,
	Parent = AddFrame
})

Corner(IdBox, 7)
Stroke(IdBox, 0.8)

local AddTrackButton = Create("TextButton", {
	Name = "AddTrackButton",
	Size = UDim2.new(1, -20, 0, 38),
	Position = UDim2.fromOffset(10, 57),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Add Track",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextSize = 14,
	Font = Enum.Font.Code,
	Parent = AddFrame
})

Corner(AddTrackButton, 7)

local SettingsLabel = Create("TextLabel", {
	Name = "SettingsLabel",
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.fromOffset(10, 105),
	BackgroundTransparency = 1,
	Text = "Volume: 1    Speed: 1    Pitch: 1",
	TextColor3 = Color3.fromRGB(130, 130, 130),
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = AddFrame
})

-----/ImportExport/-----
local InputFrame = Create("Frame", {
	Name = "InputFrame",
	Size = UDim2.fromOffset(600, 300),
	Position = UDim2.new(0.5, -300, 0.5, -150),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
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
	TextColor3 = Color3.fromRGB(255, 255, 255),
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
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	Text = "×",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 20,
	Font = Enum.Font.Code,
	ZIndex = 21,
	Parent = InputFrame
})

Corner(CloseInput, 7)

local DataBox = Create("TextBox", {
	Name = "DataBox",
	Size = UDim2.new(1, -30, 0, 180),
	Position = UDim2.fromOffset(15, 50),
	BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	Text = "",
	PlaceholderText = "43294322432:Volume-1:Speed-1:Pitch-1, 48548352371:Volume-1:Speed-1:Pitch-1",
	PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
	TextColor3 = Color3.fromRGB(255, 255, 255),
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
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Import",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextSize = 13,
	Font = Enum.Font.Code,
	ZIndex = 21,
	Parent = InputFrame
})

Corner(ConfirmInput, 7)

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
end

local function RefreshTracks()
	ClearTrackUI()

	for Index, Track in ipairs(Tracks) do
		local TrackFrame = Create("Frame", {
			Name = "Track_" .. Index,
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			BorderSizePixel = 0,
			Parent = TrackList
		})

		Corner(TrackFrame, 7)

		local Number = Create("TextLabel", {
			Size = UDim2.fromOffset(35, 52),
			BackgroundTransparency = 1,
			Text = tostring(Index),
			TextColor3 = Color3.fromRGB(100, 100, 100),
			TextSize = 12,
			Font = Enum.Font.Code,
			Parent = TrackFrame
		})

		local TrackName = Create("TextLabel", {
			Size = UDim2.new(1, -115, 0, 28),
			Position = UDim2.fromOffset(35, 4),
			BackgroundTransparency = 1,
			Text = Track.Id,
			TextColor3 = Color3.fromRGB(255, 255, 255),
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
			TextColor3 = Color3.fromRGB(100, 100, 100),
			TextSize = 10,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TrackFrame
		})

		local PlayTrackButton = Create("TextButton", {
			Size = UDim2.fromOffset(32, 32),
			Position = UDim2.new(1, -72, 0.5, -16),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Text = "▶",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 11,
			Font = Enum.Font.Code,
			Parent = TrackFrame
		})

		Corner(PlayTrackButton, 6)

		local DeleteButton = Create("TextButton", {
			Size = UDim2.fromOffset(32, 32),
			Position = UDim2.new(1, -36, 0.5, -16),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			Text = "×",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			Font = Enum.Font.Code,
			Parent = TrackFrame
		})

		Corner(DeleteButton, 6)

		PlayTrackButton.MouseButton1Click:Connect(function()
			PlayTrack(Index)
		end)

		DeleteButton.MouseButton1Click:Connect(function()
			if CurrentIndex == Index and CurrentSound then
				CurrentSound:Stop()
				CurrentIndex = 0
				CurrentLabel.Text = "Nothing playing"
				PlayButton.Text = "▶"
			end

			table.remove(Tracks, Index)
			RefreshTracks()
		end)
	end

	UpdateCanvas()
end

-----/Main/-----
AddTrackButton.MouseButton1Click:Connect(function()
	local Id = IdBox.Text:gsub("%s+", "")

	if Id == "" then
		return
	end

	Id = Id:gsub("rbxassetid://", "")
	Id = Id:gsub("https://www.roblox.com/library/", "")
	Id = Id:gsub("https://create.roblox.com/store/asset/", "")

	table.insert(Tracks, {
		Id = Id,
		Volume = 1,
		Speed = 1,
		Pitch = 1
	})

	IdBox.Text = ""

	RefreshTracks()
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

ExportButton.MouseButton1Click:Connect(function()
	DataBox.Text = ExportTracks()
	InputTitle.Text = "Export"
	InputFrame.Visible = true
end)

ImportButton.MouseButton1Click:Connect(function()
	DataBox.Text = ""
	InputTitle.Text = "Import"
	InputFrame.Visible = true
end)

CloseInput.MouseButton1Click:Connect(function()
	InputFrame.Visible = false
end)

ConfirmInput.MouseButton1Click:Connect(function()
	local Data = DataBox.Text

	if Data ~= "" then
		ImportTracks(Data)
		RefreshTracks()
	end

	InputFrame.Visible = false
end)

Sound.Ended:Connect(function()
	if #Tracks == 0 then
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
		TimeLabel.Text = FormatTime(Sound.TimePosition)
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

game:GetService("UserInputService").InputChanged:Connect(function(Input)
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
RefreshTracks()
